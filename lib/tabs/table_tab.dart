import 'package:flutter/material.dart';
import '../core/database.dart';
import '../widgets/table/table_widget.dart';

class TableTab extends StatefulWidget {
  final bool isKg;

  const TableTab({super.key, required this.isKg});

  @override
  TableTabState createState() => TableTabState();
}

class TableTabState extends State<TableTab> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  String _selectedTable = 'exercises';
  final GlobalKey<TableWidgetState> _tableWidgetKey =
      GlobalKey<TableWidgetState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Table View'),
        actions: [
          DropdownButton<String>(
            value: _selectedTable,
            items: const [
              DropdownMenuItem(
                value: 'exercises',
                child: Text('Exercises'),
              ),
              DropdownMenuItem(
                value: 'fitness',
                child: Text('Fitness'),
              ),
            ],
            onChanged: (String? newValue) {
              setState(() {
                _selectedTable = newValue!;
                _tableWidgetKey.currentState?.loadData(_selectedTable);
              });
            },
          ),
        ],
      ),
      body: TableWidget(
        key: _tableWidgetKey,
        selectedTable: _selectedTable,
        isKg: widget.isKg,
        dbHelper: _dbHelper,
      ),
    );
  }
}