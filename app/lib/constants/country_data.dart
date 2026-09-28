/// Country definitions and chargeability mappings for the U.S. Visa Bulletin.
/// Maps countries to either dedicated bulletin cutoff columns or All Chargeability.
library;

bool isDedicatedCountry(String country) {
  final c = country.trim().toLowerCase();
  return c == 'india' || c == 'china' || c == 'mexico' || c == 'philippines';
}

String getChargeabilityKey(String country) {
  final c = country.trim().toLowerCase();
  if (c == 'india') return 'India';
  if (c == 'china' || c.contains('china')) return 'China';
  if (c == 'mexico') return 'Mexico';
  if (c == 'philippines') return 'Philippines';
  return 'All Chargeability';
}

String getCountryFlag(String country) {
  final c = country.trim().toLowerCase();
  if (c == 'india') return '🇮🇳';
  if (c == 'china') return '🇨🇳';
  if (c == 'mexico') return '🇲🇽';
  if (c == 'philippines') return '🇵🇭';
  if (c.contains('worldwide') || c.contains('chargeability')) return '🌐';
  if (c == 'canada') return '🇨🇦';
  if (c == 'united kingdom') return '🇬🇧';
  if (c == 'united states') return '🇺🇸';
  if (c == 'south korea') return '🇰🇷';
  if (c == 'brazil') return '🇧🇷';
  if (c == 'pakistan') return '🇵🇰';
  if (c == 'nigeria') return '🇳🇬';
  if (c == 'germany') return '🇩🇪';
  if (c == 'france') return '🇫🇷';
  if (c == 'japan') return '🇯🇵';
  if (c == 'australia') return '🇦🇺';
  if (c == 'vietnam') return '🇻🇳';
  if (c == 'taiwan') return '🇹🇼';
  return '🌐';
}

const List<String> priorityCountries = [
  'All Chargeability (Worldwide)',
  'India',
  'China',
  'Mexico',
  'Philippines',
];

const List<String> allWorldCountries = [
  'All Chargeability (Worldwide)',
  'India',
  'China',
  'Mexico',
  'Philippines',
  'Afghanistan',
  'Albania',
  'Algeria',
  'Andorra',
  'Angola',
  'Argentina',
  'Armenia',
  'Australia',
  'Austria',
  'Azerbaijan',
  'Bahamas',
  'Bahrain',
  'Bangladesh',
  'Barbados',
  'Belarus',
  'Belgium',
  'Belize',
  'Benin',
  'Bhutan',
  'Bolivia',
  'Bosnia and Herzegovina',
  'Botswana',
  'Brazil',
  'Brunei',
  'Bulgaria',
  'Burkina Faso',
  'Burundi',
  'Cambodia',
  'Cameroon',
  'Canada',
  'Cape Verde',
  'Central African Republic',
  'Chad',
  'Chile',
  'Colombia',
  'Comoros',
  'Congo',
  'Costa Rica',
  'Croatia',
  'Cuba',
  'Cyprus',
  'Czech Republic',
  'Denmark',
  'Djibouti',
  'Dominican Republic',
  'Ecuador',
  'Egypt',
  'El Salvador',
  'Equatorial Guinea',
  'Eritrea',
  'Estonia',
  'Eswatini',
  'Ethiopia',
  'Fiji',
  'Finland',
  'France',
  'Gabon',
  'Gambia',
  'Georgia',
  'Germany',
  'Ghana',
  'Greece',
  'Grenada',
  'Guatemala',
  'Guinea',
  'Guyana',
  'Haiti',
  'Honduras',
  'Hong Kong',
  'Hungary',
  'Iceland',
  'Indonesia',
  'Iran',
  'Iraq',
  'Ireland',
  'Israel',
  'Italy',
  'Jamaica',
  'Japan',
  'Jordan',
  'Kazakhstan',
  'Kenya',
  'Kuwait',
  'Kyrgyzstan',
  'Laos',
  'Latvia',
  'Lebanon',
  'Lesotho',
  'Liberia',
  'Libya',
  'Liechtenstein',
  'Lithuania',
  'Luxembourg',
  'Madagascar',
  'Malawi',
  'Malaysia',
  'Maldives',
  'Mali',
  'Malta',
  'Mauritania',
  'Mauritius',
  'Moldova',
  'Monaco',
  'Mongolia',
  'Montenegro',
  'Morocco',
  'Mozambique',
  'Myanmar',
  'Namibia',
  'Nepal',
  'Netherlands',
  'New Zealand',
  'Nicaragua',
  'Niger',
  'Nigeria',
  'North Macedonia',
  'Norway',
  'Oman',
  'Pakistan',
  'Panama',
  'Papua New Guinea',
  'Paraguay',
  'Peru',
  'Poland',
  'Portugal',
  'Qatar',
  'Romania',
  'Russia',
  'Rwanda',
  'Saudi Arabia',
  'Senegal',
  'Serbia',
  'Sierra Leone',
  'Singapore',
  'Slovakia',
  'Slovenia',
  'Somalia',
  'South Africa',
  'South Korea',
  'Spain',
  'Sri Lanka',
  'Sudan',
  'Sweden',
  'Switzerland',
  'Syria',
  'Taiwan',
  'Tajikistan',
  'Tanzania',
  'Thailand',
  'Togo',
  'Trinidad and Tobago',
  'Tunisia',
  'Turkey',
  'Turkmenistan',
  'Uganda',
  'Ukraine',
  'United Arab Emirates',
  'United Kingdom',
  'United States',
  'Uruguay',
  'Uzbekistan',
  'Venezuela',
  'Vietnam',
  'Yemen',
  'Zambia',
  'Zimbabwe',
];
