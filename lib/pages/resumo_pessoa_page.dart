import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/compra_model.dart';
import '../components/menu_lateral.dart';
import '../services/storage_service.dart';
import 'home_page.dart';

class ResumoPessoaPage extends StatefulWidget {
  final List<CompraModel> compras;
  final Function(String) onRemover;
  final Function(CompraModel) onAdicionar;
  final VoidCallback onCartoesAtualizados;

  const ResumoPessoaPage({
    super.key,
    required this.compras,
    required this.onRemover,
    required this.onAdicionar,
    required this.onCartoesAtualizados,
  });

  @override
  State<ResumoPessoaPage> createState() => _ResumoPessoaPageState();
}

class _ResumoPessoaPageState extends State<ResumoPessoaPage> {
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
    final Color corCalendario = isDark ? Colors.white : const Color(0xFF1976D2);

    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );
    final DateFormat dateFormat = DateFormat('dd/MM');
    final DateFormat nomeMesFormat = DateFormat("MMMM 'de' yyyy", 'pt_BR');

    final comprasDoMes = widget.compras.where((c) {
      final diaFech = _obterDiaFechamento(c.cartao);
      return c.estaAtivaNoMes(_mesVisualizado, diaFech);
    }).toList();

    final Map<String, List<CompraModel>> agrupadoPorPessoa = {};
    for (var compra in comprasDoMes) {
      final chavePessoa = compra.parente.trim();
      if (!agrupadoPorPessoa.containsKey(chavePessoa)) {
        agrupadoPorPessoa[chavePessoa] = [];
      }
      agrupadoPorPessoa[chavePessoa]!.add(compra);
    }

    final listaPessoasOrdenada = agrupadoPorPessoa.keys.toList()..sort();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            settings: const RouteSettings(name: 'HomePage'),
            pageBuilder: (context, anim, seqAnim) => const HomePage(),
            transitionsBuilder: (context, anim, seqAnim, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      },
      child: SafeArea(
        child: Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: const Text(
              'Total por Pessoa',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            centerTitle: true,
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor: Colors.white,
            elevation: 4.0, // Adiciona o sombreado de profundidade
            shadowColor: isDark
                ? Colors.black54
                : Colors.black26, // Sombra adaptativa
            toolbarHeight: 64.0, // Aumenta a altura para dar respiro interno
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
          body: Column(
            children: [
              Container(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.blue.shade50,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 8,
                ), // Aumentado o padding vertical
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios,
                        size: 28,
                        color: corCalendario,
                      ),
                      onPressed: () => setState(
                        () => _mesVisualizado = DateTime(
                          _mesVisualizado.year,
                          _mesVisualizado.month - 1,
                        ),
                      ),
                    ),
                    Text(
                      nomeMesFormat.format(_mesVisualizado).toUpperCase(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: corCalendario,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.arrow_forward_ios,
                        size: 28,
                        color: corCalendario,
                      ),
                      onPressed: () => setState(
                        () => _mesVisualizado = DateTime(
                          _mesVisualizado.year,
                          _mesVisualizado.month + 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: comprasDoMes.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhuma conta para este mês.',
                          style: TextStyle(
                            fontSize: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12.0),
                        itemCount: listaPessoasOrdenada.length,
                        itemBuilder: (context, index) {
                          final nomeParente = listaPessoasOrdenada[index];
                          final comprasDaPessoa =
                              agrupadoPorPessoa[nomeParente]!;
                          double totalPessoa = comprasDaPessoa.fold(
                            0,
                            (soma, c) => soma + c.valorParcela,
                          );

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        nomeParente,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1976D2),
                                        ),
                                      ),
                                      Text(
                                        currencyFormat.format(totalPessoa),
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 16, thickness: 1),
                                  ...comprasDaPessoa.map((compra) {
                                    final diaFech = _obterDiaFechamento(
                                      compra.cartao,
                                    );
                                    final parcNoMes = compra
                                        .calcularParcelaNoMes(
                                          _mesVisualizado,
                                          diaFech,
                                        );
                                    final textParc = compra.totalParcelas == 1
                                        ? "À vista"
                                        : (compra.ehAssinatura
                                              ? "Assinatura"
                                              : "$parcNoMes de ${compra.totalParcelas}");

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 3.0,
                                        horizontal: 4.0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${compra.local} (${compra.cartao})',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w500,
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  '${dateFormat.format(compra.dataCompra)} • $textParc',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            currencyFormat.format(
                                              compra.valorParcela,
                                            ),
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
