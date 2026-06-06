/// Country presets for the tax calculator and a default currency for the
/// converter. Tax rates are each country's *standard* national VAT / GST /
/// consumption / sales rate (approximate — the tax screen lets the user edit
/// the rate, since rates change and some countries vary by region/state).
class Country {
  final String code; // ISO 3166-1 alpha-2
  final String name;
  final double taxRate; // standard rate, percent
  final String taxName; // e.g. "Consumption tax", "VAT", "GST"
  final String currency; // ISO 4217
  const Country(this.code, this.name, this.taxRate, this.taxName, this.currency);
}

const kCountries = <Country>[
  Country('JP', 'Japan', 10, 'Consumption tax', 'JPY'),
  Country('US', 'United States', 0, 'Sales tax', 'USD'),
  Country('GB', 'United Kingdom', 20, 'VAT', 'GBP'),
  Country('DE', 'Germany', 19, 'VAT', 'EUR'),
  Country('FR', 'France', 20, 'VAT', 'EUR'),
  Country('IT', 'Italy', 22, 'VAT', 'EUR'),
  Country('ES', 'Spain', 21, 'VAT', 'EUR'),
  Country('CA', 'Canada', 5, 'GST', 'CAD'),
  Country('AU', 'Australia', 10, 'GST', 'AUD'),
  Country('NZ', 'New Zealand', 15, 'GST', 'NZD'),
  Country('CN', 'China', 13, 'VAT', 'CNY'),
  Country('KR', 'South Korea', 10, 'VAT', 'KRW'),
  Country('IN', 'India', 18, 'GST', 'INR'),
  Country('SG', 'Singapore', 9, 'GST', 'SGD'),
  Country('CH', 'Switzerland', 8.1, 'VAT', 'CHF'),
  Country('SE', 'Sweden', 25, 'VAT', 'SEK'),
  Country('NO', 'Norway', 25, 'VAT', 'NOK'),
  Country('MX', 'Mexico', 16, 'VAT', 'MXN'),
  Country('TH', 'Thailand', 7, 'VAT', 'THB'),
  Country('HK', 'Hong Kong', 0, 'No sales tax', 'HKD'),
];

const Country kDefaultCountry = Country('JP', 'Japan', 10, 'Consumption tax', 'JPY');

Country countryByCode(String? code) {
  for (final c in kCountries) {
    if (c.code == code) return c;
  }
  return kDefaultCountry;
}
