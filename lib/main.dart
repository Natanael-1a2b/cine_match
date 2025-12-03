import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'providers/favorites_provider.dart';
import 'providers/recommendation_provider.dart';
import 'services/db_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DBService.instance.init();
  runApp(CineMatchApp());
}

class CineMatchApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => RecommendationProvider()),
      ],
      child: MaterialApp(
        title: 'CineMatch',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF0E0E10),
          primaryColor: Colors.redAccent,
          appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
        ),
        home: SplashScreen(),
      ),
    );
  }
}