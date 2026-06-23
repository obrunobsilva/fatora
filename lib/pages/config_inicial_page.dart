import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/storage_service.dart';
import 'home_page.dart';

class ConfigInicialPage extends StatefulWidget {
  const ConfigInicialPage({super.key});

  @override
  State<ConfigInicialPage> createState() => _ConfigInicialPageState();
}

class _ConfigInicialPageState extends State<ConfigInicialPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _fechamentoController = TextEditingController();

  @override
  void dispose() {
    _nomeController.dispose();
    _fechamentoController.dispose();
    super.dispose();
  }

  Future<void> _concluirConfiguracao() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final int? diaFechamento = int.tryParse(_fechamentoController.text.trim());
    if (diaFechamento == null || diaFechamento < 1 || diaFechamento > 31) {
      return;
    }

    FocusScope.of(context).unfocus();

    final List<Map<String, dynamic>> cartaoInicial = [
      {'nome': _nomeController.text.trim(), 'fechamento': diaFechamento},
    ];

    await StorageService.salvarConfiguracaoCartoes(cartaoInicial);

    if (!mounted) return;

    HapticFeedback.vibrate();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: 'HomePage'),
        builder: (context) => const HomePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<BoxShadow> profundidadeSutil = [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.5)
            : Colors.black.withValues(alpha: 0.04),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: isDark
            ? Colors.white.withValues(alpha: 0.02)
            : Colors.white.withValues(alpha: 0.4),
        blurRadius: 1,
        offset: const Offset(0, -1),
      ),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Text(
                  'Bem-vindo ao Fatora',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Para começar, cadastre o seu primeiro cartão de crédito de forma simples.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  'Nome do cartão',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: profundidadeSutil,
                  ),
                  child: TextFormField(
                    controller: _nomeController,
                    textCapitalization: TextCapitalization.words,
                    style: TextStyle(color: theme.colorScheme.primary),
                    decoration: InputDecoration(
                      hintText: 'Ex: Nubank, Inter, Visa...',
                      hintStyle: TextStyle(
                        color: theme.colorScheme.secondary.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white10 : Colors.black12,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Obrigatório'
                        : null,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Dia do fechamento',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: profundidadeSutil,
                  ),
                  child: TextFormField(
                    controller: _fechamentoController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: theme.colorScheme.primary),
                    decoration: InputDecoration(
                      hintText: 'Digite um dia entre 1 e 31...',
                      hintStyle: TextStyle(
                        color: theme.colorScheme.secondary.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white10 : Colors.black12,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Obrigatório';
                      }
                      final dia = int.tryParse(val.trim());
                      if (dia == null || dia < 1 || dia > 31) {
                        return 'Digite um dia válido (1 a 31)';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 48),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? const Color(0xFF3A3A3C).withValues(alpha: 0.4)
                            : Colors.black.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _concluirConfiguracao,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF3A3A3C)
                          : theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isDark ? Colors.white10 : Colors.transparent,
                          width: 1,
                        ),
                      ),
                    ),
                    child: const Text(
                      'Começar a usar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
