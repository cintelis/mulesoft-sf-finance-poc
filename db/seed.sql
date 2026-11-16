-- Seed data for the legacy finance system. All names, ABNs and contacts are made up.
-- Customers have no sf_account_id yet: they are the "historical" records the
-- migration flow will load into Salesforce and link back.
SET DEFINE OFF

INSERT INTO customers (customer_code, customer_name, abn, email, phone, address_line, suburb, state_code, postcode, status, credit_limit)
VALUES ('C001001', 'Harbour City Plumbing Pty Ltd', '51824753556', 'accounts@harbourcityplumbing.example', '02 5550 1001', '12 Wharf Rd', 'Balmain', 'NSW', '2041', 'ACTIVE', 25000);
INSERT INTO customers (customer_code, customer_name, abn, email, phone, address_line, suburb, state_code, postcode, status, credit_limit)
VALUES ('C001002', 'Yarra Valley Catering', '33102417032', 'finance@yarravalleycatering.example', '03 5550 1002', '88 Maroondah Hwy', 'Healesville', 'VIC', '3777', 'ACTIVE', 10000);
INSERT INTO customers (customer_code, customer_name, abn, email, phone, address_line, suburb, state_code, postcode, status, credit_limit)
VALUES ('C001003', 'Smith & Sons Electrical', '80004552110', 'office@smithsons.example', '07 5550 1003', '4/19 Kingsford Smith Dr', 'Hamilton', 'QLD', '4007', 'ACTIVE', 15000);
INSERT INTO customers (customer_code, customer_name, abn, email, phone, address_line, suburb, state_code, postcode, status, credit_limit)
VALUES ('C001004', 'Swan River Logistics', '67119230804', 'ap@swanriverlogistics.example', '08 5550 1004', '201 Great Eastern Hwy', 'Belmont', 'WA', '6104', 'ON_HOLD', 50000);
INSERT INTO customers (customer_code, customer_name, abn, email, phone, address_line, suburb, state_code, postcode, status, credit_limit)
VALUES ('C001005', 'Adelaide Hills Vineyards', '45008714903', 'accounts@adelaidehillsvineyards.example', '08 5550 1005', '7 Onkaparinga Valley Rd', 'Hahndorf', 'SA', '5245', 'ACTIVE', 30000);
INSERT INTO customers (customer_code, customer_name, abn, email, phone, address_line, suburb, state_code, postcode, status, credit_limit)
VALUES ('C001006', 'Derwent Office Supplies', '29615008477', 'orders@derwentoffice.example', '03 5550 1006', '55 Elizabeth St', 'Hobart', 'TAS', '7000', 'ACTIVE', 5000);
INSERT INTO customers (customer_code, customer_name, abn, email, phone, address_line, suburb, state_code, postcode, status, credit_limit)
VALUES ('C001007', 'Top End Air Conditioning', '12730946115', 'admin@topendair.example', '08 5550 1007', '3 Stuart Hwy', 'Winnellie', 'NT', '0820', 'ACTIVE', 12000);
INSERT INTO customers (customer_code, customer_name, abn, email, phone, address_line, suburb, state_code, postcode, status, credit_limit)
VALUES ('C001008', 'Capital Print & Design', '74301862209', 'hello@capitalprint.example', '02 5550 1008', '14 Lonsdale St', 'Braddon', 'ACT', '2612', 'CLOSED', 0);

