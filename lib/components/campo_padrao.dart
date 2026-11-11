import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fatora/main.dart';

List<BoxShadow> sombraSutil(bool isDark) => [
  BoxShadow(
    color: isDark
        ? Colors.black.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.04),
    blurRadius: 10,
    offset: const Offset(0, 4),
  ),
  BoxShadow(
    color: isDark
        ? Colors.white.withValues(alpha: 0.02)
        : Colors.white.withValues(alpha: 0.4),
    blurRadius: 1,
    offset: const Offset(0, -1),
  ),
];

/// Snackbar padrão do app (usa o messengerKey do main.dart).
void mostrarAviso(
  BuildContext context,
  String mensagem, {
  IconData? icone,
  String? acaoLabel,
  VoidCallback? aoAcionar,
  Duration duracao = const Duration(seconds: 2),
}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final corTexto = isDark ? const Color(0xFF1D1D1F) : Colors.white;
  final messenger = messengerKey.currentState;
  messenger?.clearSnackBars();
  messenger?.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: theme.colorScheme.primary,
      duration: duracao,
      content: Row(
        children: [
          if (icone != null) ...[
            Icon(icone, color: corTexto, size: 22),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              mensagem,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: corTexto,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
      action: acaoLabel == null
          ? null
          : SnackBarAction(
              label: acaoLabel,
              textColor: isDark ? Colors.blue.shade400 : Colors.blue.shade300,
              onPressed: aoAcionar ?? () {},
            ),
    ),
  );
}

class TituloCampo extends StatelessWidget {
  final String texto;
  const TituloCampo(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: -0.3,
      ),
    );
  }
}

class CampoPadrao extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final String? prefixo;
  final TextInputType? teclado;
  final List<TextInputFormatter>? formatadores;
  final TextCapitalization capitalizacao;
  final String? Function(String?)? validador;

  const CampoPadrao({
    super.key,
    required this.controller,
    required this.hint,
    this.focusNode,
    this.prefixo,
    this.teclado,
    this.formatadores,
    this.capitalizacao = TextCapitalization.none,
    this.validador,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: sombraSutil(isDark),
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: teclado,
        inputFormatters: formatadores,
        textCapitalization: capitalizacao,
        style: TextStyle(color: theme.colorScheme.primary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: theme.colorScheme.secondary.withValues(alpha: 0.6),
          ),
          prefixText: prefixo,
          prefixStyle: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: theme.colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? Colors.white10 : Colors.black12,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 1.5,
            ),
          ),
        ),
        validator: validador,
      ),
    );
  }
}

/// Switch com o efeito de "apertar" que você já usava.
class SwitchPadrao extends StatefulWidget {
  final bool valor;
  final ValueChanged<bool> onChanged;
  const SwitchPadrao({super.key, required this.valor, required this.onChanged});

  @override
  State<SwitchPadrao> createState() => _SwitchPadraoState();
}

class _SwitchPadraoState extends State<SwitchPadrao> {
  double _escala = 1.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTapDown: (_) => setState(() => _escala = 0.92),
      onTapUp: (_) => setState(() => _escala = 1.0),
      onTapCancel: () => setState(() => _escala = 1.0),
      child: AnimatedScale(
        scale: _escala,
        duration: const Duration(milliseconds: 100),
        child: Switch(
          activeThumbColor: isDark ? const Color(0xFF000000) : Colors.white,
          activeTrackColor: isDark ? Colors.white : const Color(0xFF1D1D1F),
          inactiveThumbColor: isDark
              ? Colors.grey.shade600
              : Colors.grey.shade400,
          inactiveTrackColor: isDark ? Colors.white10 : Colors.black12,
          value: widget.valor,
          onChanged: (v) {
            HapticFeedback.lightImpact();
            widget.onChanged(v);
          },
        ),
      ),
    );
  }
}

class CartaoPadrao extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const CartaoPadrao({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: sombraSutil(isDark),
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isDark ? Colors.white10 : Colors.black12,
            width: 1,
          ),
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
