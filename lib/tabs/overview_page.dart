import 'package:flutter/material.dart';

class OverviewPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Overview'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Age: 25', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Weight: 70 kg', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Height: 175 cm', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Most Common Exercise: Squats', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
