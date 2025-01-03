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
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _loadSettings();
    await Future.delayed(const Duration(seconds: 2)); // Hold splash screen for 1 second
    setState(() {
      _showSplash = false;
    });
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

  Color _getSplashBackgroundColor(ThemeData themeData) {
    if (themeData.brightness == Brightness.dark) {
      return Colors.black; // Use black for dark mode
    } else {
      return themeData.colorScheme.primary.withOpacity(0.1); // Lighten the color for light themes
    }
  }

  Color _getSplashTextColor(ThemeData themeData) {
    return themeData.brightness == Brightness.dark ? Colors.white : Colors.black;
  }

  @override
  Widget build(BuildContext context) {
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
      home: Stack(
        children: [
          ExerciseStoreHomePage(
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
          ),
          if (_showSplash)
            Container(
              color: Colors.white, // Add a white background behind the splash screen
              child: AnimatedOpacity(
                opacity: _showSplash ? 1.0 : 0.0,
                duration: const Duration(seconds: 1), // Slower fade-out duration
                child: Container(
                  color: _getSplashBackgroundColor(themeData), // Use dynamic splash background color
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/icon/wave_app_icon_transparent_thumbnail.png',
                          height: 125, // Adjust the height as needed
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'IronFlow',
                          style: TextStyle(
                            color: _getSplashTextColor(themeData), // Dynamic text color
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none, // Ensure no decoration
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}