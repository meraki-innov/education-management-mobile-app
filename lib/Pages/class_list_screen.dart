import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../features/class/presentation/providers/class_provider.dart';
import '../features/class/domain/entities/class_item.dart';

const _navy = Color(0xFF1E3A8A);
const _bg = Color(0xFFF3F4F6);

class ClassListScreen extends ConsumerStatefulWidget {
  const ClassListScreen({super.key});

  @override
  ConsumerState<ClassListScreen> createState() => _ClassListScreenState();
}

class _ClassListScreenState extends ConsumerState<ClassListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openClassDialog({ClassItem? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final isEditing = existing != null;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEditing ? 'Edit Class' : 'Add Class'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Class name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              final controller = ref.read(classListControllerProvider.notifier);
              try {
                if (isEditing) {
                  await controller.editClass(existing.uid, name);
                } else {
                  await controller.addClass(name);
                }
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().replaceFirst('Exception: ', ''),
                      ),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _navy),
            child: Text(isEditing ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(ClassItem item) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete class?'),
        content: Text('This will permanently delete "${item.name}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await ref
                    .read(classListControllerProvider.notifier)
                    .deleteClass(item.uid);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().replaceFirst('Exception: ', ''),
                      ),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classListControllerProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          'Class',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => _openClassDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Class'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _navy,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                // Kicks off a new search each time the user changes the
                // text — resets to page 1 since the result set changed.
                onChanged: (value) {
                  ref
                      .read(classListControllerProvider.notifier)
                      .loadClasses(search: value, page: 1);
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: classesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          error.toString().replaceFirst('Exception: ', ''),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => ref
                              .read(classListControllerProvider.notifier)
                              .loadClasses(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (result) {
                    if (result.items.isEmpty) {
                      return const Center(
                        child: Text(
                          'No classes found.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            itemCount: result.items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) => _ClassRow(
                              item: result.items[index],
                              onEdit: () => _openClassDialog(
                                existing: result.items[index],
                              ),
                              onDelete: () =>
                                  _confirmDelete(result.items[index]),
                            ),
                          ),
                        ),
                        if (result.totalPages > 1) _Pagination(result: result),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassRow extends StatelessWidget {
  const _ClassRow({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });
  final ClassItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Created ${dateFormat.format(item.createdAt)}  ·  Updated ${dateFormat.format(item.updatedAt)}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pagination extends ConsumerWidget {
  const _Pagination({required this.result});
  final dynamic result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: result.page > 1
                ? () => ref
                      .read(classListControllerProvider.notifier)
                      .loadClasses(page: result.page - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('Page ${result.page} of ${result.totalPages}'),
          IconButton(
            onPressed: result.page < result.totalPages
                ? () => ref
                      .read(classListControllerProvider.notifier)
                      .loadClasses(page: result.page + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
