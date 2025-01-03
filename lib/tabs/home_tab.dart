import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'visualization_tab.dart';
import 'inputs_tab.dart';
import 'summary_tab.dart';
import '../widgets/settings/settings.dart';
import 'table_tab.dart';
import 'records_tab.dart';

class ExerciseStoreApp extends StatelessWidget {
  final AppTheme appTheme;
  final ValueChanged<AppTheme> updateTheme;
  final bool isKg;
  final bool bodyweightEnabledGlobal;
  final ValueChanged<bool> toggleUnit;
  final ValueChanged<bool> toggleBodyweightEnabledGlobal;
  final String aggregationMethod;
  final ValueChanged<String> setAggregationMethod;
  final String plotType;
  final ValueChanged<String> setPlotType;

  const ExerciseStoreApp({
    super.key,
    required this.appTheme,
    required this.updateTheme,
    required this.isKg,
    required this.bodyweightEnabledGlobal,
    required this.toggleUnit,
    required this.toggleBodyweightEnabledGlobal,
    required this.aggregationMethod,
    required this.setAggregationMethod,
    required this.plotType,
    required this.setPlotType,
  });

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
        bodyweightEnabledGlobal: bodyweightEnabledGlobal,
        toggleUnit: toggleUnit,
        toggleBodyweightEnabledGlobal: toggleBodyweightEnabledGlobal,
        aggregationMethod: aggregationMethod,
        setAggregationMethod: setAggregationMethod,
        plotType: plotType,
        setPlotType: setPlotType,
      ),
    );
  }
}

class ExerciseStoreHomePage extends StatefulWidget {
  final AppTheme appTheme;
  final ValueChanged<AppTheme> updateTheme;
  final bool isKg;
  final bool bodyweightEnabledGlobal;
  final ValueChanged<bool> toggleUnit;
  final String aggregationMethod;
  final ValueChanged<String> setAggregationMethod;
  final String plotType;
  final ValueChanged<String> setPlotType;
  final ValueChanged<bool> toggleBodyweightEnabledGlobal;

  const ExerciseStoreHomePage({
    super.key,
    required this.appTheme,
    required this.updateTheme,
    required this.isKg,
    required this.bodyweightEnabledGlobal,
    required this.toggleUnit,
    required this.toggleBodyweightEnabledGlobal,
    required this.aggregationMethod,
    required this.setAggregationMethod,
    required this.plotType,
    required this.setPlotType,
  });

  @override
  ExerciseStoreHomePageState createState() => ExerciseStoreHomePageState();
}

class ExerciseStoreHomePageState extends State<ExerciseStoreHomePage>
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
    _pageController = PageController(initialPage: 2);
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
          bodyweightEnabledGlobal: widget.bodyweightEnabledGlobal,
          isKg: widget.isKg,
          onUnitChanged: widget.toggleUnit,
          onBodyweightEnabledGlobalChanged:
              widget.toggleBodyweightEnabledGlobal,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/icon/wave_app_icon_transparent_thumbnail.png',
          height: 45, // Adjust the height as needed
          fit: BoxFit.contain,
        ),
        centerTitle: true, // Center the logo in the AppBar
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: theme.iconTheme.color),
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
            RecordsTab(
                isKg: widget.isKg,
                bodyweightEnabledGlobal: widget.bodyweightEnabledGlobal),
            SummaryTab(
              selectedDay: _selectedDay,
              onDateSelected: _onDateSelected,
              isKg: widget.isKg,
              bodyweightEnabledGlobal: widget.bodyweightEnabledGlobal,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ExerciseSetter(
                isKg: widget.isKg,
                onExerciseAdded: () {
                  setState(() {});
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: VisualizationTab(
                key: const PageStorageKey('visualizationTab'),
                isKg: widget.isKg,
                bodyweightEnabledGlobal: widget.bodyweightEnabledGlobal,
                defaultAggregationMethod: widget.aggregationMethod,
                defaultChartType: widget.plotType,
              ),
            ),
            TableTab(isKg: widget.isKg),
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
