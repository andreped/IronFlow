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
    return Scaffold(
      appBar: AppBar(
        title: Text(_showRecords ? 'Records' : 'Exercise Data'),
        leading: IconButton(
          icon: Icon(_showRecords ? Icons.celebration : Icons.storage),
          onPressed: _toggleView,
        ),
      ),
      body: _showRecords ? RecordsTab() : TableTab(),
    );
  }
}
