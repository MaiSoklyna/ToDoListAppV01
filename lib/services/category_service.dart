import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _categoriesRef => _firestore.collection('categories');

  Future<List<TaskCategory>> getCategories(String userId) async {
    final snapshot = await _categoriesRef
        .where('userId', isEqualTo: userId)
        .get();
    if (snapshot.docs.isEmpty) {
      return TaskCategory.defaultCategories;
    }
    return snapshot.docs
        .map((doc) => TaskCategory.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<void> addCategory(TaskCategory category) async {
    await _categoriesRef.doc(category.id).set(category.toJson());
  }

  Future<void> updateCategory(TaskCategory category) async {
    await _categoriesRef.doc(category.id).update(category.toJson());
  }

  Future<void> deleteCategory(String categoryId) async {
    await _categoriesRef.doc(categoryId).delete();
  }
}
