import 'package:flutter/material.dart';

class RepositoryInfoWidget extends StatelessWidget {
  const RepositoryInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Repository Features Demonstrated:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('• Auto-generated Firestore IDs'),
          const Text('• Real-time streaming updates'),
          const Text('• CRUD operations (Create, Read, Update, Delete)'),
          const Text('• Custom Query system with QueryBuilder'),
          const Text('• Search queries (QueryByName, QueryByMaxAge)'),
          const Text('• Error handling'),
          const Text('• Firebase emulator integration'),
          const SizedBox(height: 8),
          Text(
            'Collection: users | Query System: UserQueryBuilder',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
