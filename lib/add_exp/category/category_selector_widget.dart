import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/category_service.dart';
import '../../models/category_model.dart';

class CategorySelectorWidget extends StatefulWidget {
  final Function(String categoryName, String categoryId) onCategorySelected;
  final String? selectedCategory;
  final bool isDarkMode;
  final String type; // 'expense' or 'income'

  const CategorySelectorWidget({
    super.key,
    required this.onCategorySelected,
    this.selectedCategory,
    this.isDarkMode = false,
    this.type = 'expense',
  });

  @override
  State<CategorySelectorWidget> createState() => _CategorySelectorWidgetState();
}

class _CategorySelectorWidgetState extends State<CategorySelectorWidget> {
  List<Map<String, dynamic>> categories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() async {
    setState(() {
      isLoading = true;
    });

    try {
      if (widget.type == 'expense') {
        // Load static categories first for immediate display
        categories = CategoryService.getStaticCategoriesWithIcons();
        setState(() {
          isLoading = false;
        });

        // Try to load from API and update if available
        if (Get.isRegistered<CategoryService>()) {
          final service = Get.find<CategoryService>();
          final apiCategories = await service.fetchCategoriesWithIcons();
          if (apiCategories.isNotEmpty) {
            setState(() {
              categories = apiCategories;
            });
          }
        }
      } else {
        // Income categories (static only for now)
        categories = CategoryModel.getIncomeCategories().map((category) => {
          'id': category.name.toLowerCase().replaceAll(' ', '_'),
          'name': category.name,
          'iconPath': category.icon,
          'description': category.description ?? '',
        }).toList();
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.type == 'expense' ? 'Select Expense Category' : 'Select Income Category',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: widget.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.8,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = widget.selectedCategory == category['name'];

            return GestureDetector(
              onTap: () {
                widget.onCategorySelected(
                  category['name'],
                  category['id'],
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? (widget.isDarkMode ? Colors.blue.shade800 : Colors.blue.shade100)
                      : (widget.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Colors.blue
                        : (widget.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Category Icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blue
                            : (widget.isDarkMode ? Colors.grey.shade700 : Colors.white),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.asset(
                          category['iconPath'],
                          width: 24,
                          height: 24,
                          color: isSelected
                              ? Colors.white
                              : (widget.isDarkMode ? Colors.white70 : Colors.grey.shade700),
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.category,
                              size: 24,
                              color: isSelected
                                  ? Colors.white
                                  : (widget.isDarkMode ? Colors.white70 : Colors.grey.shade700),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Category Name
                    Text(
                      category['name'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? Colors.blue
                            : (widget.isDarkMode ? Colors.white : Colors.black),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}