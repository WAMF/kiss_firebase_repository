import 'package:flutter/material.dart';
import 'package:kiss_firebase_repository/kiss_firebase_repository.dart';
import 'package:kiss_firebase_repository_example/data_model.dart';
import 'package:kiss_firebase_repository_example/queries.dart';
import 'user_list_widget.dart';

class RecentUsersTab extends StatelessWidget {
  final RepositoryFirestore<User> userRepository;
  final int daysBack;

  const RecentUsersTab({
    super.key,
    required this.userRepository,
    this.daysBack = 7,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Recent Users (Last $daysBack Days)',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: UserListWidget(
              userRepository: userRepository,
              query: QueryRecentUsers(daysBack),
            ),
          ),
        ),
      ],
    );
  }
}
