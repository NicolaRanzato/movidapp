import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movidapp/presentation/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

  // await Supabase.initialize(
  //   url: 'https://ecrppeocxgjlbxipmqao.supabase.co',
  //   anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVjcnBwZW9jeGdqbGJ4aXBtcWFvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE3MjQxMTksImV4cCI6MjA2NzMwMDExOX0.ZX_orTh70wfZONWPh0gHF2J8lxC7cGAqo4DZYA6upNY',
  // );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Movidapp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
