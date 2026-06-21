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
      themeMode: ThemeMode.system, // Segue o tema do celular automaticamente
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue.shade700,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue.shade400,
          brightness: Brightness.dark,
          surface: const Color(0xFF1E1E1E),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
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
