import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smart_doc/widgets/custom_app_bar.dart';

class AdminCategoriesTab extends StatefulWidget {
  const AdminCategoriesTab({super.key});

  @override
  State<AdminCategoriesTab> createState() => _AdminCategoriesTabState();
}

class _AdminCategoriesTabState extends State<AdminCategoriesTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _categoryController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Manage Categories'),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('categories').orderBy('name').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final categories = snapshot.data!.docs;

          if (categories.isEmpty) {
            return const Center(child: Text('No categories found. Add one to get started.'));
          }

          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final categoryName = category['name'] as String;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(categoryName, style: const TextStyle(fontWeight: FontWeight.w500)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueGrey),
                        tooltip: 'Edit Category',
                        onPressed: () => _showCategoryDialog(category: category),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        tooltip: 'Delete Category',
                        onPressed: () => _confirmDeleteCategory(context, category.id, categoryName),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(),
        tooltip: 'Add Category',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCategoryDialog({DocumentSnapshot? category}) {
    _categoryController.text = category != null ? category['name'] : '';
    showDialog(
      context: context,
      builder: (dialogContext) { // Use a different context name
        return AlertDialog(
          title: Text(category == null ? 'Add Category' : 'Edit Category'),
          content: TextField(
            controller: _categoryController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Category Name'),
            textCapitalization: TextCapitalization.characters, // Automatically capitalize input
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final name = _categoryController.text.trim();
                if (name.isNotEmpty) {
                  // **FIX: Pop the dialog before showing snackbar**
                  Navigator.of(dialogContext).pop(); 
                  if (category == null) {
                    await _addCategory(name);
                  } else {
                    await _editCategory(category.id, name);
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // **FIX: Made function async and added validation**
  Future<void> _addCategory(String name) async {
    final upperCaseName = name.toUpperCase();

    final querySnapshot = await _firestore
        .collection('categories')
        .where('name', isEqualTo: upperCaseName)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Category "$name" already exists.'), backgroundColor: Colors.red),
      );
    } else {
      await _firestore.collection('categories').add({'name': upperCaseName});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Category "$name" added.'), backgroundColor: Colors.green),
      );
    }
  }

  // **FIX: Made function async and added validation**
  Future<void> _editCategory(String id, String name) async {
    final upperCaseName = name.toUpperCase();

    final querySnapshot = await _firestore
        .collection('categories')
        .where('name', isEqualTo: upperCaseName)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty && querySnapshot.docs.first.id != id) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Another category named "$name" already exists.'), backgroundColor: Colors.red),
      );
    } else {
      await _firestore.collection('categories').doc(id).update({'name': upperCaseName});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category updated successfully.'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _confirmDeleteCategory(BuildContext context, String categoryId, String categoryName) async {
    final QuerySnapshot result = await _firestore
        .collection('documents')
        .where('category', isEqualTo: categoryName)
        .limit(1)
        .get();

    final bool isBeingUsed = result.docs.isNotEmpty;
    final _forceDeleteController = TextEditingController();

    if (isBeingUsed) {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Warning: This category is in use by one or more documents. Deleting the category will not remove it from the documents. Are you sure you want to proceed?'),
              const SizedBox(height: 10),
              TextField(
                controller: _forceDeleteController,
                decoration: const InputDecoration(
                  labelText: 'Type the category name to confirm',
                ),
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                if (_forceDeleteController.text == categoryName) {
                  Navigator.of(dialogContext).pop(true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Category name does not match.'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Force Delete (Not Recommended)', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        _deleteCategory(categoryId, categoryName);
      }
    } else {
        final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to permanently delete the category "$categoryName"?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        _deleteCategory(categoryId, categoryName);
      }
    }
  }

  void _deleteCategory(String id, String name) {
    _firestore.collection('categories').doc(id).delete();
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Category "$name" has been deleted.'), backgroundColor: Colors.green,)
    );
  }

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }
}
