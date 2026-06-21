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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configuração Inicial',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Bem-vindo ao Fatora!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Configure abaixo os cartões que você costuma emprestar para organizar suas faturas.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _nomeControllers.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              if (_nomeControllers.length > 1)
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _removerCartaoCampo(index),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _nomeControllers[index],
                            style: const TextStyle(fontSize: 18),
                            decoration: InputDecoration(
                              labelText: 'Nome do Cartão',
                              hintText: _obterHintExemplo(index),
                              border: const OutlineInputBorder(),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'O nome do cartão é obrigatório'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _fechControllers[index],
                            style: const TextStyle(fontSize: 18),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Dia de Fechamento da Fatura',
                              border: OutlineInputBorder(),
                              hintText: 'Ex: 10',
                            ),
                            validator: _validarDia,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: _adicionarCartaoCampo,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.blue.shade700, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: Icon(Icons.add, color: Colors.blue.shade700),
                label: Text(
                  'ADICIONAR OUTRO CARTÃO',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 35),

              ElevatedButton(
                onPressed: _salvarConfiguracao,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'COMEÇAR A USAR',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
