import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fundvanceai/features/connectivity/connectivity_provider.dart';
import 'package:fundvanceai/shared/services/local_database.dart';

/// A banner that shows at the top of a screen when the device is offline.
///
/// Usage — wrap your scaffold body (or the whole Scaffold):
/// ```dart
/// Column(children: [
///   const OfflineBanner(),
///   Expanded(child: yourContent),
/// ])
/// ```
class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _heightFactor;
  int _pendingOps = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _heightFactor = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _refreshPendingCount() async {
    final count = await LocalDatabase.instance.pendingOpsCount();
    if (mounted) setState(() => _pendingOps = count);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, provider, _) {
        if (provider.isOffline) {
          _refreshPendingCount();
          _ctrl.forward();
        } else {
          _ctrl.reverse();
        }

        return SizeTransition(
          sizeFactor: _heightFactor,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.errorContainer,
              child: Row(
                children: [
                  Icon(
                    Icons.wifi_off_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _pendingOps > 0
                          ? 'You\'re offline · $_pendingOps change${_pendingOps == 1 ? '' : 's'} pending sync'
                          : 'You\'re offline · Changes will sync when reconnected',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
