import 'package:flutter/material.dart';
import '../models/compra_model.dart';
import '../pages/home_page.dart';
import '../pages/historico_page.dart';
import '../pages/relatorio_page.dart';
import '../pages/resumo_pessoa_page.dart';
import '../pages/gerenciar_cartoes_page.dart';

class MenuLateral extends StatelessWidget {
  final List<CompraModel> compras;
  final Function(String) onRemoverCompra;
  final Function(CompraModel) onAdicionarCompra;
  final VoidCallback onCartoesAtualizados;

  const MenuLateral({
    super.key,
    required this.compras,
    required this.onRemoverCompra,
    required this.onAdicionarCompra,
    required this.onCartoesAtualizados,
  });

  Route _criarRotaNativa(Widget pagina, String nomeRota) {
    return MaterialPageRoute(
      settings: RouteSettings(name: nomeRota),
      builder: (context) => pagina,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? rotaAtual = ModalRoute.of(context)?.settings.name;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1D1D1F)
                    : const Color(0xFFF5F5F7),
                border: const Border(bottom: BorderSide.none),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fatora',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Menu de Opções',
                    style: TextStyle(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.add_box_outlined,
                color: theme.colorScheme.primary,
              ),
              title: const Text(
                'Registrar Compra',
                style: TextStyle(fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(context);
                if (rotaAtual != '/' && rotaAtual != 'HomePage') {
                  Navigator.pushReplacement(
                    context,
                    _criarRotaNativa(const HomePage(), 'HomePage'),
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(
                Icons.history_rounded,
                color: theme.colorScheme.primary,
              ),
              title: const Text(
                'Histórico de compras',
                style: TextStyle(fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(context);
                if (rotaAtual != 'HistoricoPage') {
                  Navigator.pushReplacement(
                    context,
                    _criarRotaNativa(
                      HistoricoPage(
                        compras: compras,
                        onRemover: onRemoverCompra,
                        onAdicionar: onAdicionarCompra,
                        onCartoesAtualizados: onCartoesAtualizados,
                      ),
                      'HistoricoPage',
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(
                Icons.analytics_outlined,
                color: theme.colorScheme.primary,
              ),
              title: const Text(
                'Resumo das faturas',
                style: TextStyle(fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(context);
                if (rotaAtual != 'RelatorioPage') {
                  Navigator.pushReplacement(
                    context,
                    _criarRotaNativa(
                      RelatorioPage(
                        compras: compras,
                        onRemover: onRemoverCompra,
                        onAdicionar: onAdicionarCompra,
                        onCartoesAtualizados: onCartoesAtualizados,
                      ),
                      'RelatorioPage',
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(
                Icons.people_outline_rounded,
                color: theme.colorScheme.primary,
              ),
              title: const Text(
                'Total por pessoas',
                style: TextStyle(fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(context);
                if (rotaAtual != 'ResumoPessoaPage') {
                  Navigator.pushReplacement(
                    context,
                    _criarRotaNativa(
                      ResumoPessoaPage(
                        compras: compras,
                        onRemover: onRemoverCompra,
                        onAdicionar: onAdicionarCompra,
                        onCartoesAtualizados: onCartoesAtualizados,
                      ),
                      'ResumoPessoaPage',
                    ),
                  );
                }
              },
            ),
            const Spacer(),
            const Divider(height: 1, thickness: 0.5),
            ListTile(
              leading: Icon(
                Icons.credit_card_outlined,
                color: theme.colorScheme.primary,
              ),
              title: const Text(
                'Gerenciar Cartões',
                style: TextStyle(fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(context);
                if (rotaAtual != 'GerenciarCartoesPage') {
                  Navigator.pushReplacement(
                    context,
                    _criarRotaNativa(
                      GerenciarCartoesPage(onAtualizado: onCartoesAtualizados),
                      'GerenciarCartoesPage',
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
