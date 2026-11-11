import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/storage_service.dart';
import '../models/compra_model.dart';
import '../components/campo_padrao.dart';
import '../components/menu_lateral.dart';
import '../utils/formatadores.dart';
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
  bool _carregando = true;
  bool _erro = false;

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _diaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _diaController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    try {
      final cartoes = await StorageService.obterConfiguracaoCartoes();
      final compras = await StorageService.carregarCompras();
      if (!mounted) return;
      setState(() {
        _cartoes = cartoes;
        _compras = compras;
        _carregando = false;
        _erro = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar cartões: $e');
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro = true;
      });
    }
  }

  /// Grava cartões e compras e avisa a Home. Devolve false se falhar.
  Future<bool> _persistir() async {
    try {
      await StorageService.salvarConfiguracaoCartoes(_cartoes);
      await StorageService.salvarCompras(_compras);
      widget.onAtualizado();
      return true;
    } catch (e) {
      debugPrint('Erro ao salvar: $e');
      if (mounted) {
        mostrarAviso(context, 'Não foi possível salvar. Tente novamente.');
      }
      return false;
    }
  }

  // ---------------- adicionar / editar ----------------

  Future<void> _abrirDialogoCartao({int? indice}) async {
    final editando = indice != null;
    final original = editando ? _cartoes[indice] : null;
    _nomeController.text = (original?['nome'] as String?) ?? '';
    _diaController.text = original == null ? '' : '${original['fechamento']}';
    String? erro;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(editando ? 'Editar cartão' : 'Novo cartão'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nomeController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nome do cartão'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _diaController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                decoration: const InputDecoration(
                  labelText: 'Melhor dia de compra (1-31)',
                  helperText:
                      'Primeiro dia em que a compra já entra na próxima fatura '
                      '(o app do banco mostra). Se o mês for mais curto, vale o último dia.',
                  helperMaxLines: 4,
                ),
              ),
              if (erro != null) ...[
                const SizedBox(height: 8),
                Text(
                  erro!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCELAR'),
            ),
            TextButton(
              onPressed: () async {
                final nome = limparNome(_nomeController.text);
                final dia = int.tryParse(_diaController.text);
                if (nome.isEmpty || dia == null || dia < 1 || dia > 31) {
                  setDialog(
                    () => erro = 'Informe o nome e um dia entre 1 e 31.',
                  );
                  return;
                }
                final duplicado = _cartoes.asMap().entries.any(
                  (e) =>
                      e.key != indice &&
                      chaveNome(e.value['nome'] as String) == chaveNome(nome),
                );
                if (duplicado) {
                  setDialog(() => erro = 'Já existe um cartão com esse nome.');
                  return;
                }
                Navigator.pop(dialogContext);
                await _aplicarCartao(indice, nome, dia);
              },
              child: const Text('SALVAR'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _aplicarCartao(int? indice, String nome, int dia) async {
    setState(() {
      if (indice == null) {
        _cartoes.add({'nome': nome, 'fechamento': dia});
      } else {
        final antigo = _cartoes[indice]['nome'] as String;
        _cartoes[indice] = {'nome': nome, 'fechamento': dia};
        if (nome != antigo) {
          // As compras guardam o nome do cartão: renomeia junto.
          _compras = _compras
              .map(
                (c) => chaveNome(c.cartao) == chaveNome(antigo)
                    ? c.copyWith(cartao: nome)
                    : c,
              )
              .toList();
        }
      }
    });
    final ok = await _persistir();
    if (!ok) await _carregarDados();
  }

  // ---------------- excluir ----------------

  Future<void> _avisoUltimoCartao() {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aviso'),
        content: const Text('Você precisa de pelo menos 1 cartão ativo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ENTENDI'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmarExclusao(String nome, int qtdCompras) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir cartão?'),
        content: Text(
          'O cartão "$nome" tem $qtdCompras compra(s). '
          'Se continuar, elas também serão removidas. '
          'Você poderá desfazer logo em seguida.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('EXCLUIR'),
          ),
        ],
      ),
    );
    return r ?? false;
  }

  Future<void> _removerCartao(int indice) async {
    final cartao = _cartoes[indice];
    final chave = chaveNome(cartao['nome'] as String);
    final removidas = _compras
        .where((c) => chaveNome(c.cartao) == chave)
        .toList();

    setState(() {
      _cartoes.removeAt(indice);
      _compras.removeWhere((c) => chaveNome(c.cartao) == chave);
    });
    final ok = await _persistir();
    if (!ok) {
      await _carregarDados();
      return;
    }
    if (!mounted) return;

    mostrarAviso(
      context,
      removidas.isEmpty
          ? 'Cartão removido'
          : 'Cartão removido com ${removidas.length} compra(s)',
      acaoLabel: 'DESFAZER',
      duracao: const Duration(seconds: 6),
      aoAcionar: () async {
        setState(() {
          _cartoes.insert(min(indice, _cartoes.length), cartao);
          _compras.addAll(removidas);
          StorageService.ordenar(_compras);
        });
        final restaurou = await _persistir();
        if (!restaurou) await _carregarDados();
      },
    );
  }

  // ---------------- backup ----------------

  Future<void> _exportar() async {
    try {
      final json = await StorageService.exportarBackup();
      await Clipboard.setData(ClipboardData(text: json));
      if (!mounted) return;
      mostrarAviso(
        context,
        'Backup copiado. Cole numa nota ou mande para você no WhatsApp.',
        icone: Icons.check_circle_outline_rounded,
        duracao: const Duration(seconds: 4),
      );
    } catch (e) {
      debugPrint('Erro ao exportar: $e');
      if (!mounted) return;
      mostrarAviso(context, 'Não foi possível gerar o backup.');
    }
  }

  Future<void> _importar() async {
    final controller = TextEditingController();
    final texto = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: const Text('Importar backup'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Cole o backup abaixo. Isso substitui todos os dados atuais.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 5,
                decoration: const InputDecoration(hintText: 'Cole aqui...'),
              ),
              TextButton.icon(
                onPressed: () async {
                  final dados = await Clipboard.getData(Clipboard.kTextPlain);
                  final colado = dados?.text;
                  if (colado != null) {
                    setDialog(() => controller.text = colado);
                  }
                },
                icon: const Icon(Icons.paste_rounded),
                label: const Text('Colar da área de transferência'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCELAR'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: const Text('IMPORTAR'),
            ),
          ],
        ),
      ),
    );
    if (texto == null || texto.trim().isEmpty) return;

    try {
      final qtd = await StorageService.importarBackup(texto);
      await _carregarDados();
      widget.onAtualizado();
      if (!mounted) return;
      mostrarAviso(
        context,
        '$qtd compra(s) importada(s)',
        icone: Icons.check_circle_outline_rounded,
      );
    } on FormatException {
      if (!mounted) return;
      mostrarAviso(
        context,
        'Backup inválido. Confira se copiou o texto inteiro.',
        duracao: const Duration(seconds: 4),
      );
    } catch (e) {
      debugPrint('Erro ao importar: $e');
      if (!mounted) return;
      mostrarAviso(context, 'Não foi possível importar o backup.');
    }
  }

  // ---------------- tela ----------------

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
          actions: [
            PopupMenuButton<String>(
              onSelected: (v) => v == 'exportar' ? _exportar() : _importar(),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'exportar',
                  child: Text('Exportar backup'),
                ),
                PopupMenuItem(
                  value: 'importar',
                  child: Text('Importar backup'),
                ),
              ],
            ),
          ],
        ),
        drawer: MenuLateral(
          compras: _compras,
          onRemoverCompra: (id) async {
            setState(() => _compras.removeWhere((c) => c.id == id));
            await StorageService.salvarCompras(_compras);
          },
          onAdicionarCompra: (compra) async {
            setState(() {
              _compras.add(compra);
              StorageService.ordenar(_compras);
            });
            await StorageService.salvarCompras(_compras);
          },
          onCartoesAtualizados: _carregarDados,
        ),
        body: _corpo(theme, isDark),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _abrirDialogoCartao(),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: isDark ? const Color(0xFF1D1D1F) : Colors.white,
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }

  Widget _corpo(ThemeData theme, bool isDark) {
    if (_carregando) return const Center(child: CircularProgressIndicator());
    if (_erro) {
      return Center(
        child: TextButton(
          onPressed: () {
            setState(() => _carregando = true);
            _carregarDados();
          },
          child: const Text('Não foi possível carregar. Tentar de novo'),
        ),
      );
    }
    if (_cartoes.isEmpty) {
      return Center(
        child: Text(
          'Nenhum cartão cadastrado.',
          style: TextStyle(color: theme.colorScheme.secondary),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 96),
      itemCount: _cartoes.length,
      itemBuilder: (context, index) {
        final item = _cartoes[index];
        final nome = item['nome'] as String;
        return Dismissible(
          key: ValueKey('$nome#$index'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.error,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.white,
            ),
          ),
          confirmDismiss: (direction) async {
            if (_cartoes.length <= 1) {
              await _avisoUltimoCartao();
              return false;
            }
            final qtd = _compras
                .where((c) => chaveNome(c.cartao) == chaveNome(nome))
                .length;
            if (qtd == 0) return true;
            return _confirmarExclusao(nome, qtd);
          },
          onDismissed: (direction) => _removerCartao(index),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black12,
              ),
              boxShadow: sombraSutil(isDark),
            ),
            child: ListTile(
              onTap: () => _abrirDialogoCartao(indice: index),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : const Color(0xFFF5F5F7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.credit_card_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              title: Text(
                nome,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              subtitle: Text(
                'Compras a partir do dia ${item['fechamento']} vão pra próxima fatura',
                style: TextStyle(color: theme.colorScheme.secondary),
              ),
              trailing: Icon(
                Icons.edit_outlined,
                size: 20,
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
        );
      },
    );
  }
}
