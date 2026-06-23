import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/compra_model.dart';
import '../components/menu_lateral.dart';
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
    if (!mounted) {
      return;
    }
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
        title: const Text('Aviso'),
        content: const Text('Você precisa de pelo menos 1 cartão ativo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ENTENDI'),
          ),
        ],
      ),
    );
    return resultado ?? false;
  }

  Future<bool> _exibirAvisoExclusao(String nomeCartao) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Cartão?'),
        content: Text(
          'Atenção: O cartão "$nomeCartao" possui compras vinculadas. Se você excluir, TODAS as despesas desse cartão também serão apagadas do histórico de forma definitiva.\n\nDeseja mesmo confirmar a exclusão?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('CONFIRMAR'),
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
          title: const Text('Meus cartões'),
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
            setState(() {
              _compras.removeWhere((item) => item.id == id);
            });
            await StorageService.salvarCompras(_compras);
          },
          onAdicionarCompra: (compra) async {
            setState(() {
              _compras.add(compra);
              _compras.sort((a, b) => b.dataCompra.compareTo(a.dataCompra));
            });
            await StorageService.salvarCompras(_compras);
          },
          onCartoesAtualizados: _carregarDados,
        ),
        body: _cartoes.isEmpty
            ? Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: profundidadeSutil,
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.black12,
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'Nenhum cartão cadastrado.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
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
                        color: theme.colorScheme.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.centerRight,
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: theme.colorScheme.error,
                        size: 24,
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      if (_cartoes.length <= 1) {
                        await _exibirAvisoUltimoCartao();
                        return false;
                      }

                      final dadosComprasAtualizados =
                          await StorageService.carregarCompras();
                      final String nomeDoCartao = item['nome']
                          .toString()
                          .trim()
                          .toLowerCase();

                      final bool temComprasDeFato = dadosComprasAtualizados.any(
                        (c) => c.cartao.trim().toLowerCase() == nomeDoCartao,
                      );

                      if (temComprasDeFato) {
                        return await _exibirAvisoExclusao(item['nome']);
                      }

                      return true;
                    },
                    onDismissed: (direction) async {
                      final String nomeDoCartaoRemovido = item['nome']
                          .toString()
                          .trim()
                          .toLowerCase();

                      setState(() {
                        _cartoes.removeAt(index);
                        _compras.removeWhere(
                          (c) =>
                              c.cartao.trim().toLowerCase() ==
                              nomeDoCartaoRemovido,
                        );
                      });

                      await _salvarEAtualizar();
                      await StorageService.salvarCompras(_compras);
                    },
                    child: Container(
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
                          item['nome'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: -0.3,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Fecha todo dia ${item['fechamento']}',
                            style: TextStyle(
                              color: theme.colorScheme.secondary.withValues(
                                alpha: 0.7,
                              ),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _exibirDialogoAdicionar,
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: isDark ? const Color(0xFF1D1D1F) : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }
}
