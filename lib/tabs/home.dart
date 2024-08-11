import 'package:flutter/material.dart';
import '../core/database.dart';
import 'visualization.dart';
import 'inputs.dart';
import 'summary.dart';
import 'records.dart';
import 'table.dart';

class ExerciseStoreApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IronFlow',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ExerciseStoreHomePage(),
    );
  }
}

class ExerciseStoreHomePage extends StatefulWidget {
  @override
  _ExerciseStoreHomePageState createState() => _ExerciseStoreHomePageState();
}

class _ExerciseStoreHomePageState extends State<ExerciseStoreHomePage>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDay = DateTime.now();
  late TabController _tabController;
  final PageController _pageController = PageController();
  final PageStorageBucket bucket = PageStorageBucket();

  void _refreshTable() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this)
      ..addListener(() {
        if (_tabController.index == 4) {
          // Index for 'View Table' tab
          _refreshTable(); // Refresh the table when this tab is selected
        }
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDay = date;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IronFlow'),
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            _pageController.jumpToPage(index);
          },
          labelStyle: TextStyle(fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.add)),
            Tab(icon: Icon(Icons.calendar_month)),
            Tab(icon: Icon(Icons.celebration)),
            Tab(icon: Icon(Icons.insert_chart)),
            Tab(icon: Icon(Icons.table_chart)),
          ],
        ),
      ),
      body: PageStorage(
        bucket: bucket,
        child: PageView(
          controller: _pageController,
          physics:
              const NeverScrollableScrollPhysics(), // Disable swipe gesture
          onPageChanged: (index) {
            _tabController.animateTo(index);
          },
          children: [
            // Log Exercise Tab
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ExerciseSetter(
                onExerciseAdded: () {
                  setState(() {});
                },
              ),
            ),
            // Summary Tab
            SummaryTab(
              selectedDay: _selectedDay,
              onDateSelected: _onDateSelected,
            ),
            // Records Tab
            RecordsTab(), // New Records tab
            // Visualize Data Tab
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: VisualizationTab(key: PageStorageKey('visualizationTab')),
            ),
            // View Table Tab
            TableTab(), // Replaced with TableTab widget
          ],
        ),
      ),
    );
  }
}
