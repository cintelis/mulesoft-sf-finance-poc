%dw 2.0
import dw::Crypto
import toHex from dw::core::Binaries
import * from modules::Lookups

// The same recipe as the finance view v_customer_recon:
//   SHA-256 of  UPPER(TRIM(name)) | abn | LOWER(email) | postcode | status
// with a missing value treated as an empty string. The Salesforce Account is
// first translated to finance vocabulary, so equal hashes mean the synced
// fields agree.
fun customerHash(account) = do {
  var parts = [
    upper(text(account.name)),
    digitsOnly(account.abn) default "",
    lower(text(account.email)),
    text(account.billingPostalCode),
    toFinanceStatus(account.status)
  ]
  ---
  lower(toHex(Crypto::hashWith((parts joinBy "|") as Binary {encoding: "UTF-8"}, "SHA-256")))
}
