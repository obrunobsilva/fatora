import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SeletorParcelas extends StatefulWidget {
  final int parcelas;
  final Function(int) onChanged;
  const SeletorParcelas({
    super.key,
    required this.parcelas,
    required this.onChanged,
  });

  @override
  State<SeletorParcelas> createState() => _SeletorParcelasState();
}

class _SeletorParcelasState extends State<SeletorParcelas> {
  double _escalaMenos = 1.0;
  double _escalaMais = 1.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
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
              'Total de parcelas',
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
                  onTapDown: (_) => widget.parcelas > 1
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
                      onPressed: widget.parcelas > 1
                          ? () {
                              HapticFeedback.lightImpact();
                              widget.onChanged(widget.parcelas - 1);
                            }
                          : null,
                      icon: Icon(
                        Icons.remove_circle_outline_rounded,
                        size: 24,
                        color: widget.parcelas > 1
                            ? theme.colorScheme.primary
                            : theme.colorScheme.secondary.withValues(
                                alpha: 0.3,
                              ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    widget.parcelas == 1 ? 'À vista' : '${widget.parcelas} x',
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
                  onTapDown: (_) => setState(() => _escalaMais = 0.85),
                  onTapUp: (_) => setState(() => _escalaMais = 1.0),
                  onTapCancel: () => setState(() => _escalaMais = 1.0),
                  child: AnimatedScale(
                    scale: _escalaMais,
                    duration: const Duration(milliseconds: 80),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        widget.onChanged(widget.parcelas + 1);
                      },
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
