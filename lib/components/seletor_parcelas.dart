import 'package:flutter/material.dart';

class SeletorParcelas extends StatelessWidget {
  final int parcelas;
  final Function(int) onChanged;

  const SeletorParcelas({
    super.key,
    required this.parcelas,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              'Total parcelas:',
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
                  onPressed: parcelas > 1
                      ? () => onChanged(parcelas - 1)
                      : null,
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    size: 30,
                    color: Color(0xFFEF5350),
                  ), // Vermelho nítido
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  constraints: const BoxConstraints(minWidth: 50),
                  child: Text(
                    parcelas == 1 ? 'À Vista' : '$parcelas x',
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
                  onPressed: () => onChanged(parcelas + 1),
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
