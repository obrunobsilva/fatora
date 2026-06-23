import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SeletorCartao extends StatelessWidget {
  final String cartaoSelecionado;
  final List<String> listaCartoes;
  final Function(String) onSelected;

  const SeletorCartao({
    super.key,
    required this.cartaoSelecionado,
    required this.listaCartoes,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<BoxShadow> profundidadeCartao = [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.5)
            : Colors.black.withValues(alpha: 0.04),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecione o cartão',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 10),
        ...listaCartoes.map((nomeCartao) {
          final bool estaSelecionado = cartaoSelecionado == nomeCartao;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: profundidadeCartao,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  HapticFeedback.lightImpact();
                  onSelected(nomeCartao);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: estaSelecionado
                        ? (isDark
                              ? const Color(0xFF3A3A3C)
                              : theme.colorScheme.primary)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: estaSelecionado
                          ? (isDark
                                ? Colors.white24
                                : theme.colorScheme.primary)
                          : (isDark ? Colors.white10 : Colors.black12),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.credit_card_rounded,
                        color: estaSelecionado
                            ? Colors.white
                            : theme.colorScheme.secondary,
                        size: 22,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          nomeCartao,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: estaSelecionado
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: estaSelecionado
                                ? Colors.white
                                : theme.colorScheme.primary,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      if (estaSelecionado)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
