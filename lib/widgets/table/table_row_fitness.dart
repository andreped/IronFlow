import 'package:flutter/material.dart';
import '../../components/table/table_row.dart';
import '../../core/convert.dart';

class TableRowFitness extends TableRowBase {
  const TableRowFitness({
    super.key,
    required super.item,
    required super.isKg,
    required super.showEditDialog,
    required super.showFitnessEditDialog,
    required super.deleteRow,
  });

  @override
  List<TableCell> buildCells(BuildContext context) {
    return [
      TableCell(
          child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 14.0),
              child: Text(formatWeight(item['weight'] ?? '', isKg)))),
      TableCell(
          child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 14.0),
              child: Text((item['height'] ?? 0).toString()))),
      TableCell(
          child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 14.0),
              child: Text((item['age'] ?? 0).toString()))),
      TableCell(
          child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 14.0),
              child: Text(formatDate(item['timestamp'] ?? '')))),
      TableCell(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0.0),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.edit,
                    size: 18.0, color: Theme.of(context).colorScheme.secondary),
                onPressed: () {
                  showFitnessEditDialog(item);
                },
              ),
              const SizedBox(width: 0.0),
              IconButton(
                icon: Icon(Icons.delete,
                    size: 18.0, color: Theme.of(context).colorScheme.secondary),
                onPressed: () async {
                  await deleteRow('fitness', item['id'] ?? 0);
                },
              ),
            ],
          ),
        ),
      ),
    ];
  }

  @override
  Map<int, TableColumnWidth> getColumnWidths() {
    return {
      0: const FixedColumnWidth(120.0),
      1: const FixedColumnWidth(90.0),
      2: const FixedColumnWidth(70.0),
      3: const FixedColumnWidth(120.0),
      4: const FixedColumnWidth(130.0),
    };
  }
}
