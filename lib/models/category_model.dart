class CategoryModel {
  final String name;
  final String icon;
  final String type; // 'expense' or 'income'
  final String? description;

  CategoryModel({
    required this.name,
    required this.icon,
    required this.type,
    this.description,
  });

  static List<CategoryModel> getExpenseCategories() {
    // Fixed frontend categories for non-pro users
    return [
      CategoryModel(
        name: 'Food',
        icon: 'assets/icons/foodoc.png',
        type: 'expense',
        description: 'Restaurant meals, takeout, food delivery',
      ),
      CategoryModel(
        name: 'Transport',
        icon: 'assets/icons/car.png',
        type: 'expense',
        description: 'Car, bus, train, taxi, fuel',
      ),
      CategoryModel(
        name: 'Eating Out',
        icon: 'assets/icons/eating_out.png',
        type: 'expense',
        description: 'Restaurants, cafes, bars',
      ),
      CategoryModel(
        name: 'Home',
        icon: 'assets/icons/home.png',
        type: 'expense',
        description: 'Rent, utilities, maintenance',
      ),
      CategoryModel(
        name: 'Groceries',
        icon: 'assets/icons/Groceries.png',
        type: 'expense',
        description: 'Supermarket, food shopping',
      ),
      CategoryModel(
        name: 'Other',
        icon: 'assets/icons/money.png',
        type: 'expense',
        description: 'Miscellaneous expenses',
      ),
    ];
  }

  static List<CategoryModel> getIncomeCategories() {
    // Fixed frontend categories for non-pro users
    return [
      CategoryModel(
        name: 'Salary',
        icon: 'assets/icons/money.png',
        type: 'income',
        description: 'Monthly salary, wages',
      ),
      CategoryModel(
        name: 'Freelancing',
        icon: 'assets/icons/rocket.png',
        type: 'income',
        description: 'Freelance work, consulting',
      ),
      CategoryModel(
        name: 'Donation',
        icon: 'assets/icons/gift.png',
        type: 'income',
        description: 'Donations received',
      ),
      CategoryModel(
        name: 'Gift',
        icon: 'assets/icons/gift.png',
        type: 'income',
        description: 'Gifts received',
      ),
      CategoryModel(
        name: 'Other Income',
        icon: 'assets/icons/money.png',
        type: 'income',
        description: 'Other sources of income',
      ),
    ];
  }

  static List<CategoryModel> getAllCategories() {
    return [...getExpenseCategories(), ...getIncomeCategories()];
  }

  static CategoryModel? getCategoryByName(String name, String type) {
    final categories = type == 'expense' ? getExpenseCategories() : getIncomeCategories();
    try {
      return categories.firstWhere((category) => category.name == name);
    } catch (e) {
      return null;
    }
  }
}