import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/category_service.dart';

class CategoryViewModel extends ChangeNotifier {
  final CategoryService _categoryService = CategoryService();

  List<TaskCategory> _categories = TaskCategory.defaultCategories;
  bool _isLoading = false;

  List<TaskCategory> get categories => _categories;
  bool get isLoading => _isLoading;

  Future<void> loadCategories(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _categories = await _categoryService.getCategories(userId);
    } catch (e) {
      _categories = TaskCategory.defaultCategories;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCategory(TaskCategory category) async {
    try {
      await _categoryService.addCategory(category);
      _categories.add(category);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await _categoryService.deleteCategory(categoryId);
      _categories.removeWhere((c) => c.id == categoryId);
      notifyListeners();
    } catch (_) {}
  }
}
