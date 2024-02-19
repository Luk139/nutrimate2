import 'package:flutter/material.dart';
import 'package:nutrimate/nutrient_tracker_home_page.dart';
import 'database_helper.dart';
import 'calendar_page.dart'; // Import the calendar page

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final databaseHelper = DatabaseHelper();
  runApp(MyApp(databaseHelper: databaseHelper));
} 

class MyApp extends StatefulWidget {
  final DatabaseHelper databaseHelper;

  const MyApp({Key? key, required this.databaseHelper}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _currentThemeMode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currentThemeMode = _getThemeModeFromBrightness(
          MediaQuery.of(context).platformBrightness);
    });
  }

  ThemeMode _getThemeModeFromBrightness(Brightness brightness) {
    return brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
  }

  void _toggleThemeMode() {
    setState(() {
      _currentThemeMode = _currentThemeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  Color _getAppBarColor() {
    return _currentThemeMode == ThemeMode.dark
        ? const Color(0xFF28C849)! // Dark mode color
        : const Color(0xFF28C849); // Light mode color
  }

  Color _getTextColor() {
    return _currentThemeMode == ThemeMode.dark ? Colors.black : Colors.black;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentThemeMode =
        _getThemeModeFromBrightness(MediaQuery.of(context).platformBrightness);
  }

  void _navigateToCalendarPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CalendarPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor:const Color(0xFF28C849),
        // Add other theme properties as needed for the light theme
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor:const Color(0xFF28C849)
        // Add other theme properties as needed for the dark theme
      ),
      themeMode: _currentThemeMode,
      home: Scaffold(
        appBar: MyAppBar(
          title: 'Nutrient Tracker',
          textColor: _getTextColor(),
          backgroundColor: _getAppBarColor(),
          onToggleTheme: _toggleThemeMode,
          onCalendarPagePressed: () {
            _navigateToCalendarPage(context);
          },
        ),
        body: NutrientTrackerHomePage(databaseHelper: widget.databaseHelper),
      ),
    );
  }
}

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color textColor;
  final Color backgroundColor;
  final VoidCallback onToggleTheme;
  final VoidCallback onCalendarPagePressed;

  const MyAppBar({
    Key? key,
    required this.title,
    required this.textColor,
    required this.backgroundColor,
    required this.onToggleTheme,
    required this.onCalendarPagePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      title: Text(title, style: TextStyle(color: textColor)),
      actions: [
        IconButton(
          icon: Icon(Icons.lightbulb, color: textColor),
          onPressed: onToggleTheme,
        ),
        IconButton(
          icon: Icon(Icons.calendar_today, color: textColor),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CalendarPage()),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
