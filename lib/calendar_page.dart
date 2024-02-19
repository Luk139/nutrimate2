//calendar_page.dart
import 'package:flutter/material.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calorie Tracker Calendar'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _buildMonths(),
        ),
      ),
    );
  }

  List<Widget> _buildMonths() {
    List<Widget> months = [];
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;

    for (int month = 1; month <= 12; month++) {
      final daysInMonth = DateTime(currentYear, month + 1, 0).day;
      final days = List.generate(daysInMonth, (index) => index + 1);

      months.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '${_getMonthName(month)} $currentYear',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Wrap(
              children: days.map((day) {
                return Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.all(5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    color: (month == currentMonth && day == now.day) ? Colors.blue : null,
                  ),
                  child: Text(
                    day.toString(),
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    }

    return months;
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'January';
      case 2:
        return 'February';
      case 3:
        return 'March';
      case 4:
        return 'April';
      case 5:
        return 'May';
      case 6:
        return 'June';
      case 7:
        return 'July';
      case 8:
        return 'August';
      case 9:
        return 'September';
      case 10:
        return 'October';
      case 11:
        return 'November';
      case 12:
        return 'December';
      default:
        return '';
    }
  }
}
