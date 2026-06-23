import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/compra_model.dart';
import '../components/menu_lateral.dart';
import '../services/storage_service.dart';
import 'home_page.dart';

class RelatorioPage extends StatefulWidget {
  final List<CompraModel> compras;
  final Function(String) onRemover;
  final Function(CompraModel) onAdicionar;
  final VoidCallback onCartoesAtualizados;

  const RelatorioPage({
    super.key,
    required this.compras,
    required this.onRemover,
    required this.onAdicionar,
    required this.onCartoesAtualizados,
  });

  @override
  State<RelatorioPage> createState() => _RelatorioPageState();
}

class _RelatorioPageState extends State<RelatorioPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime _mesVisualizado = DateTime.now();
  Map<String, int> _fechamentoCartoes = {};
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarPrazosCartoes();
  }

  Future<void> _carregarPrazosCartoes() async {
    final listaCartoes = await StorageService.obterConfiguracaoCartoes();
    final Map<String, int> mapaFechamentos = {};
    for (var c in listaCartoes) {
      final nome = c['nome'] as String;
      final fechamento = c['fechamento'] as int;
      mapaFechamentos[nome.trim().toLowerCase()] = fechamento;
    }
    if (!mounted) return;
    setState(() {
      _fechamentoCartoes = mapaFechamentos;
      _carregando = false;
    });
  }

  int _obterDiaFechamento(String nomeCartao) {
    final chave = nomeCartao.trim().toLowerCase();
    return _fechamentoCartoes[chave] ?? 10;
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );
    final dateFormat = DateFormat('dd/MM');
    final nomeMesFormat = DateFormat("MMMM 'de' yyyy", 'pt_BR');

    final comprasDoMes = widget.compras.where((c) {
      final diaFech = _obterDiaFechamento(c.cartao);
      return c.estaAtivaNoMes(_mesVisualizado, diaFech);
    }).toList();

    final Map<String, Map<String, List<CompraModel>>> resumoAgrupado = {};

    for (var compra in comprasDoMes) {
      if (!resumoAgrupado.containsKey(compra.cartao)) {
        resumoAgrupado[compra.cartao] = {};
      }
      final parente = compra.parente;
      if (!resumoAgrupado[compra.cartao]!.containsKey(parente)) {
        resumoAgrupado[compra.cartao]![parente] = [];
      }
      resumoAgrupado[compra.cartao]![parente]!.add(compra);
    }

    final List<BoxShadow> profundidadeSutil = [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.5)
            : Colors.black.withValues(alpha: 0.03),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: isDark
            ? Colors.white.withValues(alpha: 0.01)
            : Colors.white.withValues(alpha: 0.3),
        blurRadius: 1,
        offset: const Offset(0, -1),
      ),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.menu_rounded, color: theme.colorScheme.primary),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(
                    () => _mesVisualizado = DateTime(
                      _mesVisualizado.year,
                      _mesVisualizado.month - 1,
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              Text(
                nomeMesFormat.format(_mesVisualizado).toUpperCase(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(
                    () => _mesVisualizado = DateTime(
                      _mesVisualizado.year,
                      _mesVisualizado.month + 1,
                    ),
                  );
                },
              ),
            ],
          ),
          centerTitle: true,
        ),
        drawer: MenuLateral(
          compras: widget.compras,
          onRemoverCompra: widget.onRemover,
          onAdicionarCompra: widget.onAdicionar,
          onCartoesAtualizados: () {
            _carregarPrazosCartoes();
            widget.onCartoesAtualizados();
          },
        ),
        body: SafeArea(
          bottom: true,
          child: Column(
            children: [
              Container(
                color: theme.colorScheme.surface,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      nomeMesFormat.format(_mesVisualizado).toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: comprasDoMes.isEmpty
                    ? Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 32,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: profundidadeSutil,
                            border: Border.all(
                              color: isDark ? Colors.white10 : Colors.black12,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 32,
                                color: theme.colorScheme.secondary.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Nenhuma conta para este mês',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Os lançamentos do período aparecerão aqui',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        children: resumoAgrupado.keys.map((cartao) {
                          final parentesGasto = resumoAgrupado[cartao]!;
                          double totalCartao = 0;

                          for (var listaCompras in parentesGasto.values) {
                            for (var c in listaCompras) {
                              totalCartao += c.valorParcela;
                            }
                          }

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: profundidadeSutil,
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        cartao,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      Text(
                                        currencyFormat.format(totalCartao),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24, thickness: 0.5),
                                  ...parentesGasto.entries.map((entry) {
                                    final nomeParente = entry.key;
                                    final listaDeComprasDoParente = entry.value;
                                    double totalDoParente =
                                        listaDeComprasDoParente.fold(
                                          0,
                                          (s, c) => s + c.valorParcela,
                                        );

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4.0,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                nomeParente,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: theme
                                                      .colorScheme
                                                      .secondary,
                                                ),
                                              ),
                                              Text(
                                                currencyFormat.format(
                                                  totalDoParente,
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        ...listaDeComprasDoParente.map((
                                          compra,
                                        ) {
                                          final diaFech = _obterDiaFechamento(
                                            compra.cartao,
                                          );
                                          final parcNoMes = compra
                                              .calcularParcelaNoMes(
                                                _mesVisualizado,
                                                diaFech,
                                              );
                                          final textParc =
                                              compra.totalParcelas == 1
                                              ? "À vista"
                                              : (compra.ehAssinatura
                                                    ? "Assinatura"
                                                    : "$parcNoMes de ${compra.totalParcelas}");
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 4.0,
                                              horizontal: 8.0,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      compra.local,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    Text(
                                                      '${dateFormat.format(compra.dataCompra)} • $textParc',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: theme
                                                            .colorScheme
                                                            .secondary
                                                            .withValues(
                                                              alpha: 0.7,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  currencyFormat.format(
                                                    compra.valorParcela,
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                        const SizedBox(height: 8),
                                      ],
                                    );
                                  }),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
