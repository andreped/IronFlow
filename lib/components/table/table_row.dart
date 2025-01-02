import 'package:flutter/material.dart';

abstract class TableRowBase extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isKg;
  final Function(Map<String, dynamic>) showEditDialog;
  final Function(Map<String, dynamic>) showFitnessEditDialog;
  final Function(String, int) deleteRow;

  const TableRowBase({
    Key? key,
    required this.item,
    required this.isKg,
    required this.showEditDialog,
    required this.showFitnessEditDialog,
    required this.deleteRow,
  }) : super(key: key);

  List<TableCell> buildCells(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: getColumnWidths(),
      border: TableBorder(
        horizontalInside: BorderSide(
          color: Colors.grey.shade300,
          width: 0.5,
        ),
        verticalInside: BorderSide.none,
        top: BorderSide.none,
        bottom: BorderSide.none,
      ),
      children: [
        TableRow(
          children: buildCells(context),
        ),
      ],
    );
  }

  Map<int, TableColumnWidth> getColumnWidths();
}
