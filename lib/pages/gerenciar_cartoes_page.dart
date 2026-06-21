import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/compra_model.dart';
import '../components/menu_lateral.dart';
import '../main.dart';
import 'home_page.dart';

class GerenciarCartoesPage extends StatefulWidget {
  final VoidCallback onAtualizado;
  const GerenciarCartoesPage({super.key, required this.onAtualizado});

  @override
  State<GerenciarCartoesPage> createState() => _GerenciarCartoesPageState();
}

class _GerenciarCartoesPageState extends State<GerenciarCartoesPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>> _cartoes = [];
  List<CompraModel> _compras = [];
  final _nomeController = TextEditingController();
  final _fechController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _fechController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    final dadosCartoes = await StorageService.obterConfiguracaoCartoes();
    final dadosCompras = await StorageService.carregarCompras();
    if (!mounted) return;
    setState(() {
      _cartoes = List<Map<String, dynamic>>.from(dadosCartoes);
      _compras = dadosCompras;
    });
  }

  Future<void> _salvarEAtualizar() async {
    await StorageService.salvarConfiguracaoCartoes(_cartoes);
    widget.onAtualizado();
  }

  void _exibirDialogoAdicionar() {
    _nomeController.clear();
    _fechController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo Cartão'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nomeController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nome do Cartão'),
            ),
            TextField(
              controller: _fechController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Dia do Fechamento (1-31)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () {
              final dia = int.tryParse(_fechController.text);
              if (_nomeController.text.trim().isEmpty ||
                  dia == null ||
                  dia < 1 ||
                  dia > 31) {
                return;
              }
              setState(() {
                _cartoes.add({
                  'nome': _nomeController.text.trim(),
                  'fechamento': dia,
                });
              });
              _salvarEAtualizar();
              Navigator.pop(context);
            },
            child: const Text('SALVAR'),
          ),
        ],
      ),
    );
  }

  Future<bool> _exibirAvisoUltimoCartao() async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('Aviso'),
          ],
        ),
        content: const Text(
          'Você precisa de pelo menos 1 cartão ativo.',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'ENTENDI',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
    return resultado ?? false;
  }

  Future<bool> _exibirAvisoComprasPendentes(String nomeCartao) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.report_problem, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('Atenção'),
          ],
        ),
        content: Text(
          'O cartão "$nomeCartao" possui compras parceladas ativas. Se você excluir, essas contas sumirão do resumo.\n\nDeseja mesmo excluir?',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'CANCELAR',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'EXCLUIR MESMO ASSIM',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
    return resultado ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
              'Meus Cartões',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            backgroundColor: isDark
                ? const Color(0xFF1E1E1E)
                : const Color(0xFF1976D2),
            foregroundColor: Colors.white,
            centerTitle: true,
            elevation: 4.0, // Adicionado sombreado
            shadowColor: isDark
                ? Colors.black54
                : Colors.black26, // Sombra adaptativa
            toolbarHeight: 64.0, // Altura padronizada com respiro
          ),
          drawer: MenuLateral(
            compras: _compras,
            onRemoverCompra: (id) {},
            onAdicionarCompra: (compra) {},
            onCartoesAtualizados: _carregarDados,
          ),
          body: _cartoes.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum cartão cadastrado.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _cartoes.length,
                  itemBuilder: (context, index) {
                    final item = _cartoes[index];
                    return Dismissible(
                      key: Key(item['nome'] + index.toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
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
                      confirmDismiss: (direction) async {
                        if (_cartoes.length <= 1) {
                          return await _exibirAvisoUltimoCartao();
                        }
                        final String nomeDoCartao = item['nome']
                            .toString()
                            .trim()
                            .toLowerCase();
                        final temComprasAtivas = _compras.any(
                          (c) =>
                              c.cartao.trim().toLowerCase() == nomeDoCartao &&
                              c.estaAtiva,
                        );
                        if (temComprasAtivas) {
                          return await _exibirAvisoComprasPendentes(
                            item['nome'],
                          );
                        }
                        return true;
                      },
                      onDismissed: (direction) {
                        final cartaoRemovido = item;
                        setState(() {
                          _cartoes.removeAt(index);
                        });
                        _salvarEAtualizar();

                        messengerKey.currentState?.clearSnackBars();
                        messengerKey.currentState?.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Cartão ${cartaoRemovido['nome']} removido',
                            ),
                            duration: const Duration(seconds: 3),
                            action: SnackBarAction(
                              label: 'DESFAZER',
                              onPressed: () {
                                setState(() {
                                  _cartoes.insert(index, cartaoRemovido);
                                });
                                _salvarEAtualizar();
                                messengerKey.currentState?.clearSnackBars();
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.credit_card,
                            size: 28,
                            color: Colors.blue,
                          ),
                          title: Text(
                            item['nome'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          subtitle: Text(
                            'Fecha todo dia ${item['fechamento']}',
                          ),
                        ),
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: _exibirDialogoAdicionar,
            backgroundColor: isDark
                ? const Color(0xFF1E1E1E)
                : const Color(0xFF1976D2),
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}
