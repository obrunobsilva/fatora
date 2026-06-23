import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fatora/main.dart';
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

  double _escalaSwitchParcela = 1.0;
  double _escalaSwitchAssinatura = 1.0;

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  Future<void> _carregarDadosIniciais() async {
    try {
      final dadosCarregados = await StorageService.carregarCompras();
      final configCartoes = await StorageService.obterConfiguracaoCartoes();
      final List<String> nomesExtraidos = configCartoes
          .map((c) => c['nome'] as String)
          .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _compras = dadosCarregados;
        _nomesCartoes = nomesExtraidos;
        if (_nomesCartoes.isNotEmpty && _cartaoSelecionado.isEmpty) {
          _cartaoSelecionado = _nomesCartoes.first;
        }
      });
    } catch (e) {
      debugPrint("Erro: $e");
    }
  }

  Future<void> _salvarCompra() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    final valorLimpo = _valorController.text.replaceAll(',', '.');
    final double? valorDigitado = double.tryParse(valorLimpo);
    if (valorDigitado == null || valorDigitado <= 0) {
      return;
    }

    double valorTotalCalculado = valorDigitado;
    int parcelasFinais = _ehAssinaturaRecorrente ? 999 : _parcelasSelecionadas;
    if (_inserirPorValorParcela && !_ehAssinaturaRecorrente) {
      valorTotalCalculado = valorDigitado * _parcelasSelecionadas;
    }

    DateTime dataBase = DateTime.now();

    try {
      final configCartoes = await StorageService.obterConfiguracaoCartoes();
      final cartaoAtual = configCartoes.firstWhere(
        (c) =>
            c['nome'].toString().toLowerCase() ==
            _cartaoSelecionado.toLowerCase(),
        orElse: () => {'fechamento': 25},
      );

      int vencimentoCartao = cartaoAtual['fechamento'] as int;
      int fechamentoReal = vencimentoCartao - 10;
      if (fechamentoReal < 1) {
        fechamentoReal = 1;
      }

      if (dataBase.day >= fechamentoReal) {
        dataBase = DateTime(dataBase.year, dataBase.month + 1, dataBase.day);
      }
    } catch (e) {
      debugPrint("Erro: $e");
    }

    if (!_ehAssinaturaRecorrente && _parcelaAtualSelecionada > 1) {
      dataBase = DateTime(
        dataBase.year,
        dataBase.month - (_parcelaAtualSelecionada - 1),
        dataBase.day,
      );
    }

    final novaCompra = CompraModel(
      id: DateTime.now().toString(),
      parente: _parenteController.text.trim(),
      valorTotal: valorTotalCalculado,
      local: _localController.text.trim(),
      cartao: _cartaoSelecionado,
      totalParcelas: parcelasFinais,
      dataCompra: dataBase,
    );

    if (!mounted) {
      return;
    }

    final localTheme = Theme.of(context);
    final isDarkLocal = localTheme.brightness == Brightness.dark;

    setState(() {
      _compras.add(novaCompra);
      _parenteController.clear();
      _valorController.clear();
      _localController.clear();
      _parcelasSelecionadas = 1;
      _parcelaAtualSelecionada = 1;
      _inserirPorValorParcela = false;
      _ehAssinaturaRecorrente = false;
    });
    await StorageService.salvarCompras(_compras);

    HapticFeedback.vibrate();

    messengerKey.currentState?.clearSnackBars();
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: localTheme.colorScheme.primary,
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: isDarkLocal ? const Color(0xFF1D1D1F) : Colors.white,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              'Compra registrada com sucesso!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkLocal ? const Color(0xFF1D1D1F) : Colors.white,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
          Navigator.pop(context);
        } else {
          _scaffoldKey.currentState?.openDrawer();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Fatora'),
          centerTitle: true,
          backgroundColor: theme.appBarTheme.backgroundColor,
          leading: IconButton(
            icon: Icon(Icons.menu_rounded, color: theme.colorScheme.primary),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ),
        drawer: MenuLateral(
          compras: _compras,
          onRemoverCompra: (id) async {
            _compras.removeWhere((item) => item.id == id);
            await StorageService.salvarCompras(_compras);
            if (mounted) {
              setState(() {});
            }
          },
          onAdicionarCompra: (compra) async {
            _compras.add(compra);
            _compras.sort((a, b) => b.dataCompra.compareTo(a.dataCompra));
            await StorageService.salvarCompras(_compras);
            if (mounted) {
              setState(() {});
            }
          },
          onCartoesAtualizados: _carregarDadosIniciais,
        ),
        body: _nomesCartoes.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Quem usou o cartão?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: profundidadeSutil,
                        ),
                        child: TextFormField(
                          controller: _parenteController,
                          textCapitalization: TextCapitalization.words,
                          style: TextStyle(color: theme.colorScheme.primary),
                          decoration: InputDecoration(
                            hintText: 'Ex: João...',
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _inserirPorValorParcela
                                  ? 'Qual o valor da parcela?'
                                  : 'Qual o valor total da compra?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          if (!_ehAssinaturaRecorrente)
                            GestureDetector(
                              onTapDown: (_) =>
                                  setState(() => _escalaSwitchParcela = 0.92),
                              onTapUp: (_) =>
                                  setState(() => _escalaSwitchParcela = 1.0),
                              onTapCancel: () =>
                                  setState(() => _escalaSwitchParcela = 1.0),
                              child: AnimatedScale(
                                scale: _escalaSwitchParcela,
                                duration: const Duration(milliseconds: 100),
                                child: Switch(
                                  activeThumbColor: isDark
                                      ? const Color(0xFF000000)
                                      : Colors.white,
                                  activeTrackColor: isDark
                                      ? Colors.white
                                      : const Color(0xFF1D1D1F),
                                  inactiveThumbColor: isDark
                                      ? Colors.grey.shade600
                                      : Colors.grey.shade400,
                                  inactiveTrackColor: isDark
                                      ? Colors.white10
                                      : Colors.black12,
                                  value: _inserirPorValorParcela,
                                  onChanged: (val) {
                                    HapticFeedback.lightImpact();
                                    setState(
                                      () => _inserirPorValorParcela = val,
                                    );
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: profundidadeSutil,
                        ),
                        child: TextFormField(
                          controller: _valorController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: TextStyle(color: theme.colorScheme.primary),
                          decoration: InputDecoration(
                            hintText: '0,00',
                            prefixText: 'R\$ ',
                            prefixStyle: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
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
                        'Onde ou o que foi comprado?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: profundidadeSutil,
                        ),
                        child: TextFormField(
                          controller: _localController,
                          textCapitalization: TextCapitalization.words,
                          style: TextStyle(color: theme.colorScheme.primary),
                          decoration: InputDecoration(
                            hintText:
                                'Ex: Mercado, Farmácia, Tênis, Dentista...',
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
                      const SizedBox(height: 28),
                      SeletorCartao(
                        cartaoSelecionado: _cartaoSelecionado,
                        listaCartoes: _nomesCartoes,
                        onSelected: (n) =>
                            setState(() => _cartaoSelecionado = n),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: profundidadeSutil,
                        ),
                        child: Card(
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          color: theme.colorScheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: isDark ? Colors.white10 : Colors.black12,
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'É uma assinatura mensal?',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.primary,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTapDown: (_) => setState(
                                    () => _escalaSwitchAssinatura = 0.92,
                                  ),
                                  onTapUp: (_) => setState(
                                    () => _escalaSwitchAssinatura = 1.0,
                                  ),
                                  onTapCancel: () => setState(
                                    () => _escalaSwitchAssinatura = 1.0,
                                  ),
                                  child: AnimatedScale(
                                    scale: _escalaSwitchAssinatura,
                                    duration: const Duration(milliseconds: 100),
                                    child: Switch(
                                      activeThumbColor: isDark
                                          ? const Color(0xFF000000)
                                          : Colors.white,
                                      activeTrackColor: isDark
                                          ? Colors.white
                                          : const Color(0xFF1D1D1F),
                                      inactiveThumbColor: isDark
                                          ? Colors.grey.shade600
                                          : Colors.grey.shade400,
                                      inactiveTrackColor: isDark
                                          ? Colors.white10
                                          : Colors.black12,
                                      value: _ehAssinaturaRecorrente,
                                      onChanged: (val) {
                                        HapticFeedback.lightImpact();
                                        setState(() {
                                          _ehAssinaturaRecorrente = val;
                                          if (val) {
                                            _inserirPorValorParcela = false;
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (!_ehAssinaturaRecorrente) ...[
                        const SizedBox(height: 20),
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
                      const SizedBox(height: 36),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? const Color(
                                      0xFF3A3A3C,
                                    ).withValues(alpha: 0.4)
                                  : Colors.black.withValues(alpha: 0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _salvarCompra,
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
                                color: isDark
                                    ? Colors.white10
                                    : Colors.transparent,
                                width: 1,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Salvar Registro',
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
