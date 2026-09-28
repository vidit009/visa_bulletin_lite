/// Supported Employment-based and Family-sponsored categories in the Visa Bulletin.
library;

class VisaCategories {
  static const List<String> employment = [
    'EB-1',
    'EB-2',
    'EB-3',
    'Other Workers',
    'EB-4',
    'Certain Religious Workers',
    'EB-5 Unreserved',
    'EB-5 Rural',
    'EB-5 High Unemployment',
    'EB-5 Infrastructure',
  ];

  static const List<String> family = [
    'F1',
    'F2A',
    'F2B',
    'F3',
    'F4',
  ];

  static String formatCategoryName(String cat) {
    switch (cat) {
      case 'EB-1':
        return 'EB-1 (Priority Workers)';
      case 'EB-2':
        return 'EB-2 (Advanced Degree / Exceptional Ability)';
      case 'EB-3':
        return 'EB-3 (Skilled Workers & Professionals)';
      case 'Other Workers':
        return 'Other Workers (Unskilled)';
      case 'EB-4':
        return 'EB-4 (Special Immigrants)';
      case 'Certain Religious Workers':
        return 'Certain Religious Workers';
      case 'EB-5 Unreserved':
        return 'EB-5 (Unreserved / Direct)';
      case 'EB-5 Rural':
        return 'EB-5 Set-Aside (Rural Area 20%)';
      case 'EB-5 High Unemployment':
        return 'EB-5 Set-Aside (High Unemployment 10%)';
      case 'EB-5 Infrastructure':
        return 'EB-5 Set-Aside (Infrastructure 2%)';
      case 'F1':
        return 'F1 (Unmarried Sons & Daughters of U.S. Citizens)';
      case 'F2A':
        return 'F2A (Spouses & Minor Children of Permanent Residents)';
      case 'F2B':
        return 'F2B (Unmarried Sons & Daughters of Permanent Residents)';
      case 'F3':
        return 'F3 (Married Sons & Daughters of U.S. Citizens)';
      case 'F4':
        return 'F4 (Brothers & Sisters of Adult U.S. Citizens)';
      default:
        return cat;
    }
  }
}
