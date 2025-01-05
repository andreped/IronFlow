import 'package:flutter/material.dart';

class SearchBar extends StatelessWidget {
  final TextEditingController searchController;
  final Function(String) onChanged;
  final Color textColor;
  final VoidCallback onClear;

  const SearchBar({
    required this.searchController,
    required this.onChanged,
    required this.textColor,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Search for exercises...',
        hintStyle: TextStyle(color: textColor.withOpacity(0.6)),
        border: InputBorder.none,
      ),
      style: TextStyle(color: textColor),
      onChanged: onChanged,
    );
  }
}
