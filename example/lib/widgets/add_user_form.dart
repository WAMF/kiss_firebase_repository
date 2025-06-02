import 'package:flutter/material.dart';
import 'package:kiss_firebase_repository/kiss_firebase_repository.dart';
import 'package:kiss_firebase_repository_example/data_model.dart';

class AddUserForm extends StatefulWidget {
  final Repository<User> userRepository;
  final VoidCallback? onUserAdded;

  const AddUserForm({
    super.key,
    required this.userRepository,
    this.onUserAdded,
  });

  @override
  State<AddUserForm> createState() => _AddUserFormState();
}

class _AddUserFormState extends State<AddUserForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _addUser() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty) {
      _showSnackBar('Please fill in both name and email');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = User(
        id: '', // Will be auto-generated
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        createdAt: DateTime.now(),
      );

      // Create user with auto-generated Firestore ID
      await widget.userRepository.addAutoIdentified(
        user,
        updateObjectWithId: (user, id) => user.copyWith(id: id),
      );

      _nameController.clear();
      _emailController.clear();
      _showSnackBar('User added successfully!');
      widget.onUserAdded?.call();
    } catch (e) {
      _showSnackBar('Error adding user: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Add New User',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _addUser,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add),
            label: Text(_isLoading ? 'Adding...' : 'Add User'),
          ),
        ],
      ),
    );
  }
}
