import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'home_page.dart';

class ConfigInicialPage extends StatefulWidget {
  const ConfigInicialPage({super.key});

  @override
  State<ConfigInicialPage> createState() => _ConfigInicialPageState();
}

class _ConfigInicialPageState extends State<ConfigInicialPage> {
  final _formKey = GlobalKey<FormState>();

  final List<TextEditingController> _nomeControllers = [
    TextEditingController(),
  ];
  final List<TextEditingController> _fechControllers = [
    TextEditingController(),
  ];

  final List<String> _exemplosCartoes = [
    'Nubank',
    'Itaú',
    'Santander',
    'Bradesco',
    'Banco do Brasil',
    'C6 Bank',
    'Inter',
  ];

  @override
  void dispose() {
    for (var c in _nomeControllers) {
      c.dispose();
    }
    for (var c in _fechControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _adicionarCartaoCampo() {
    setState(() {
      _nomeControllers.add(TextEditingController());
      _fechControllers.add(TextEditingController());
    });
  }

  void _removerCartaoCampo(int index) {
    if (_nomeControllers.length <= 1) return;
    setState(() {
      _nomeControllers[index].dispose();
      _fechControllers[index].dispose();
      _nomeControllers.removeAt(index);
      _fechControllers.removeAt(index);
    });
  }

  Future<void> _salvarConfiguracao() async {
    if (!_formKey.currentState!.validate()) return;

    final List<Map<String, dynamic>> listaCartoesParaSalvar = [];

    for (int i = 0; i < _nomeControllers.length; i++) {
      listaCartoesParaSalvar.add({
        'nome': _nomeControllers[i].text.trim(),
        'fechamento': int.parse(_fechControllers[i].text.trim()),
      });
    }

    await StorageService.salvarConfiguracaoCartoes(listaCartoesParaSalvar);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  String? _validarDia(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'O dia de fechamento é obrigatório';
    }
    final dia = int.tryParse(value);
    if (dia == null || dia < 1 || dia > 31) {
      return 'Digite um dia válido (1 a 31)';
    }
    return null;
  }

  String _obterHintExemplo(int index) {
    if (index < _exemplosCartoes.length) {
      return 'Ex: ${_exemplosCartoes[index]}';
    }
    return 'Ex: Cartão de Crédito';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Configuração Inicial')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Bem-vindo ao Fatora',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Configure abaixo os cartões que você costuma emprestar para organizar suas faturas.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 24),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _nomeControllers.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.black12,
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Cartão Nº ${index + 1}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              if (_nomeControllers.length > 1)
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline_rounded,
                                    color: theme.colorScheme.error,
                                  ),
                                  onPressed: () => _removerCartaoCampo(index),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nomeControllers[index],
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Nome do Cartão',
                              labelStyle: TextStyle(
                                color: theme.colorScheme.secondary.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                              hintText: _obterHintExemplo(index),
                              filled: true,
                              fillColor: theme.colorScheme.surface,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black12,
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
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'O nome é obrigatório'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _fechControllers[index],
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 16,
                            ),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Dia de Fechamento da Fatura',
                              labelStyle: TextStyle(
                                color: theme.colorScheme.secondary.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                              hintText: 'Ex: 10',
                              filled: true,
                              fillColor: theme.colorScheme.surface,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black12,
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
                            validator: _validarDia,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _adicionarCartaoCampo,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: Icon(Icons.add_rounded, color: theme.colorScheme.primary),
                label: Text(
                  'ADICIONAR OUTRO CARTÃO',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(height: 36),
              ElevatedButton(
                onPressed: _salvarConfiguracao,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: isDark
                      ? const Color(0xFF1D1D1F)
                      : Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'COMEÇAR A USAR',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
