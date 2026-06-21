import 'package:flutter/material.dart';
import '../models/compra_model.dart';
import '../components/seletor_cartao.dart';
import '../components/seletor_parcelas.dart';
import '../components/seletor_parcela_atual.dart';
import '../components/menu_lateral.dart';
import '../services/storage_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _parenteController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _localController = TextEditingController();

  String _cartaoSelecionado = '';
  List<String> _nomesCartoes = [];
  int _parcelasSelecionadas = 1;
  int _parcelaAtualSelecionada = 1;
  bool _inserirPorValorParcela = false;
  bool _ehAssinaturaRecorrente = false;
  List<CompraModel> _compras = [];
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  Future<void> _carregarDadosIniciais() async {
    final dadosCarregados = await StorageService.carregarCompras();
    final configCartoes =
        await StorageService.obterConfiguracaoCartoes(); // Corrigido para português
    final List<String> nomesExtraidos = configCartoes
        .map((c) => c['nome'] as String)
        .toList();
    if (!mounted) return;
    setState(() {
      _compras = dadosCarregados;
      _nomesCartoes = nomesExtraidos;
      if (_nomesCartoes.isNotEmpty && _cartaoSelecionado.isEmpty) {
        _cartaoSelecionado = _nomesCartoes.first;
      }
    });
  }

  Future<void> _salvarCompra() async {
    if (!_formKey.currentState!.validate()) return;
    final valorLimpo = _valorController.text.replaceAll(',', '.');
    final double? valorDigitado = double.tryParse(valorLimpo);
    if (valorDigitado == null || valorDigitado <= 0) return;

    double valorTotalCalculado = valorDigitado;
    int parcelasFinais = _ehAssinaturaRecorrente ? 999 : _parcelasSelecionadas;
    if (_inserirPorValorParcela && !_ehAssinaturaRecorrente) {
      valorTotalCalculado = valorDigitado * _parcelasSelecionadas;
    }

    final novaCompra = CompraModel(
      id: DateTime.now().toString(),
      parente: _parenteController.text.trim(),
      valorTotal: valorTotalCalculado,
      local: _localController.text.trim(),
      cartao: _cartaoSelecionado,
      totalParcelas: parcelasFinais,
      dataCompra: DateTime.now(),
    );

    setState(() {
      _compras.add(novaCompra);
      _parenteController.clear();
      _valorController.clear();
      _localController.clear();
    });
    await StorageService.salvarCompras(_compras);
  }

  @override
  void dispose() {
    _parenteController.dispose();
    _valorController.dispose();
    _localController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const Color azulTopo = Color(0xFF1976D2);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
          Navigator.pop(context);
        } else {
          _scaffoldKey.currentState?.openDrawer();
        }
      },
      child: SafeArea(
        child: Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: const Text(
              'Fatora',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            centerTitle: true,
            backgroundColor: azulTopo,
            foregroundColor: Colors.white,
            elevation: 4.0,
            shadowColor: isDark ? Colors.black54 : Colors.black26,
            toolbarHeight: 64.0,
          ),
          drawer: MenuLateral(
            compras: _compras,
            onRemoverCompra: (id) {},
            onAdicionarCompra: (c) {},
            onCartoesAtualizados: _carregarDadosIniciais,
          ),
          body: _nomesCartoes.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Quem usou o cartão?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _parenteController,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            hintText: 'Ex: João...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'Obrigatório'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _inserirPorValorParcela
                                    ? 'Qual o valor da parcela?'
                                    : 'Qual o valor total da compra?',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (!_ehAssinaturaRecorrente)
                              Switch(
                                thumbColor: WidgetStateProperty.resolveWith<Color>((
                                  states,
                                ) {
                                  if (states.contains(WidgetState.selected)) {
                                    return azulTopo; // Bolinha azul quando ligado
                                  }
                                  return isDark
                                      ? Colors.grey.shade400
                                      : Colors
                                            .white; // Bolinha branca/cinza destacada quando desligado
                                }),
                                trackColor:
                                    WidgetStateProperty.resolveWith<Color>((
                                      states,
                                    ) {
                                      if (states.contains(
                                        WidgetState.selected,
                                      )) {
                                        return azulTopo.withAlpha(76);
                                      }
                                      return isDark
                                          ? Colors.grey.shade800
                                          : Colors
                                                .grey
                                                .shade300; // Fundo contrastante
                                    }),
                                value: _inserirPorValorParcela,
                                onChanged: (val) => setState(
                                  () => _inserirPorValorParcela = val,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _valorController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            hintText: '0,00',
                            prefixText: 'R\$ ',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'Obrigatório'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Onde foi comprado?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _localController,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            hintText: 'Ex: Mercado...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'Obrigatório'
                              : null,
                        ),
                        const SizedBox(height: 24),
                        SeletorCartao(
                          cartaoSelecionado: _cartaoSelecionado,
                          listaCartoes: _nomesCartoes,
                          onSelected: (n) =>
                              setState(() => _cartaoSelecionado = n),
                        ),
                        const SizedBox(height: 24),
                        Card(
                          elevation: 0,
                          color: isDark ? Colors.white : Colors.blue.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.blue.shade200,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'É uma assinatura mensal?',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.black
                                          : Colors.blueAccent,
                                    ),
                                  ),
                                ),
                                Switch(
                                  thumbColor: WidgetStateProperty.resolveWith<Color>((
                                    states,
                                  ) {
                                    if (states.contains(WidgetState.selected)) {
                                      return azulTopo; // Bolinha azul quando ligado
                                    }
                                    return isDark
                                        ? Colors.grey.shade400
                                        : Colors
                                              .white; // Bolinha branca/cinza destacada quando desligado
                                  }),
                                  trackColor:
                                      WidgetStateProperty.resolveWith<Color>((
                                        states,
                                      ) {
                                        if (states.contains(
                                          WidgetState.selected,
                                        )) {
                                          return azulTopo.withAlpha(76);
                                        }
                                        return isDark
                                            ? Colors.grey.shade800
                                            : Colors
                                                  .grey
                                                  .shade300; // Fundo contrastante
                                      }),
                                  value: _ehAssinaturaRecorrente,
                                  onChanged: (val) => setState(() {
                                    _ehAssinaturaRecorrente = val;
                                    if (val) _inserirPorValorParcela = false;
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!_ehAssinaturaRecorrente) ...[
                          const SizedBox(height: 16),
                          SeletorParcelas(
                            parcelas: _parcelasSelecionadas,
                            onChanged: (n) =>
                                setState(() => _parcelasSelecionadas = n),
                          ),
                          SeletorParcelaAtual(
                            parcelaAtual: _parcelaAtualSelecionada,
                            totalParcelas: _parcelasSelecionadas,
                            onChanged: (n) =>
                                setState(() => _parcelaAtualSelecionada = n),
                          ),
                        ],
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: _salvarCompra,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'SALVAR COMPRA',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
