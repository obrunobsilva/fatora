import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/compra_model.dart';
import '../components/campo_padrao.dart';
import '../components/seletor_cartao.dart';
import '../components/seletor_parcelas.dart';
import '../components/seletor_parcela_atual.dart';
import '../components/menu_lateral.dart';
import '../services/storage_service.dart';
import '../utils/formatadores.dart';
import 'gerenciar_cartoes_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const int _maxParcelas = 48;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _pessoaController = TextEditingController();
  final FocusNode _pessoaFocus = FocusNode();
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _localController = TextEditingController();

  String _cartaoSelecionado = '';
  List<String> _nomesCartoes = [];
  List<CompraModel> _compras = [];

  int _parcelasSelecionadas = 1;
  int _parcelaInicial = 1;
  bool _porValorParcela = false;
  bool _assinatura = false;

  bool _carregando = true;
  bool _erro = false;

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  @override
  void dispose() {
    _pessoaController.dispose();
    _pessoaFocus.dispose();
    _valorController.dispose();
    _localController.dispose();
    super.dispose();
  }

  Future<void> _carregarDadosIniciais() async {
    try {
      final compras = await StorageService.carregarCompras();
      final cartoes = await StorageService.obterConfiguracaoCartoes();
      if (!mounted) return;
      final nomes = cartoes.map((c) => c['nome'] as String).toList();
      setState(() {
        _compras = compras;
        _nomesCartoes = nomes;
        if (!nomes.contains(_cartaoSelecionado)) {
          _cartaoSelecionado = nomes.isEmpty ? '' : nomes.first;
        }
        _carregando = false;
        _erro = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar dados: $e');
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro = true;
      });
    }
  }

  Future<void> _salvarCompra() async {
    if (!_formKey.currentState!.validate()) return;

    final centavosDigitados = lerCentavos(_valorController.text);
    if (centavosDigitados == null || centavosDigitados <= 0) {
      mostrarAviso(context, 'Informe um valor maior que zero.');
      return;
    }
    FocusScope.of(context).unfocus();

    // Parcelas só valem quando o switch "valor da parcela" está ligado.
    final bool parcelado = !_assinatura && _porValorParcela;
    final parcelas = _assinatura
        ? CompraModel.tipoAssinatura
        : (parcelado ? _parcelasSelecionadas : 1);
    final totalCentavos = parcelado
        ? centavosDigitados * _parcelasSelecionadas
        : centavosDigitados;

    final nova = CompraModel(
      id: StorageService.novoId(),
      parente: canonicalizarNome(
        _pessoaController.text,
        StorageService.nomesPessoas(_compras),
      ),
      valorTotalCentavos: totalCentavos,
      local: limparNome(_localController.text),
      cartao: _cartaoSelecionado,
      totalParcelas: parcelas,
      // Só vale para compra parcelada; à vista e assinatura começam na 1.
      parcelaInicial: (parcelado && _parcelasSelecionadas > 1)
          ? _parcelaInicial
          : 1,
      dataCompra: DateTime.now(),
    );

    final novaLista = [..._compras, nova];
    StorageService.ordenar(novaLista);

    try {
      await StorageService.salvarCompras(novaLista);
    } catch (e) {
      debugPrint('Erro ao salvar compra: $e');
      if (!mounted) return;
      mostrarAviso(context, 'Não foi possível salvar. Tente novamente.');
      return;
    }
    if (!mounted) return;

    setState(() {
      _compras = novaLista;
      _pessoaController.clear();
      _valorController.clear();
      _localController.clear();
      _parcelasSelecionadas = 1;
      _parcelaInicial = 1;
      _porValorParcela = false;
      _assinatura = false;
    });
    HapticFeedback.mediumImpact();
    mostrarAviso(
      context,
      'Compra registrada com sucesso!',
      icone: Icons.check_circle_outline_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Sem PopScope: o Android já fecha o menu lateral no "voltar"
    // e, com o menu fechado, o "voltar" sai do app normalmente.
    return Scaffold(
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
          _compras.removeWhere((c) => c.id == id);
          await _persistirLista();
        },
        onAdicionarCompra: (compra) async {
          _compras.add(compra);
          StorageService.ordenar(_compras);
          await _persistirLista();
        },
        onCartoesAtualizados: _carregarDadosIniciais,
      ),
      body: SafeArea(bottom: true, child: _corpo(theme, isDark)),
    );
  }

  Future<void> _persistirLista() async {
    try {
      await StorageService.salvarCompras(_compras);
    } catch (e) {
      debugPrint('Erro ao salvar: $e');
      if (mounted) {
        mostrarAviso(context, 'Não foi possível salvar a alteração.');
      }
    }
    if (mounted) setState(() {});
  }

  Widget _corpo(ThemeData theme, bool isDark) {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erro) {
      return _mensagemComBotao(
        theme,
        'Não foi possível carregar seus dados.',
        'Tentar de novo',
        () {
          setState(() => _carregando = true);
          _carregarDadosIniciais();
        },
      );
    }
    if (_nomesCartoes.isEmpty) {
      return _mensagemComBotao(
        theme,
        'Nenhum cartão cadastrado.',
        'Cadastrar cartão',
        () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                GerenciarCartoesPage(onAtualizado: _carregarDadosIniciais),
          ),
        ),
      );
    }
    return _formulario(theme, isDark);
  }

  Widget _mensagemComBotao(
    ThemeData theme,
    String mensagem,
    String botao,
    VoidCallback aoApertar,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: aoApertar, child: Text(botao)),
          ],
        ),
      ),
    );
  }

  Widget _campoPessoa(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) => RawAutocomplete<String>(
        textEditingController: _pessoaController,
        focusNode: _pessoaFocus,
        optionsBuilder: (TextEditingValue valor) {
          final chave = chaveNome(valor.text);
          if (chave.isEmpty) return const Iterable<String>.empty();
          return StorageService.nomesPessoas(_compras).where((nome) {
            final c = chaveNome(nome);
            return c.contains(chave) && c != chave;
          });
        },
        fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
          return CampoPadrao(
            controller: controller,
            focusNode: focusNode,
            hint: 'Ex: João...',
            capitalizacao: TextCapitalization.words,
            validador: (v) =>
                v == null || v.trim().isEmpty ? 'Obrigatório' : null,
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: 200,
                  maxWidth: constraints.maxWidth,
                ),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, i) {
                    final nome = options.elementAt(i);
                    return ListTile(
                      dense: true,
                      title: Text(nome),
                      onTap: () => onSelected(nome),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _formulario(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TituloCampo('Quem usou o cartão?'),
            const SizedBox(height: 8),
            _campoPessoa(theme),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TituloCampo(
                    _porValorParcela
                        ? 'Qual o valor da parcela?'
                        : 'Qual o valor total da compra?',
                  ),
                ),
                if (!_assinatura)
                  SwitchPadrao(
                    valor: _porValorParcela,
                    onChanged: (v) => setState(() {
                      _porValorParcela = v;
                      if (!v) {
                        _parcelasSelecionadas = 1;
                        _parcelaInicial = 1;
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            CampoPadrao(
              controller: _valorController,
              hint: '0,00',
              prefixo: 'R\$ ',
              teclado: TextInputType.number,
              formatadores: [MoedaInputFormatter()],
              validador: (v) {
                final c = lerCentavos(v ?? '');
                return (c == null || c <= 0) ? 'Informe um valor' : null;
              },
            ),
            const SizedBox(height: 24),
            const TituloCampo('Onde ou o que foi comprado?'),
            const SizedBox(height: 8),
            CampoPadrao(
              controller: _localController,
              hint: 'Ex: Mercado, Farmácia, Tênis, Dentista...',
              capitalizacao: TextCapitalization.words,
              validador: (v) =>
                  v == null || v.trim().isEmpty ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 28),
            SeletorCartao(
              cartaoSelecionado: _cartaoSelecionado,
              listaCartoes: _nomesCartoes,
              onSelected: (n) => setState(() => _cartaoSelecionado = n),
            ),
            const SizedBox(height: 24),
            CartaoPadrao(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: TituloCampo('É uma assinatura mensal?'),
                  ),
                  SwitchPadrao(
                    valor: _assinatura,
                    onChanged: (v) => setState(() {
                      _assinatura = v;
                      if (v) {
                        _porValorParcela = false;
                        _parcelasSelecionadas = 1;
                        _parcelaInicial = 1;
                      }
                    }),
                  ),
                ],
              ),
            ),
            if (!_assinatura && _porValorParcela) ...[
              const SizedBox(height: 20),
              SeletorParcelas(
                parcelas: _parcelasSelecionadas,
                onChanged: (n) {
                  // Limita o total e mantém "começar da parcela" válido.
                  final novo = min(max(n, 1), _maxParcelas);
                  setState(() {
                    _parcelasSelecionadas = novo;
                    if (_parcelaInicial > novo) _parcelaInicial = novo;
                  });
                },
              ),
              const SizedBox(height: 12),
              SeletorParcelaAtual(
                parcelaAtual: _parcelaInicial,
                totalParcelas: _parcelasSelecionadas,
                onChanged: (n) => setState(() => _parcelaInicial = n),
              ),
            ],
            const SizedBox(height: 36),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? const Color(0xFF3A3A3C).withValues(alpha: 0.4)
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
                      color: isDark ? Colors.white10 : Colors.transparent,
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
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
