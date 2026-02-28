import 'package:flutter/material.dart';
import 'features/colleagues/colleagues_screen.dart';

class OfficeLedgerApp extends StatelessWidget {
  const OfficeLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Office Ledger',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const ColleaguesScreen(),
    );
  }
}
