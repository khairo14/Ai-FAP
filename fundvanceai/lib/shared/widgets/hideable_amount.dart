import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fundvanceai/features/settings/settings_provider.dart';

/// Displays [amount] text (e.g. "1,234.56") but replaces it with "••••••"
/// when [SettingsProvider.hideBalances] is true.
///
/// Tap anywhere on the widget to temporarily reveal the amount for 3 seconds.
class HideableAmount extends StatefulWidget {
  final String amount;
  final TextStyle? style;

  const HideableAmount({
    super.key,
    required this.amount,
    this.style,
  });

  @override
  State<HideableAmount> createState() => _HideableAmountState();
}

class _HideableAmountState extends State<HideableAmount> {
  bool _revealed = false;

  void _peek() {
    setState(() => _revealed = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _revealed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hide = context.watch<SettingsProvider>().hideBalances;

    if (!hide) {
      return Text(widget.amount, style: widget.style);
    }

    return GestureDetector(
      onTap: _peek,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Text(
          _revealed ? widget.amount : '••••••',
          key: ValueKey(_revealed),
          style: widget.style,
        ),
      ),
    );
  }
}
