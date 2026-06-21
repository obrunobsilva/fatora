import 'package:flutter/material.dart';

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
    return Column(
      children: listaCartoes.map((nomeCartao) {
        final bool estaSelecionado = cartaoSelecionado == nomeCartao;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: GestureDetector(
            onTap: () => onSelected(nomeCartao),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: estaSelecionado
                    ? Colors.blue.shade700
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: estaSelecionado
                      ? Colors.blue.shade900
                      : Colors.grey.shade400,
                  width: estaSelecionado ? 2.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.credit_card,
                    color: estaSelecionado
                        ? Colors.white
                        : Colors.blue.shade700,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      nomeCartao,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: estaSelecionado ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  if (estaSelecionado)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 24,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
