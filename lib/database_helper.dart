//database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';


// Define an abstract class for DatabaseHelper
abstract class AbstractDatabaseHelper {
  Future<Database> get database;
  Future<Database> initDatabase();
  addNutrients(int calories, int carbs, int fats, int protein);
  subtractNutrients(int calories, int carbs, int fats, int protein, Function callback);
  fetchNutrients();
}
// DatabaseHelper.dart - Add a new table for logged dates
const String createLogTableQuery = '''
  CREATE TABLE logs(
    id INTEGER PRIMARY KEY,
    date TEXT
  )
''';


// Implement DatabaseHelper by extending AbstractDatabaseHelper
class DatabaseHelper implements AbstractDatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;



  DatabaseHelper._internal();

  static Database? _database;

  @override
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  // Initialize the last nutrient added date
  //This might need to be changes. It initializes        
  //id INTEGER PRIMARY KEY, calories INTEGER, carbs INTEGER, fats INTEGER, protein INTEGER)
  //but actually, it should get initialised with the date aswell. I added it below because I was not sure wether I wanted it that way or not, 
  //but it would be smarter to initialise the database with a current date


Future<Database> initDatabase() async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'nutrient_tracker.db');

  return openDatabase(
    path,
    onCreate: (db, version) async {
      // Create 'nutrients' table
      await db.execute(
        'CREATE TABLE nutrients(id INTEGER PRIMARY KEY, calories INTEGER, carbs INTEGER, fats INTEGER, protein INTEGER)',
      );

      // Create 'logs' table
      await db.execute(
        createLogTableQuery,
      );
    },
    version: 1, // Set the version number
  );
}



Future<DateTime?> getLastLogDate() async {
  final db = await database;

  // Check if the 'logs' table exists in the database
  final result = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='table' AND name='logs'",
  );

  if (result.isNotEmpty) {
    // 'logs' table exists, proceed with querying
    final logResult = await db.rawQuery('SELECT MAX(date) as lastDate FROM logs');
    if (logResult.isNotEmpty && logResult.first['lastDate'] != null) {
      // Parse and return the last date from the query result
      final lastDate = DateTime.parse(logResult.first['lastDate'] as String);
      return lastDate;
    }
  }
  
  // Return a default value if there are no logs or last date is null
  return null;
}


@override
Future<void> addNutrients(int calories, int carbs, int fats, int protein) async {
  final db = await database;

  // Calculate calorie adjustment based on subtracted fats, carbs, and protein
  //final calorieAdjustment = (fats * 9) + (carbs * 4) + (protein * 4);

  // Subtract adjusted values from the database
  await db.insert(
    'nutrients',
    {'calories': calories, 'carbs': carbs, 'fats': fats, 'protein': protein},
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  // Update the last nutrient added date in the logs table
  await db.insert(
    'logs',
    {'date': DateTime.now().toIso8601String()},
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  // Note: Do not fetch nutrients here; let the calling code handle it
}


@override
Future<void> subtractNutrients(int calories, int carbs, int fats, int protein, Function callback) async {
  final db = await database;

  // Calculate the calorie adjustment based on subtracted nutrients
  final calorieAdjustment = (carbs * 4) + (fats * 9) + (protein * 4);

  // Subtract adjusted values from the database
  await db.insert(
    'nutrients',
    {
      'calories': -calories - calorieAdjustment,
      'carbs': -carbs,
      'fats': -fats,
      'protein': -protein,
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  // Call the callback function provided by the calling code
  callback();

  // Note: Do not fetch nutrients here; let the calling code handle it
}




Future<void> resetNutrients() async {
  final db = await database;
  await db.update('nutrients', {'calories': 0, 'carbs': 0, 'fats': 0, 'protein': 0});
}

Future<int> calculateStreak() async {
    final db = await database;

    // Check if the 'logs' table exists
    final result = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='logs'");
    if (result.isEmpty) {
      // 'logs' table does not exist, return a default value (0)
      return 0;
    }

    // 'logs' table exists, proceed with the streak calculation
    final List<Map<String, dynamic>> logResult = await db.query('logs', orderBy: 'date DESC');

    int streak = 0;
    int currentStreak = 0;
    DateTime? lastDate;

    for (var row in logResult) {
      final currentDate = DateTime.parse(row['date']);
      if (lastDate == null || currentDate.difference(lastDate).inDays == 1) {
        currentStreak++;
      } else {
        streak = currentStreak > streak ? currentStreak : streak;
        currentStreak = 1;
      }
      lastDate = currentDate;
    }

    streak = currentStreak > streak ? currentStreak : streak;

    return streak;
  }


@override
Future<Map<String, int>> fetchNutrients() async {
  final db = await database;
  
  final List<Map<String, dynamic>> result = await db.query('nutrients');
  
  if (result.isNotEmpty) {
    int totalCalories = 0;
    int totalCarbs = 0;
    int totalFats = 0;
    int totalProtein = 0;

    for (var record in result) {
      totalCalories += record['calories'] as int;
      totalCarbs += record['carbs'] as int;
      totalFats += record['fats'] as int;
      totalProtein += record['protein'] as int;
    }

    return {
      'calories': totalCalories,
      'carbs': totalCarbs,
      'fats': totalFats,
      'protein': totalProtein,
    };
  } else {
    return {
      'calories': 0,
      'carbs': 0,
      'fats': 0,
      'protein': 0,
    };
  }
}


}