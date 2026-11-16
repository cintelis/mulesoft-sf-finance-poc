%dw 2.0

// Translation tables between Salesforce's vocabulary and the finance system's.
// This is the one place that knows both.

var stateCodesByName = {
  "NEW SOUTH WALES": "NSW",
  "VICTORIA": "VIC",
  "QUEENSLAND": "QLD",
  "WESTERN AUSTRALIA": "WA",
  "SOUTH AUSTRALIA": "SA",
  "TASMANIA": "TAS",
  "NORTHERN TERRITORY": "NT",
  "AUSTRALIAN CAPITAL TERRITORY": "ACT"
}
var stateCodes = ["NSW", "VIC", "QLD", "WA", "SA", "TAS", "NT", "ACT"]

// Salesforce orgs with state and country picklists switched on accept the full
// state name, not the code.
var stateNamesByCode = {
  "NSW": "New South Wales",
  "VIC": "Victoria",
  "QLD": "Queensland",
  "WA": "Western Australia",
  "SA": "South Australia",
  "TAS": "Tasmania",
  "NT": "Northern Territory",
  "ACT": "Australian Capital Territory"
}

var accountStatusToFinance = { "Active": "ACTIVE", "On Hold": "ON_HOLD", "Closed": "CLOSED" }
var financeStatusToAccount = { "ACTIVE": "Active", "ON_HOLD": "On Hold", "CLOSED": "Closed" }
var invoiceStatusToSalesforce = { "OPEN": "Open", "PART_PAID": "Part Paid", "PAID": "Paid", "VOID": "Void" }

fun text(value) = trim((value default "") as String)

// "New South Wales", "nsw" and "NSW" all become "NSW". Unknown values become null.
fun toStateCode(value) = do {
  var name = upper(text(value))
  ---
  if (isEmpty(name)) null
  else if (stateCodes contains name) name
  else stateCodesByName[name]
}

// "NSW" -> "New South Wales". Anything unrecognised is passed through unchanged.
fun toStateName(value) = stateNamesByCode[upper(text(value))] default value

// A Salesforce Account with no status is treated as active, as finance does.
fun toFinanceStatus(value) = accountStatusToFinance[text(value)] default "ACTIVE"

// "51 824 753 556" -> "51824753556". Empty becomes null.
fun digitsOnly(value) = do {
  var digits = text(value) replace /[^0-9]/ with ""
  ---
  if (isEmpty(digits)) null else digits
}
