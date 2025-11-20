import 'package:flutter/material.dart';
import 'responsive_helper.dart';

// Type definitions for clarity
typedef TabSelectionCallback = void Function(int index);
typedef SearchQueryCallback = void Function(String query);

// ✅ Generic filter and sort function
/// Filters a list based on a search query and optionally pins an item to the top
///
/// [items] - The list of items to filter
/// [searchQuery] - The search query string
/// [getItemName] - Function to extract the name/identifier from each item for filtering
/// [pinnedItem] - Optional item that should always appear first in the results
/// [comparePinnedItem] - Function to compare if an item matches the pinned item
List<T> filterAndSortWithPinnedItem<T>({
  required List<T> items,
  required String searchQuery,
  required String Function(T item) getItemName,
  T? pinnedItem,
  bool Function(T item, T pinnedItem)? comparePinnedItem,
}) {
  final lowerCaseQuery = searchQuery.toLowerCase();

  // Filter items based on search query
  List<T> filteredList = items.where((item) {
    return getItemName(item).toLowerCase().contains(lowerCaseQuery);
  }).toList();

  // If there's a pinned item, move it to the top
  if (pinnedItem != null && comparePinnedItem != null) {
    final pinnedIndex = filteredList.indexWhere(
            (item) => comparePinnedItem(item, pinnedItem)
    );

    if (pinnedIndex != -1) {
      final pinnedItemFromList = filteredList.removeAt(pinnedIndex);
      filteredList.insert(0, pinnedItemFromList);
    }
  }

  return filteredList;
}

// 1. Reusable Search Bar Widget
Widget buildGenericSearchBar({
  required double scaleFactor,
  required double textScaleFactor,
  required SearchQueryCallback onSearchQueryChanged,
  String hintText = 'Search files...', // Generic hint text
  required BuildContext context, // Added context for responsive helper
}) {
  final r = ResponsiveHelper(context);

  return Padding(
    padding: EdgeInsets.fromLTRB(r.w(16), r.h(8), r.w(16), r.h(8)),
    child: Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(r.w(12)),
        border: Border.all(
          color: Colors.grey[400]!,
          width: r.w(1),
        ),
      ),
      child: TextField(
        onChanged: onSearchQueryChanged,
        style: TextStyle(
          fontSize: r.fs(14),
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: r.fs(14),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey[500],
            size: r.w(20),
          ),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            vertical: r.h(12),
            horizontal: 0,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
    ),
  );
}

// 2. Reusable Filter Tabs (Wrapper)
Widget buildGenericFilterTabs({
  required double scaleFactor,
  required double scaleFactorHeight,
  required double textScaleFactor,
  required int selectedTabIndex,
  required TabSelectionCallback onTabSelected,
  required List<String> tabLabels,
  required BuildContext context, // Added context for responsive helper
}) {
  final r = ResponsiveHelper(context);

  return Padding(
    padding: EdgeInsets.fromLTRB(r.w(16), 0, r.w(16), r.h(12)),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: EdgeInsets.all(r.w(4)),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(r.w(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: List.generate(tabLabels.length, (index) {
            return _buildTabButton(
              label: tabLabels[index],
              index: index,
              isActive: selectedTabIndex == index,
              scaleFactor: scaleFactor,
              textScaleFactor: textScaleFactor,
              onTap: () => onTabSelected(index),
              context: context, // Pass context
            );
          }),
        ),
      ),
    ),
  );
}

// 3. Single Tab Button (Private helper inside the utils file)
Widget _buildTabButton({
  required String label,
  required int index,
  required bool isActive,
  required double scaleFactor,
  required double textScaleFactor,
  required VoidCallback onTap,
  required BuildContext context, // Added context for responsive helper
}) {
  final r = ResponsiveHelper(context);
  const double baseFontSize = 13.0;

  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: EdgeInsets.all(r.w(2)),
      padding: EdgeInsets.symmetric(vertical: r.h(10), horizontal: r.w(10)),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(r.w(10)),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: r.fs(baseFontSize),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? Colors.black87 : Colors.grey[600],
          ),
        ),
      ),
    ),
  );
}