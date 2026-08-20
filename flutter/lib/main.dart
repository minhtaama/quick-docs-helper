import 'package:flutter/material.dart';
import 'widgets/pages/homepage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quick Docs Helper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: Colors.black87,
          onPrimary: Colors.white,
          secondaryContainer: Colors.grey[300],
          onSecondaryContainer: Colors.black87,
        ),
        useMaterial3: true,
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
      home: const SelectionArea(child: HomePage()),
    );
  }
}
