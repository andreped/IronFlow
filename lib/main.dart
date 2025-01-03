import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tabs/home_tab.dart';
import 'core/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AppTheme _appTheme = AppTheme.system; // Default to system theme
  bool _isKg = true; // Default unit system
  bool _bodyweightEnabledGlobal = true;
  String _aggregationMethod = 'Top3Avg'; // Default aggregation method
  String _plotType = 'Line'; // Default plot type
  late Future<void> _settingsLoaded;
  late Image _logoImage;

  @override
  void initState() {
    super.initState();
    _logoImage = Image.asset(
      'assets/icon/wave_app_icon_transparent_thumbnail.png',
      height: 45, // Adjust the height as needed
      fit: BoxFit.contain,
    );
    _settingsLoaded = _loadSettings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheLogoImage();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _appTheme = AppTheme.values[prefs.getInt('appTheme') ?? _appTheme.index];
      _isKg = prefs.getBool('isKg') ?? _isKg;
      _bodyweightEnabledGlobal =
          prefs.getBool('bodyweightEnabledGlobal') ?? _bodyweightEnabledGlobal;
      _aggregationMethod =
          prefs.getString('aggregationMethod') ?? _aggregationMethod;
      _plotType = prefs.getString('plotType') ?? _plotType;
    });
  }

  Future<void> _precacheLogoImage() async {
    await precacheImage(_logoImage.image, context);
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('appTheme', _appTheme.index);
    await prefs.setBool('isKg', _isKg);
    await prefs.setBool('bodyweightEnabledGlobal', _bodyweightEnabledGlobal);
    await prefs.setString('aggregationMethod', _aggregationMethod);
    await prefs.setString('plotType', _plotType);
  }

  void _toggleTheme(AppTheme newTheme) {
    setState(() {
      _appTheme = newTheme;
    });
    _saveSettings();
  }

  void _toggleUnit(bool newUnit) {
    setState(() {
      _isKg = newUnit;
    });
    _saveSettings();
  }

  void _toggleBodyweightEnabledGlobal(bool newValue) {
    setState(() {
      _bodyweightEnabledGlobal = newValue;
    });
    _saveSettings();
  }

  void _setAggregationMethod(String newMethod) {
    setState(() {
      _aggregationMethod = newMethod;
    });
    _saveSettings();
  }

  void _setPlotType(String newType) {
    setState(() {
      _plotType = newType;
    });
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _settingsLoaded,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a loading indicator while waiting for settings to load
          return const CircularProgressIndicator();
        } else {
          // Get current brightness
          final brightness = MediaQuery.of(context).platformBrightness;
          final themeData = AppThemes.getTheme(_appTheme, brightness);

          return MaterialApp(
            title: 'IronFlow',
            theme: themeData,
            darkTheme: AppThemes.darkTheme,
            themeMode: _appTheme == AppTheme.system
                ? ThemeMode.system
                : (_appTheme == AppTheme.dark ? ThemeMode.dark : ThemeMode.light),
            home: ExerciseStoreHomePage(
              appTheme: _appTheme,
              updateTheme: _toggleTheme,
              isKg: _isKg,
              bodyweightEnabledGlobal: _bodyweightEnabledGlobal,
              toggleUnit: _toggleUnit,
              toggleBodyweightEnabledGlobal: _toggleBodyweightEnabledGlobal,
              aggregationMethod: _aggregationMethod,
              setAggregationMethod: _setAggregationMethod,
              plotType: _plotType,
              setPlotType: _setPlotType,
              logoImage: _logoImage, // Pass the preloaded logo image
            ),
          );
        }
      },
    );
  }
}