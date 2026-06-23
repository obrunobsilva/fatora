import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SeletorParcelaAtual extends StatefulWidget {
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
  State<SeletorParcelaAtual> createState() => _SeletorParcelaAtualState();
}

class _SeletorParcelaAtualState extends State<SeletorParcelaAtual> {
  double _escalaMenos = 1.0;
  double _escalaMais = 1.0;

  @override
  Widget build(BuildContext context) {
    if (widget.totalParcelas <= 1) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              'Começar da parcela',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
                letterSpacing: -0.3,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTapDown: (_) => widget.parcelaAtual > 1
                      ? setState(() => _escalaMenos = 0.85)
                      : null,
                  onTapUp: (_) => setState(() => _escalaMenos = 1.0),
                  onTapCancel: () => setState(() => _escalaMenos = 1.0),
                  child: AnimatedScale(
                    scale: _escalaMenos,
                    duration: const Duration(milliseconds: 80),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20,
                      onPressed: widget.parcelaAtual > 1
                          ? () {
                              HapticFeedback.lightImpact();
                              widget.onChanged(widget.parcelaAtual - 1);
                            }
                          : null,
                      icon: Icon(
                        Icons.remove_circle_outline_rounded,
                        size: 24,
                        color: widget.parcelaAtual > 1
                            ? theme.colorScheme.primary
                            : theme.colorScheme.secondary.withValues(
                                alpha: 0.3,
                              ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    '${widget.parcelaAtual}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                GestureDetector(
                  onTapDown: (_) => widget.parcelaAtual < widget.totalParcelas
                      ? setState(() => _escalaMais = 0.85)
                      : null,
                  onTapUp: (_) => setState(() => _escalaMais = 1.0),
                  onTapCancel: () => setState(() => _escalaMais = 1.0),
                  child: AnimatedScale(
                    scale: _escalaMais,
                    duration: const Duration(milliseconds: 80),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20,
                      onPressed: widget.parcelaAtual < widget.totalParcelas
                          ? () {
                              HapticFeedback.lightImpact();
                              widget.onChanged(widget.parcelaAtual + 1);
                            }
                          : null,
                      icon: Icon(
                        Icons.add_circle_outline_rounded,
                        size: 24,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
