import 'package:flutter/material.dart';
class AppTheme {
  static const navy=Color(0xFF082B45), navy2=Color(0xFF124765), aqua=Color(0xFF19A7A1), gold=Color(0xFFC7A45D);
  static ThemeData get light=>ThemeData(useMaterial3:true,colorScheme:ColorScheme.fromSeed(seedColor:navy,primary:navy,secondary:aqua,surface:const Color(0xFFF4F7F8)),scaffoldBackgroundColor:const Color(0xFFF4F7F8),appBarTheme:const AppBarTheme(backgroundColor:navy,foregroundColor:Colors.white,elevation:0),cardTheme:CardThemeData(color:Colors.white,elevation:1,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16))),inputDecorationTheme:InputDecorationTheme(border:OutlineInputBorder(borderRadius:BorderRadius.circular(12))));
  static ThemeData get dark=>ThemeData.dark(useMaterial3:true).copyWith(colorScheme:ColorScheme.fromSeed(seedColor:navy,brightness:Brightness.dark,secondary:aqua));
}
