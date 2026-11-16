// Local dashboard for the Salesforce-to-finance integration POC.
//
// One page that shows every component, whether it is up, how many records sit
// on each side, and lets you run each flow. No dependencies: Node 18 or later.
//
//   node dashboard/server.js      then open http://localhost:8090
//
// The browser cannot call the Mule APIs directly (different ports, no CORS),
// so this server reads their state and forwards the actions.
const http = require('http');
const fs = require('fs');
const path = require('path');
const { execFile } = require('child_process');

const PORT = Number(process.env.DASHBOARD_PORT || 8090);
const SF_ORG = process.env.SF_ORG_ALIAS || 'poc';
const REPO = path.resolve(__dirname, '..');
const APIS = {
  finance: process.env.FINANCE_API_URL || 'http://localhost:8081/api',
  sfdc: process.env.SFDC_API_URL || 'http://localhost:8082/api',
  prc: process.env.PROCESS_API_URL || 'http://localhost:8083/api',
};

async function call(url, options = {}) {
  const { timeout = 8000, ...rest } = options;
  try {
    const response = await fetch(url, { ...rest, signal: AbortSignal.timeout(timeout) });
    const text = await response.text();
    let body = text;
    try { body = JSON.parse(text); } catch { /* not JSON */ }
    return { ok: response.ok, status: response.status, body };
  } catch (error) {
    return { ok: false, status: 0, error: (error.cause && error.cause.code) || error.name };
  }
}

function run(command, args, timeout = 30000) {
  return new Promise((resolve) => {
    execFile(command, args, { timeout, windowsHide: true, shell: process.platform === 'win32' },
      (error, stdout) => resolve(error ? null : stdout));
  });
}

// Slow lookups (Salesforce CLI, Docker) are cached and refreshed in the
// background, so the page never waits on them.
const cache = {};
function cached(key, maxAgeMs, loader) {
  const entry = cache[key] || (cache[key] = { value: null, at: 0, loading: false });
  if (!entry.loading && Date.now() - entry.at > maxAgeMs) {
    entry.loading = true;
    loader().then((value) => { entry.value = value; entry.at = Date.now(); })
      .catch(() => {}).finally(() => { entry.loading = false; });
  }
  return entry.value;
}

async function loadContainers() {
  // "=" as the separator: the command runs through a shell on Windows, where "|" is a pipe.
  const out = await run('docker', ['ps', '-a', '--format', '{{.Names}}={{.Status}}']);
  if (out === null) return null;
  const containers = {};
  for (const line of out.split(/\r?\n/)) {
    const [name, status] = line.split('=');
    if (name === 'finance-db' || name === 'legacy-sftp') {
      containers[name] = { status, up: /^Up/.test(status || '') };
    }
  }
  return containers;
}

async function sfCount(soql) {
  const out = await run('sf', ['data', 'query', '--target-org', SF_ORG, '--json', '-q', `"${soql}"`]);
  if (out === null) return null;
  try { return JSON.parse(out).result.totalSize; } catch { return null; }
}

async function loadSalesforce() {
  const [accounts, invoices, orgOut] = await Promise.all([
    sfCount('SELECT COUNT() FROM Account'),
    sfCount('SELECT COUNT() FROM Invoice__c'),
    run('sf', ['org', 'display', '--target-org', SF_ORG, '--json']),
  ]);
  let links = null;
  try {
    // Only the instance URL is used. The access token in this output is never kept.
    const instanceUrl = JSON.parse(orgOut).result.instanceUrl;
    const lightning = instanceUrl.replace('.my.salesforce.com', '.lightning.force.com');
    const setup = instanceUrl.replace('.my.salesforce.com', '.my.salesforce-setup.com');
    links = {
      invoices: `${lightning}/lightning/o/Invoice__c/list?filterName=All_Invoices`,
      accounts: `${lightning}/lightning/o/Account/list?filterName=AllAccounts`,
      externalClientApp: `${setup}/lightning/setup/ManageExternalClientApplication/home`,
      changeDataCapture: `${setup}/lightning/setup/CdcObjectEnablement/home`,
    };
  } catch { /* CLI not available or not logged in */ }
  return { accounts, invoices, links };
}

// ---------------------------------------------------------------------------
// Issues: recent errors and rejected requests, read from each app's log file.
// The apps log one JSON object per line, so this is a plain tail and filter.
// ---------------------------------------------------------------------------
const os = require('os');
const LOG_APPS = { finance: 'finance-sys-api', sfdc: 'sfdc-sys-api', prc: 'customer-sync-prc-api' };

function findLogDir() {
  if (process.env.MULE_LOG_DIR) return process.env.MULE_LOG_DIR;
  try {
    const base = path.join(os.homedir(), 'AnypointCodeBuilder', 'runtime');
    const runtime = fs.readdirSync(base).filter((d) => d.startsWith('mule-enterprise-standalone-')).sort().pop();
    return runtime ? path.join(base, runtime, 'logs') : null;
  } catch { return null; }
}

