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

  Route _criarRotaSlide(Widget pagina, String nomeRota) {
    return PageRouteBuilder(
      settings: RouteSettings(name: nomeRota),
      pageBuilder: (context, animation, secondaryAnimation) => pagina,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? rotaAtual = ModalRoute.of(context)?.settings.name;

    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF1976D2), // Lógica do azul escuro absoluto fixado
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fatora',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Menu de Opções',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add_box, size: 28),
            title: const Text(
              'Registrar Compra',
              style: TextStyle(fontSize: 18),
            ),
            onTap: () {
              Navigator.pop(context);
              if (rotaAtual != '/' && rotaAtual != 'HomePage') {
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
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.history, size: 28),
            title: const Text(
              'Histórico de Compras',
              style: TextStyle(fontSize: 18),
            ),
            onTap: () {
              Navigator.pop(context);
              if (rotaAtual != 'HistoricoPage') {
                Navigator.pushReplacement(
                  context,
                  _criarRotaSlide(
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
            leading: const Icon(Icons.analytics, size: 28),
            title: const Text(
              'Resumo das Faturas',
              style: TextStyle(fontSize: 18),
            ),
            onTap: () {
              Navigator.pop(context);
              if (rotaAtual != 'RelatorioPage') {
                Navigator.pushReplacement(
                  context,
                  _criarRotaSlide(
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
            leading: const Icon(Icons.people, size: 28),
            title: const Text(
              'Total por Pessoa',
              style: TextStyle(fontSize: 18),
            ),
            onTap: () {
              Navigator.pop(context);
              if (rotaAtual != 'ResumoPessoaPage') {
                Navigator.pushReplacement(
                  context,
                  _criarRotaSlide(
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
          const Divider(height: 1, thickness: 1),
          ListTile(
            leading: const Icon(Icons.credit_card, size: 28),
            title: const Text(
              'Gerenciar Cartões',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            onTap: () {
              Navigator.pop(context);
              if (rotaAtual != 'GerenciarCartoesPage') {
                Navigator.pushReplacement(
                  context,
                  _criarRotaSlide(
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
    );
  }
}
