import 'package:flutter/material.dart';

TableCell tableHeader(
  String column,
  String sortColumn,
  bool sortAscending,
  Function(String) sortTable,
  BuildContext context,
  bool isKg,
) {
  final weightLabel = isKg ? 'Weight [kg]' : 'Weight [lbs]';
  final title = column == 'Weight' ? weightLabel : column;

  return TableCell(
    child: GestureDetector(
      onTap: () => sortTable(column),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (sortColumn.toLowerCase() == column.toLowerCase())
              Icon(
                sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: Theme.of(context).iconTheme.color,
              ),
          ],
        ),
      ),
    ),
  );
}
