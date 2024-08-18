import 'package:flutter/material.dart';
import '../widgets/records.dart';
import '../widgets/table.dart';

class DataTab extends StatefulWidget {
  @override
  _DataTabState createState() => _DataTabState();
}

class _DataTabState extends State<DataTab> {
  bool _showRecords = true;

  void _toggleView() {
    setState(() {
      _showRecords = !_showRecords;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get current theme data

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _showRecords ? 'High Scores' : 'Exercise Data',
        ),
        leading: IconButton(
          icon: Icon(
            _showRecords ? Icons.celebration : Icons.storage,
            color: theme.iconTheme.color, // Use theme icon color
          ),
          onPressed: _toggleView,
        ),
        backgroundColor:
            theme.appBarTheme.backgroundColor, // Use theme app bar color
      ),
      body: _showRecords ? RecordsTab() : TableTab(),
    );
  }
}
