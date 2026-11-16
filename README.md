# Salesforce to finance integration POC (MuleSoft)

A small API-led integration between Salesforce and a legacy finance system,
built with Mule 4. The finance system is an Oracle database and an SFTP file
feed, both running in Docker to stand in for on-premises systems.

## Flows

| Flow | Direction | Pattern |
|---|---|---|
| Customer sync | Salesforce Account to finance customer | Change Data Capture event, idempotent upsert |
| Invoice sync | Finance invoice to Salesforce `Invoice__c` | Scheduled poll with a watermark, bulk upsert on an external ID |
| Payments file | Nightly CSV over SFTP to finance and Salesforce | Batch job with per-record error handling |

## Repository layout

| Path | Contents | Status |
|---|---|---|
| `infra/` | Docker Compose for Oracle Database Free and SFTP | Working |
| `db/` | Finance schema, stored procedures and seed data | Working |
| `samples/payments/` | Clean and deliberately bad payment files | Ready |
| `finance-sys-api/` | System API over the finance database | Not started |
| `sfdc-sys-api/` | System API over Salesforce | Not started |
| `payments-file-sys-api/` | System API over the SFTP feed | Not started |
| `customer-sync-prc-api/` | Process API: orchestration, mappings, reconciliation | Not started |
| `docs/` | Architecture, mapping spec, runbook | Not started |

## Run the local systems

Needs Docker Desktop.

```powershell
cd infra
Copy-Item .env.example .env      # first time only; change the passwords if you like
docker compose up -d
docker compose ps                # wait for finance-db to show "healthy"
```

| System | Address | Login |
|---|---|---|
| Oracle | `localhost:1521`, service `FREEPDB1` | `FINANCE_DB_USER` / `FINANCE_DB_PASSWORD` from `.env` |
| SFTP | `localhost:2222`, folder `/payments` | `SFTP_USER` / `SFTP_PASSWORD` from `.env` |

The SFTP folders `inbound`, `archive` and `error` map to `infra/sftp-data/`.

The schema and seed data load once, when the database volume is first created.
To rebuild the database from scratch:

```powershell
docker compose down -v
docker compose up -d
```

Quick check:

```powershell
docker exec finance-db bash -c 'echo "select count(*) from invoices;" | sqlplus -s $APP_USER/$APP_USER_PASSWORD@//localhost/FREEPDB1'
```
