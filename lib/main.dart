import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'pages/home_page.dart';
import 'pages/config_inicial_page.dart';
import 'services/storage_service.dart';

final GlobalKey<ScaffoldMessengerState> messengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bool configurado = await StorageService.isConfigurado();
  runApp(
    FatoraApp(
      telaInicial: configurado ? const HomePage() : const ConfigInicialPage(),
    ),
  );
}

class FatoraApp extends StatelessWidget {
  final Widget telaInicial;
  const FatoraApp({super.key, required this.telaInicial});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fatora',
      scaffoldMessengerKey: messengerKey,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF2F2F7),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1D1D1F),
          secondary: Color(0xFF6E6E73),
          surface: Colors.white,
          error: Color(0xFFFF453A),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF2F2F7),
          foregroundColor: Color(0xFF1D1D1F),
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1D1F),
            letterSpacing: -0.5,
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF000000),
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          secondary: Color(0xFF86868B),
          surface: Color(0xFF1D1D1F),
          error: Color(0xFFFF453A),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF000000),
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      home: telaInicial,
    );
  }
}
