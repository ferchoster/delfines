import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'data/local_database.dart';
import 'features/home_shell.dart';
Future<void> main() async { WidgetsFlutterBinding.ensureInitialized(); await LocalDatabase.instance.initialize(); runApp(const LosDelfinesApp()); }
class LosDelfinesApp extends StatelessWidget { const LosDelfinesApp({super.key}); @override Widget build(BuildContext context)=>MaterialApp(title:'Cevichería Los Delfines ERP',debugShowCheckedModeBanner:false,theme:AppTheme.light,darkTheme:AppTheme.dark,themeMode:ThemeMode.light,home:const HomeShell()); }
