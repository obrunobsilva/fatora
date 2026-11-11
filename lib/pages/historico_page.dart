import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fatora/main.dart';
import '../models/compra_model.dart';
import '../components/menu_lateral.dart';
import 'home_page.dart';
import '../services/storage_service.dart';
import '../utils/formatadores.dart';

class HistoricoPage extends StatefulWidget {
  final List<CompraModel> compras;
  final Function(String) onRemover;
  final Function(CompraModel) onAdicionar;
  final VoidCallback onCartoesAtualizados;

  const HistoricoPage({
    super.key,
    required this.compras,
    required this.onRemover,
    required this.onAdicionar,
    required this.onCartoesAtualizados,
  });

  @override
  State<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );
  final TextEditingController _buscaController = TextEditingController();
  String _textoBusca = '';

  // Dia de corte (melhor dia de compra) de cada cartão, pela chave do nome.
  Map<String, int> _cortes = {};

  @override
  void initState() {
    super.initState();
    _carregarCortes();
  }

  Future<void> _carregarCortes() async {
    try {
      final cartoes = await StorageService.obterConfiguracaoCartoes();
      if (!mounted) return;
      setState(() {
        _cortes = {
          for (final c in cartoes)
            chaveNome(c['nome'] as String): c['fechamento'] as int,
        };
      });
    } catch (e) {
      debugPrint('Erro ao carregar cartões no histórico: $e');
    }
  }

  int _corteDoCartao(String nome) => _cortes[chaveNome(nome)] ?? 10;

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Busca sem diferenciar maiúscula nem acento.
    final termo = chaveNome(_textoBusca);
    final comprasFiltradas = widget.compras.where((item) {
      final porParente = chaveNome(item.parente).contains(termo);
      final porLocal = chaveNome(item.local).contains(termo);
      final porCartao = chaveNome(item.cartao).contains(termo);
      return porParente || porLocal || porCartao;
    }).toList();

    final List<BoxShadow> profundidadeSutil = [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.5)
            : Colors.black.withValues(alpha: 0.03),
        blurRadius: 12,
        offset: const Offset(0, 4),
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
          title: const Text('Histórico de compras'),
          centerTitle: true,
          backgroundColor: theme.appBarTheme.backgroundColor,
          leading: IconButton(
            icon: Icon(Icons.menu_rounded, color: theme.colorScheme.primary),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ),
        drawer: MenuLateral(
          compras: widget.compras,
          onRemoverCompra: widget.onRemover,
          onAdicionarCompra: widget.onAdicionar,
          onCartoesAtualizados: widget.onCartoesAtualizados,
        ),
        body: SafeArea(
          bottom: true,
          child: Column(
            children: [
              if (widget.compras.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 12.0,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: profundidadeSutil,
                    ),
                    child: TextField(
                      controller: _buscaController,
                      textCapitalization: TextCapitalization.words,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Pesquisar despesas...',
                        labelStyle: TextStyle(
                          color: theme.colorScheme.secondary.withValues(
                            alpha: 0.8,
                          ),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: theme.colorScheme.secondary,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
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
                        suffixIcon: _textoBusca.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  color: theme.colorScheme.secondary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _buscaController.clear();
                                    _textoBusca = '';
                                  });
                                },
                              )
                            : null,
                      ),
                      onChanged: (valor) {
                        setState(() {
                          _textoBusca = valor;
                        });
                      },
                    ),
                  ),
                ),
              Expanded(
                child: widget.compras.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhuma compra registrada ainda',
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.colorScheme.secondary,
                            letterSpacing: -0.2,
                          ),
                        ),
                      )
                    : comprasFiltradas.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhum resultado encontrado',
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.colorScheme.secondary,
                            letterSpacing: -0.2,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 4.0,
                        ),
                        itemCount: comprasFiltradas.length,
                        itemBuilder: (context, index) {
                          final item = comprasFiltradas[index];
                          final DateFormat dataCurtaFormat = DateFormat(
                            'dd/MM',
                          );
                          return Dismissible(
                            key: Key(item.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.centerRight,
                              child: Icon(
                                Icons.delete_outline_rounded,
                                color: theme.colorScheme.error,
                                size: 24,
                              ),
                            ),
                            onDismissed: (direction) {
                              final compraRemovida = item;
                              setState(() {
                                widget.onRemover(item.id);
                              });
                              messengerKey.currentState?.clearSnackBars();
                              messengerKey.currentState?.showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  margin: const EdgeInsets.all(16.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  backgroundColor: theme.colorScheme.primary,
                                  duration: const Duration(seconds: 4),
                                  content: Text(
                                    'Compra de ${compraRemovida.parente} removida',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? const Color(0xFF1D1D1F)
                                          : Colors.white,
                                    ),
                                  ),
                                  action: SnackBarAction(
                                    label: 'DESFAZER',
                                    textColor: isDark
                                        ? Colors.blue.shade400
                                        : Colors.blue.shade300,
                                    onPressed: () {
                                      // O onAdicionar já adiciona, ordena e
                                      // salva. Não mexa na lista aqui.
                                      setState(() {
                                        widget.onAdicionar(compraRemovida);
                                      });
                                      messengerKey.currentState
                                          ?.clearSnackBars();
                                    },
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: profundidadeSutil,
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black12,
                                  width: 1,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white10
                                        : const Color(0xFFF5F5F7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.credit_card_rounded,
                                    color: theme.colorScheme.primary,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  item.parente,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: theme.colorScheme.primary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    '${item.local} • ${item.rotuloParcelaNoMes(DateTime.now(), _corteDoCartao(item.cartao))}',
                                    style: TextStyle(
                                      color: theme.colorScheme.secondary
                                          .withValues(alpha: 0.7),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _currencyFormat.format(item.valorTotal),
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dataCurtaFormat.format(item.dataCompra),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.secondary
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
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
