# Sample payment files

The legacy nightly feed. Format quirks are deliberate: `DD/MM/YYYY` dates and
amounts with thousands separators in quotes.

| File | Purpose |
|---|---|
| `payments_20261116.csv` | Clean file. All six rows should apply. |
| `payments_20261117_bad.csv` | Error-handling demo. Expected outcome per row below. |

## Expected results for the bad file

| Row | Payment ref | Expected |
|---|---|---|
| 1 | PAY-20261117-0001 | Applied; INV-100006 becomes PAID |
| 2 | PAY-20261117-0002 | Rejected: unknown invoice |
| 3 | PAY-20261117-0003 | Rejected: amount missing |
| 4 | PAY-20261117-0004 | Rejected: date not `DD/MM/YYYY` |
| 5 | PAY-20261117-0005 | Rejected: invoice is void |
| 6 | PAY-20261117-0006 | Rejected: negative amount |
| 7 | PAY-20261117-0007 | Rejected: unknown payment method |
| 8 | PAY-20261116-0002 | Skipped as a duplicate, if the clean file was loaded first |
| 9 | PAY-20261117-0008 | Applied; INV-100008 becomes PAID |

To drop a file into the SFTP inbound folder, copy it to `infra/sftp-data/inbound/`.
