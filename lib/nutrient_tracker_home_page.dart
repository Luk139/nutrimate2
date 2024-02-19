import 'package:flutter/material.dart';
import 'database_helper.dart';

class NutrientTrackerHomePage extends StatefulWidget {
  final DatabaseHelper databaseHelper;

  const NutrientTrackerHomePage({Key? key, required this.databaseHelper}) : super(key: key);

  @override
  State<NutrientTrackerHomePage> createState() => _NutrientTrackerHomePageState();
}

class _NutrientTrackerHomePageState extends State<NutrientTrackerHomePage> {
  late Brightness _brightness;

  int _totalCalories = 0;
  int _totalCarbs = 0;
  int _totalFats = 0;
  int _totalProtein = 0;
  int _streakCount = 0;

  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _fatsController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchNutrientsFromDatabase();
    _calculateStreak();
    _brightness = WidgetsBinding.instance!.window.platformBrightness;
    // Fetch initial values from the database
  }

  Color _getButtonTextColor(BuildContext context) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  return isDarkMode ? Colors.white : Colors.black;
}


  Future<void> _calculateStreak() async {
    final streak = await widget.databaseHelper.calculateStreak();
    final lastLogDate = await widget.databaseHelper.getLastLogDate();
    final currentDate = DateTime.now();

    if (lastLogDate == null || !isSameDay(currentDate, lastLogDate)) {
      // If there are no logs for today or the last log date is not today
      if (isYesterday(currentDate, lastLogDate)) {
        // If the last log date was yesterday, increase the streak count
        _streakCount++;
      } else {
        // Otherwise, reset the streak count
        _streakCount = 1;
      }
    }

    setState(() {
      // Update the streak count in the widget's state
      _streakCount = streak;
    });
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool isYesterday(DateTime date1, DateTime? date2) {
    if (date2 == null) return false;
    final yesterday = date1.subtract(Duration(days: 1));
    return isSameDay(yesterday, date2);
  }

  Future<void> _fetchNutrientsFromDatabase() async {
    try {
      final Map<String, int> nutrientValues = await widget.databaseHelper.fetchNutrients();
      setState(() {
        _totalCalories = nutrientValues['calories'] ?? 0;
        _totalCarbs = nutrientValues['carbs'] ?? 0;
        _totalFats = nutrientValues['fats'] ?? 0;
        _totalProtein = nutrientValues['protein'] ?? 0;
      });
    } catch (e) {
      print("Error fetching nutrients: $e");
    }
  }

  DateTime _lastNutrientAddedDate = DateTime.now(); // Initialize with current date

  DateTime _getLastNutrientAddedDate() {
    return _lastNutrientAddedDate;
  }

  void _updateLastNutrientAddedDate(DateTime date) {
    _lastNutrientAddedDate = date;
  }

  Future<void> _increaseStreakCount() async {
    final DateTime lastNutrientAddedDate = _getLastNutrientAddedDate();
    final DateTime currentDate = DateTime.now();

    if (currentDate.year == lastNutrientAddedDate.year &&
        currentDate.month == lastNutrientAddedDate.month &&
        currentDate.day == lastNutrientAddedDate.day) {
      // Same day, no need to increase streak count
      return;
    }

    final int streak = await widget.databaseHelper.calculateStreak();
    _streakCount = streak + 1;
    setState(() {});
  }

  void _addNutrientsToDatabase(int calories, int carbs, int fats, int protein) async {
    // Calculate calories if only grams are provided
    if (calories == 0) {
      calories = (fats * 9) + (carbs * 4) + (protein * 4);
    }

    // Get the current date
    DateTime currentDate = DateTime.now();

    // Get the date of the last nutrient added
    DateTime lastNutrientAddedDate = _getLastNutrientAddedDate();

    // If the last nutrient was added on a different day, increase the streak count
    if (currentDate.difference(lastNutrientAddedDate).inDays > 0) {
      await _increaseStreakCount(); // Await here if _increaseStreakCount() is asynchronous
    }

    // Update the last nutrient added date in the database
    _updateLastNutrientAddedDate(currentDate);

    // Add nutrients to the database
    await widget.databaseHelper.addNutrients(calories, carbs, fats, protein);

    // Fetch nutrients from the database after adding nutrients
    _fetchNutrientsFromDatabase();
    await _calculateStreak(); // Call _calculateStreak() after updating streak count
  }

  void _subtractNutrientsFromDatabase(int calories, int carbs, int fats, int protein) async {
    // Calculate calories if only grams are provided
    if (calories == 0) {
      calories = (fats * 9) + (carbs * 4) + (protein * 4);
    }

    await widget.databaseHelper.subtractNutrients(calories, carbs, fats, protein, () {
      // Fetch nutrients from the database after subtracting nutrients
      _fetchNutrientsFromDatabase();
    });
  }

 Future<void> _showAddNutrientsDialog(BuildContext context) async {
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: isLightMode ? Colors.white : Colors.black,
          title: Text(
            'Add Nutrients',
            style: TextStyle(
              color: isLightMode ? Colors.black : Colors.white,
            ),
          ),
          content: Column(
            children: [
              _buildNutrientTextField('Calories', _caloriesController),
              _buildNutrientTextField('Carbs (g)', _carbsController),
              _buildNutrientTextField('Fats (g)', _fatsController),
              _buildNutrientTextField('Protein (g)', _proteinController),
            ],
          ),
          actions: <Widget>[
            // Cancel button
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isLightMode ? Colors.black : Colors.white,
                ),
              ),
            ),
            // Add button
            TextButton(
              onPressed: () {
                final int calories = int.tryParse(_caloriesController.text) ?? 0;
                final int carbs = int.tryParse(_carbsController.text) ?? 0;
                final int fats = int.tryParse(_fatsController.text) ?? 0;
                final int protein = int.tryParse(_proteinController.text) ?? 0;

                _addNutrientsToDatabase(calories, carbs, fats, protein);

                _caloriesController.clear();
                _carbsController.clear();
                _fatsController.clear();
                _proteinController.clear();

                Navigator.of(dialogContext).pop();
              },
              child: Text(
                'Add',
                style: TextStyle(
                  color: isLightMode ? Colors.black : Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSubtractNutrientsDialog(BuildContext context) async {
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: isLightMode ? Colors.black : Colors.white,
          title: Text(
            'Subtract Nutrients',
            style: TextStyle(
              color: isLightMode ? Colors.white : Colors.black,
            ),
          ),
          content: Column(
            children: [
              _buildNutrientTextField('Calories', _caloriesController),
              _buildNutrientTextField('Carbs (g)', _carbsController),
              _buildNutrientTextField('Fats (g)', _fatsController),
              _buildNutrientTextField('Protein (g)', _proteinController),
            ],
          ),
          actions: <Widget>[
            // Cancel button
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isLightMode ? Colors.white : Colors.black,
                ),
              ),
            ),
            // Subtract button
            TextButton(
              onPressed: () {
                final int calories = int.tryParse(_caloriesController.text) ?? 0;
                final int carbs = int.tryParse(_carbsController.text) ?? 0;
                final int fats = int.tryParse(_fatsController.text) ?? 0;
                final int protein = int.tryParse(_proteinController.text) ?? 0;

                _subtractNutrientsFromDatabase(calories, carbs, fats, protein);

                _caloriesController.clear();
                _carbsController.clear();
                _fatsController.clear();
                _proteinController.clear();

                Navigator.of(dialogContext).pop();
              },
              child: Text(
                'Subtract',
                style: TextStyle(
                  color: isLightMode ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        );
      },
    );
  }


  Widget _buildNutrientTextField(String nutrientName, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: 'Enter $nutrientName'),
      onChanged: (String value) {
        // Handle input validation or parsing if needed
      },
    );
  }

  Future<void> _resetNutrientsInDatabase() async {
    try {
      await widget.databaseHelper.resetNutrients();
      _fetchNutrientsFromDatabase(); // Fetch nutrients after resetting
    } catch (e) {
      print("Error resetting nutrients: $e");
      // Handle the error, possibly display a message to the user
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _buildNutrientWidget(context, 'Calories', _totalCalories),
            _buildNutrientWidget(context, 'Carbs', _totalCarbs),
            _buildNutrientWidget(context, 'Fats', _totalFats),
            _buildNutrientWidget(context, 'Protein', _totalProtein),
            ElevatedButton(
              onPressed: () {
                _resetNutrientsInDatabase();
              },
              style: ElevatedButton.styleFrom(
backgroundColor: const Color(0xFF3EC067),
              ),
              child: SizedBox(
                width: 200,
                child: Text(
                  'Reset Nutrients',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _getButtonTextColor(context),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16), // Add some space
            ElevatedButton(
              onPressed: () {
                _showAddNutrientsDialog(context);
              },
              style: ElevatedButton.styleFrom(
backgroundColor: const Color(0xFF3EC067),
              ),
              child: SizedBox(
                width: 200,
                child: Text(
                  'Add Nutrients',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _getButtonTextColor(context),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16), // Add some space
            ElevatedButton(
              onPressed: () {
                _showSubtractNutrientsDialog(context);
              },
              style: ElevatedButton.styleFrom(
backgroundColor: const Color(0xFF3EC067),
              ),
              child: SizedBox(
                width: 200,
                child: Text(
                  'Subtract Nutrients',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _getButtonTextColor(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientWidget(BuildContext context, String nutrientName, int nutrientCount) {
    final Color textColor = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;

    return Column(
      children: <Widget>[
        const SizedBox(height: 16),
        Text(
          'Total $nutrientName:',
          style: TextStyle(fontSize: 18, color: textColor),
        ),
        Text(
          '$nutrientCount',
          style: TextStyle(fontSize: 24, color: textColor),
        ),
      ],
    );
  }
}