function tail(file, bytes = 700000) {
  try {
    const size = fs.statSync(file).size;
    const fd = fs.openSync(file, 'r');
    const length = Math.min(size, bytes);
    const buffer = Buffer.alloc(length);
    fs.readSync(fd, buffer, 0, length, size - length);
    fs.closeSync(fd);
    return buffer.toString('utf8').split(/\r?\n/);
  } catch { return []; }
}

// Mule wraps flow errors in a block of asterisks. Keep the message and where it happened.
function tidy(message) {
  const text = String(message || '');
  const block = text.match(/Message\s*:\s*([\s\S]*?)\s*Element\s*:\s*([^\r\n]*)/);
  let out = block ? `${block[1].trim()} (at ${block[2].trim().replace(/ @ .*$/, '')})` : text;
  out = out.replace(/\\n|\r?\n/g, ' ').replace(/\s+/g, ' ').trim();
  return out.length > 600 ? `${out.slice(0, 600)}…` : out;
}

// Which connection an issue belongs to, judged from the app and the text.
function connectionFor(app, text) {
  if (app === 'finance') return /ORA-|DB:|database|FINANCE_DB/i.test(text) ? 'finance>oracle' : null;
  if (app === 'sfdc') {
    if (/account change event failed|process api|:8083/i.test(text)) return 'sfdc>prc';
    if (/replay|streaming|channel|subscri/i.test(text)) return 'cdc>sfdc';
    if (/invalid_client|invalid_grant|jwt|token|keystore|authenticat/i.test(text)) return 'eca>sfdc';
    if (/invoice/i.test(text)) return 'sfdc>sfInvoices';
    if (/SALESFORCE:|salesforce/i.test(text)) return 'sfdc>accounts';
    return null;
  }
  if (app === 'prc') {
    if (/:8081|finance/i.test(text)) return 'prc>finance';
    if (/:8082|salesforce|sfdc/i.test(text)) return 'sfdc>prc';
  }
  return null;
}

function loadIssues() {
  const dir = findLogDir();
  const result = { logDir: dir, components: {}, connections: {} };
  if (!dir) return Promise.resolve(result);
  for (const [id, app] of Object.entries(LOG_APPS)) {
    const issues = [];
    for (const line of tail(path.join(dir, `${app}.log`))) {
      if (!line.includes('"level":"ERROR"') && !line.includes('"level":"WARN"')) continue;
      let entry;
      try { entry = JSON.parse(line); } catch { continue; }
      // Warnings from the runtime itself are start-up noise; keep only the app's own.
      if (entry.level === 'WARN' && entry.logger !== app) continue;
      const message = tidy(entry.message);
      const handled = message.match(/^error status=(\d{3}) type=(\S+) description=(.*)$/);
      const status = handled ? Number(handled[1]) : null;
      const issue = {
        at: entry.timestamp,
        // A 4xx is the API doing its job: it rejected bad input. Anything else is a fault.
        kind: status && status < 500 ? 'rejected' : (entry.level === 'WARN' ? 'warning' : 'error'),
        status,
        type: handled ? handled[2] : null,
        message: handled ? handled[3] || handled[2] : message,
        correlationId: entry.correlationId || null,
        connection: connectionFor(id, message),
      };
      const last = issues[issues.length - 1];
      // The runtime logs a failure twice (its own block, then the app's line). Keep the app's.
      if (last && last.correlationId && last.correlationId === issue.correlationId && !handled) continue;
      if (last && last.correlationId && last.correlationId === issue.correlationId && handled && last.status === null) issues.pop();
      issues.push(issue);
    }
    // Fold a run of the same message into one entry with a count, newest time kept.
    // A component that is down produces the same line on every poll.
    const folded = [];
    for (const issue of issues) {
      const previous = folded[folded.length - 1];
      if (previous && previous.kind === issue.kind && previous.message === issue.message) {
        previous.count += 1; previous.at = issue.at; previous.correlationId = issue.correlationId;
      } else {
        folded.push({ ...issue, count: 1 });
      }
    }
    result.components[id] = folded.slice(-40).reverse();
    for (const issue of result.components[id]) {
      if (issue.connection) (result.connections[issue.connection] || (result.connections[issue.connection] = [])).push({ ...issue, app });
    }
  }
  return Promise.resolve(result);
}

function countFiles(folder) {
  try {
    return fs.readdirSync(path.join(REPO, 'infra', 'sftp-data', folder)).filter((f) => !f.startsWith('.')).length;
  } catch { return null; }
}

function listSamples() {
  try {
    return fs.readdirSync(path.join(REPO, 'samples', 'payments')).filter((f) => f.endsWith('.csv')).sort();
  } catch { return []; }
}

