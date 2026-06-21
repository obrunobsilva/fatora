import 'package:flutter/material.dart';

class SeletorParcelaAtual extends StatelessWidget {
  final int parcelaAtual;
  final int totalParcelas;
  final Function(int) onChanged;

  const SeletorParcelaAtual({
    super.key,
    required this.parcelaAtual,
    required this.totalParcelas,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (totalParcelas <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1976D2), // Fundo azul escuro padrão
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: const Text(
              'Parcela atual:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 5,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: parcelaAtual > 1
                      ? () => onChanged(parcelaAtual - 1)
                      : null,
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    size: 30,
                    color: Color(0xFFEF5350),
                  ), // Vermelho nítido
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  constraints: const BoxConstraints(minWidth: 45),
                  child: Text(
                    '$parcelaAtual',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: parcelaAtual < totalParcelas
                      ? () => onChanged(parcelaAtual + 1)
                      : null,
                  icon: const Icon(
                    Icons.add_circle_outline,
                    size: 30,
                    color: Color(0xFF66BB6A),
                  ), // Verde nítido
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
