import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'features/home/presentation/pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase with your project credentials.
  await Supabase.initialize(
    url: 'https://ujqxduigkkllytiutcsi.supabase.co', // SUPABASE_URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVqcXhkdWlna2tsbHl0aXV0Y3NpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY0MTg3OTIsImV4cCI6MjA4MTk5NDc5Mn0.y12kU7SFZ51B81zxIHnEalYGfjCGLOpYKXuQx9dXNr0',             // SUPABASE_ANON_KEY
  );

  runApp(const ShujogApp());
}

class ShujogApp extends StatelessWidget {
  const ShujogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shujog',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomePage(),
    );
  }
}