async function loadState() {
  const [financeHealth, sfdcHealth, prcHealth, customers, invoices, status] = await Promise.all([
    call(`${APIS.finance}/health`, { timeout: 5000 }),
    call(`${APIS.sfdc}/health`, { timeout: 12000 }),
    call(`${APIS.prc}/health`, { timeout: 12000 }),
    call(`${APIS.finance}/customers`),
    call(`${APIS.finance}/invoices?limit=1000`),
    call(`${APIS.prc}/status`, { timeout: 5000 }),
  ]);
  const customerItems = customers.ok ? customers.body.items : null;
  const invoiceItems = invoices.ok ? invoices.body.items : null;
  const byStatus = {};
  for (const invoice of invoiceItems || []) byStatus[invoice.status] = (byStatus[invoice.status] || 0) + 1;

  const health = (result, backend) => ({
    reachable: result.status !== 0,
    up: result.ok && result.body && result.body.status === 'UP',
    backendUp: result.body && backend ? result.body[backend] === 'UP' : null,
    detail: result.status === 0 ? 'Not running' : (result.body && result.body.status) || `HTTP ${result.status}`,
  });

  return {
    at: new Date().toISOString(),
    apis: {
      finance: { url: APIS.finance, ...health(financeHealth, 'database') },
      sfdc: { url: APIS.sfdc, ...health(sfdcHealth, 'salesforce') },
      prc: { url: APIS.prc, ...health(prcHealth, null), dependencies: prcHealth.body && prcHealth.body.dependencies },
      paymentsFile: { url: null, reachable: false, up: false, detail: 'Not built yet' },
    },
    containers: cached('containers', 5000, loadContainers),
    finance: {
      customers: customerItems ? customerItems.length : null,
      customersLinked: customerItems ? customerItems.filter((c) => c.sfAccountId).length : null,
      invoices: invoiceItems ? invoiceItems.length : null,
      invoicesByStatus: byStatus,
      invoicesLinked: invoiceItems ? invoiceItems.filter((i) => i.sfAccountId).length : null,
    },
    salesforce: cached('salesforce', 20000, loadSalesforce),
    sftp: { inbound: countFiles('inbound'), archive: countFiles('archive'), error: countFiles('error') },
    runs: status.ok ? status.body : null,
    issues: cached('issues', 3000, loadIssues),
    samples: listSamples(),
  };
}

const ACTIONS = {
  'migrate-customers': () => call(`${APIS.prc}/migrations/customers`, { method: 'POST', timeout: 120000 }),
  'sync-invoices': () => call(`${APIS.prc}/sync/invoices`, { method: 'POST', timeout: 120000 }),
  'sync-invoices-full': () => call(`${APIS.prc}/sync/invoices?full=true`, { method: 'POST', timeout: 120000 }),
  reconcile: () => call(`${APIS.prc}/reconciliation/customers`, { timeout: 120000 }),
  'process-payments': (input) => {
    const file = String((input && input.file) || '');
    if (!listSamples().includes(file)) return { ok: false, status: 400, body: { error: { message: `Unknown sample file ${file}` } } };
    const csv = fs.readFileSync(path.join(REPO, 'samples', 'payments', file));
    return call(`${APIS.prc}/payments/files?fileName=${encodeURIComponent(file)}`, {
      method: 'POST', headers: { 'Content-Type': 'text/csv' }, body: csv, timeout: 180000,
    });
  },
};

function send(res, status, body, type = 'application/json') {
  res.writeHead(status, { 'Content-Type': type, 'Cache-Control': 'no-store' });
  res.end(typeof body === 'string' || Buffer.isBuffer(body) ? body : JSON.stringify(body));
}

function readBody(req) {
  return new Promise((resolve) => {
    const chunks = [];
    req.on('data', (c) => chunks.push(c));
    req.on('end', () => {
      try { resolve(JSON.parse(Buffer.concat(chunks).toString() || '{}')); } catch { resolve({}); }
    });
  });
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://localhost:${PORT}`);
  try {
    if (req.method === 'GET' && url.pathname === '/') {
      return send(res, 200, fs.readFileSync(path.join(__dirname, 'index.html')), 'text/html; charset=utf-8');
    }
    if (req.method === 'GET' && url.pathname === '/api/state') {
      return send(res, 200, await loadState());
    }
    const action = url.pathname.match(/^\/api\/actions\/([a-z-]+)$/);
    if (req.method === 'POST' && action && ACTIONS[action[1]]) {
      const started = Date.now();
      const result = await ACTIONS[action[1]](await readBody(req));
      // Refresh the Salesforce counts straight after an action changes them.
      if (cache.salesforce) cache.salesforce.at = 0;
      return send(res, 200, { action: action[1], ms: Date.now() - started, ...result });
    }
    send(res, 404, { error: 'Not found' });
  } catch (error) {
    send(res, 500, { error: String(error && error.message) });
  }
});

// Local only: the page can trigger writes to the finance database and Salesforce.
server.listen(PORT, '127.0.0.1', () => {
  console.log(`Dashboard: http://localhost:${PORT}`);
});
