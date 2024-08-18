import 'package:flutter/material.dart';
import '../core/theme.dart'; // Import your AppThemes
import '../core/database.dart';
import 'visualization.dart';
import 'inputs.dart';
import 'summary.dart';
import 'data.dart';
import '../widgets/settings.dart';
import '../widgets/table.dart';
import '../widgets/records.dart';

class ExerciseStoreApp extends StatelessWidget {
  final AppTheme appTheme;
  final ValueChanged<AppTheme> updateTheme;
  final bool isKg;
  final ValueChanged<bool> toggleUnit;

  const ExerciseStoreApp({
    Key? key,
    required this.appTheme,
    required this.updateTheme,
    required this.isKg,
    required this.toggleUnit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final themeData = AppThemes.getTheme(appTheme, brightness);

    return MaterialApp(
      title: 'IronFlow',
      theme: themeData,
      darkTheme: AppThemes.darkTheme,
      themeMode: appTheme == AppTheme.system
          ? ThemeMode.system
          : (appTheme == AppTheme.dark ? ThemeMode.dark : ThemeMode.light),
      home: ExerciseStoreHomePage(
        appTheme: appTheme,
        updateTheme: updateTheme,
        isKg: isKg,
        toggleUnit: toggleUnit,
      ),
    );
  }
}

class ExerciseStoreHomePage extends StatefulWidget {
  final AppTheme appTheme;
  final ValueChanged<AppTheme> updateTheme;
  final bool isKg;
  final ValueChanged<bool> toggleUnit;

  const ExerciseStoreHomePage({
    Key? key,
    required this.appTheme,
    required this.updateTheme,
    required this.isKg,
    required this.toggleUnit,
  }) : super(key: key);

  @override
  _ExerciseStoreHomePageState createState() => _ExerciseStoreHomePageState();
}

class _ExerciseStoreHomePageState extends State<ExerciseStoreHomePage>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDay = DateTime.now();
  late TabController _tabController;
  late PageController _pageController;
  final PageStorageBucket bucket = PageStorageBucket();

  void _refreshTable() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: 2)
      ..addListener(() {
        if (_tabController.index == 4) {
          _refreshTable();
        }
      });
    _pageController = PageController(initialPage: 1);
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

  void _openSettings() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SettingsModal(
          appTheme: widget.appTheme,
          onThemeChanged: widget.updateTheme,
          isKg: widget.isKg,
          onUnitChanged: widget.toggleUnit,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/icon/app_icon_transparent.png',
          height: 40, // Adjust the height as needed
          fit: BoxFit.contain,
        ),
        centerTitle: true, // Center the logo in the AppBar
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: PageStorage(
        bucket: bucket,
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) {
            _tabController.animateTo(index);
          },
          children: [
            RecordsTab(),
            SummaryTab(
              selectedDay: _selectedDay,
              onDateSelected: _onDateSelected,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ExerciseSetter(
                onExerciseAdded: () {
                  setState(() {});
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: VisualizationTab(key: PageStorageKey('visualizationTab')),
            ),
            TableTab(),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: TabBar(
          controller: _tabController,
          onTap: (index) {
            _pageController.jumpToPage(index);
          },
          labelStyle: const TextStyle(fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.celebration, size: 27.0)),
            Tab(icon: Icon(Icons.calendar_month, size: 27.0)),
            Tab(icon: Icon(Icons.add_box, size: 27.0)),
            Tab(icon: Icon(Icons.insert_chart, size: 27.0)),
            Tab(icon: Icon(Icons.table_chart, size: 27.0)),
          ],
        ),
      ),
    );
  }
}