-- Invoices: a mix of statuses and ages so the sync and the payments file have something to chew on.
INSERT INTO invoices (invoice_number, customer_id, invoice_date, due_date, amount_ex_gst, gst_amount, amount_paid, status, description)
SELECT 'INV-100001', customer_id, DATE '2026-09-01', DATE '2026-10-01', 4200.00, 420.00, 4620.00, 'PAID', 'Quarterly maintenance contract' FROM customers WHERE customer_code = 'C001001';
INSERT INTO invoices (invoice_number, customer_id, invoice_date, due_date, amount_ex_gst, gst_amount, amount_paid, status, description)
SELECT 'INV-100002', customer_id, DATE '2026-10-15', DATE '2026-11-14', 1250.00, 125.00, 0, 'OPEN', 'Emergency call-out' FROM customers WHERE customer_code = 'C001001';
INSERT INTO invoices (invoice_number, customer_id, invoice_date, due_date, amount_ex_gst, gst_amount, amount_paid, status, description)
SELECT 'INV-100003', customer_id, DATE '2026-10-03', DATE '2026-11-02', 860.00, 86.00, 0, 'OPEN', 'Event catering - 40 guests' FROM customers WHERE customer_code = 'C001002';
INSERT INTO invoices (invoice_number, customer_id, invoice_date, due_date, amount_ex_gst, gst_amount, amount_paid, status, description)
SELECT 'INV-100004', customer_id, DATE '2026-10-20', DATE '2026-11-19', 2300.00, 230.00, 1000.00, 'PART_PAID', 'Corporate lunch series' FROM customers WHERE customer_code = 'C001002';
INSERT INTO invoices (invoice_number, customer_id, invoice_date, due_date, amount_ex_gst, gst_amount, amount_paid, status, description)
SELECT 'INV-100005', customer_id, DATE '2026-09-22', DATE '2026-10-22', 5400.00, 540.00, 0, 'OPEN', 'Switchboard upgrade' FROM customers WHERE customer_code = 'C001003';
INSERT INTO invoices (invoice_number, customer_id, invoice_date, due_date, amount_ex_gst, gst_amount, amount_paid, status, description)
SELECT 'INV-100006', customer_id, DATE '2026-11-02', DATE '2026-12-02', 318.18, 31.82, 0, 'OPEN', 'Safety inspection' FROM customers WHERE customer_code = 'C001003';
INSERT INTO invoices (invoice_number, customer_id, invoice_date, due_date, amount_ex_gst, gst_amount, amount_paid, status, description)
SELECT 'INV-100007', customer_id, DATE '2026-08-11', DATE '2026-09-10', 18750.00, 1875.00, 0, 'OPEN', 'Interstate freight - August' FROM customers WHERE customer_code = 'C001004';
INSERT INTO invoices (invoice_number, customer_id, invoice_date, due_date, amount_ex_gst, gst_amount, amount_paid, status, description)
SELECT 'INV-100008', customer_id, DATE '2026-09-11', DATE '2026-10-11', 16400.00, 1640.00, 0, 'OPEN', 'Interstate freight - September' FROM customers WHERE customer_code = 'C001004';
INSERT INTO invoices (invoice_number, customer_id, invoice_date, due_date, amount_ex_gst, gst_amount, amount_paid, status, description)
SELECT 'INV-100009', customer_id, DATE '2026-10-28', DATE '2026-11-27', 7200.00, 720.00, 0, 'OPEN', 'Bottling line service' FROM customers WHERE customer_code = 'C001005';
INSERT INTO invoices (invoice_number, customer_id, invoice_date, due_date, amount_ex_gst, gst_amount, amount_paid, status, description)
SELECT 'INV-100010', customer_id, DATE '2026-11-05', DATE '2026-12-05', 950.00, 95.00, 0, 'OPEN', 'Label printing' FROM customers WHERE customer_code = 'C001005';
INSERT INTO invoices (invoice_number, customer_id, invoice_date, due_date, amount_ex_gst, gst_amount, amount_paid, status, description)
SELECT 'INV-100011', customer_id, DATE '2026-10-09', DATE '2026-11-08', 412.50, 41.25, 453.75, 'PAID', 'Stationery order' FROM customers WHERE customer_code = 'C001006';
INSERT INTO invoices (invoice_number, customer_id, invoice_date, due_date, amount_ex_gst, gst_amount, amount_paid, status, description)
SELECT 'INV-100012', customer_id, DATE '2026-11-10', DATE '2026-12-10', 1180.00, 118.00, 0, 'OPEN', 'Office chairs x 6' FROM customers WHERE customer_code = 'C001006';
INSERT INTO invoices (invoice_number, customer_id, invoice_date, due_date, amount_ex_gst, gst_amount, amount_paid, status, description)
SELECT 'INV-100013', customer_id, DATE '2026-10-30', DATE '2026-11-29', 3650.00, 365.00, 0, 'OPEN', 'Split system install x 2' FROM customers WHERE customer_code = 'C001007';
INSERT INTO invoices (invoice_number, customer_id, invoice_date, due_date, amount_ex_gst, gst_amount, amount_paid, status, description)
SELECT 'INV-100014', customer_id, DATE '2026-07-18', DATE '2026-08-17', 640.00, 64.00, 0, 'VOID', 'Brochure run - cancelled' FROM customers WHERE customer_code = 'C001008';
INSERT INTO invoices (invoice_number, customer_id, invoice_date, due_date, amount_ex_gst, gst_amount, amount_paid, status, description)
SELECT 'INV-100015', customer_id, DATE '2026-11-12', DATE '2026-12-12', 2890.00, 289.00, 0, 'OPEN', 'Ducted system service' FROM customers WHERE customer_code = 'C001007';

-- Payments already on file for the invoices seeded as paid or part-paid.
INSERT INTO payments (payment_ref, invoice_id, amount, payment_date, payment_method, payer_name, source_file)
SELECT 'PAY-20260928-0001', invoice_id, 4620.00, DATE '2026-09-28', 'EFT', 'Harbour City Plumbing', 'seed' FROM invoices WHERE invoice_number = 'INV-100001';
INSERT INTO payments (payment_ref, invoice_id, amount, payment_date, payment_method, payer_name, source_file)
SELECT 'PAY-20261030-0001', invoice_id, 1000.00, DATE '2026-10-30', 'BPAY', 'Yarra Valley Catering', 'seed' FROM invoices WHERE invoice_number = 'INV-100004';
INSERT INTO payments (payment_ref, invoice_id, amount, payment_date, payment_method, payer_name, source_file)
SELECT 'PAY-20261102-0001', invoice_id, 453.75, DATE '2026-11-02', 'CARD', 'Derwent Office Supplies', 'seed' FROM invoices WHERE invoice_number = 'INV-100011';

-- Start the invoice sync from the beginning of time.
INSERT INTO sync_watermark (sync_name, last_value)
VALUES ('invoice-sync', TIMESTAMP '2000-01-01 00:00:00');

COMMIT;
