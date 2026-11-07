import 'class_item.dart';

// His API returns pagination info alongside the list — this entity carries
// that through so the UI knows "page 1 of 3", not just the raw list.
class ClassListResult {
  final List<ClassItem> items;
  final int page;
  final int totalPages;
  final int total;

  ClassListResult({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.total,
  });
}
