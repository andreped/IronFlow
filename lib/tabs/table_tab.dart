import 'package:flutter/material.dart';
import '../core/database.dart';
import '../widgets/table/table_widget.dart';
import '../components/search/search_bar.dart' as custom;

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
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _tableWidgetKey.currentState?.filterData('');
    });
  }

  void _filterRecords(String query) {
    _tableWidgetKey.currentState?.filterData(query);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final textColor =
        theme.brightness == Brightness.dark ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching && _selectedTable == 'exercises'
            ? custom.SearchBar(
                searchController: _searchController,
                onChanged: _filterRecords,
                textColor: textColor,
                onClear: () {
                  _searchController.clear();
                  _filterRecords('');
                },
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_selectedTable == 'exercises')
                    IconButton(
                      icon: Icon(Icons.search, color: theme.iconTheme.color),
                      onPressed: _startSearch,
                    ),
                  const Spacer(),
                  const Text('Table View'),
                  const Spacer(),
                ],
              ),
        leading: _isSearching && _selectedTable == 'exercises'
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
                onPressed: _stopSearch,
              )
            : null,
        actions: _isSearching && _selectedTable == 'exercises'
            ? [
                IconButton(
                  icon: Icon(Icons.clear, color: theme.iconTheme.color),
                  onPressed: () {
                    _searchController.clear();
                    _filterRecords('');
                  },
                ),
              ]
            : [
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
                      _isSearching = false; // Stop searching when table changes
                      _searchController.clear();
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
