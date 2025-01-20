import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/floating_window_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FloatingWindowService.initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI聊天助手',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeScreen(),
    );
  }
}
