import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/compra_model.dart';
import '../components/menu_lateral.dart';
import '../main.dart';
import 'home_page.dart';

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

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final comprasFiltradas = widget.compras.where((item) {
      final termo = _textoBusca.toLowerCase();
      final porParente = item.parente.toLowerCase().contains(termo);
      final porLocal = item.local.toLowerCase().contains(termo);
      final porCartao = item.cartao.toLowerCase().contains(termo);
      return porParente || porLocal || porCartao;
    }).toList();

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
                  begin: const Offset(-1.0, 0.0),
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
              'Histórico de Compras',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            centerTitle: true,
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor: Colors.white,
            elevation: 4.0, // Adicionado sombreado
            shadowColor: isDark
                ? Colors.black54
                : Colors.black26, // Sombra adaptativa
            toolbarHeight: 64.0, // Altura padronizada com respiro
          ),
          drawer: MenuLateral(
            compras: widget.compras,
            onRemoverCompra: widget.onRemover,
            onAdicionarCompra: widget.onAdicionar,
            onCartoesAtualizados: widget.onCartoesAtualizados,
          ),
          body: Column(
            children: [
              if (widget.compras.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _buscaController,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(fontSize: 18),
                    decoration: InputDecoration(
                      labelText: 'Pesquisar...',
                      hintText: 'Digite o nome, local ou cartão',
                      prefixIcon: const Icon(Icons.search, size: 28),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: _textoBusca.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
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
              Expanded(
                child: widget.compras.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhuma compra registrada ainda.',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      )
                    : comprasFiltradas.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhum resultado encontrado.',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
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
                                color: Colors.red.shade600,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.centerRight,
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            onDismissed: (direction) {
                              final compraRemovida = item;
                              final indexOriginal = widget.compras.indexOf(
                                item,
                              );

                              setState(() {
                                widget.onRemover(item.id);
                              });

                              messengerKey.currentState?.clearSnackBars();
                              messengerKey.currentState?.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Compra de ${compraRemovida.parente} removida',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  duration: const Duration(seconds: 3),
                                  action: SnackBarAction(
                                    label: 'DESFAZER',
                                    textColor: Colors.amber,
                                    onPressed: () {
                                      setState(() {
                                        widget.onAdicionar(compraRemovida);
                                        if (indexOriginal <
                                            widget.compras.length) {
                                          widget.compras.removeLast();
                                          widget.compras.insert(
                                            indexOriginal,
                                            compraRemovida,
                                          );
                                        }
                                      });
                                      messengerKey.currentState
                                          ?.clearSnackBars();
                                    },
                                  ),
                                ),
                              );

                              Future.delayed(const Duration(seconds: 3), () {
                                if (!mounted) return;
                                messengerKey.currentState?.clearSnackBars();
                              });
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFF1976D2),
                                  child: Icon(
                                    Icons.credit_card,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  item.parente,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                subtitle: Text(
                                  item.ehAssinatura
                                      ? '${item.local} • Assinatura Mensal'
                                      : '${item.local} • Parcela ${item.parcelaAtual} de ${item.totalParcelas}',
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _currencyFormat.format(item.valorTotal),
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      dataCurtaFormat.format(item.dataCompra),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
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
