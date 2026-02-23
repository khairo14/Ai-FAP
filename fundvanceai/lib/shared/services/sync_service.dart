import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_database.dart';

/// Drains the [LocalDatabase] pending_ops queue against Supabase when the
/// device comes back online.
///
/// Each pending op has: operation (INSERT|UPDATE|DELETE), table_name,
/// record_id, and JSON payload.
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isSyncing = false;

  /// Run all queued operations against Supabase.
  /// Silently skips ops that fail after 3 attempts.
  Future<SyncResult> syncPending() async {
    if (_isSyncing) return SyncResult(synced: 0, failed: 0);
    _isSyncing = true;

    int synced = 0;
    int failed = 0;

    try {
      final ops = await LocalDatabase.instance.getPendingOps();
      if (ops.isEmpty) return SyncResult(synced: 0, failed: 0);

      debugPrint('[SyncService] Draining ${ops.length} pending operations…');

      for (final op in ops) {
        final rowId = op['id'] as int;
        final operation = op['operation'] as String;
        final tableName = op['table_name'] as String;
        final recordId = op['record_id'] as String;
        final payload =
            jsonDecode(op['payload'] as String) as Map<String, dynamic>;
        final attempts = op['attempts'] as int;

        if (attempts >= 3) {
          // Give up after 3 tries — remove to prevent queue build-up
          await LocalDatabase.instance.deletePendingOp(rowId);
          failed++;
          debugPrint('[SyncService] Giving up on op $rowId after 3 attempts');
          continue;
        }

        try {
          await _applyOp(
            operation: operation,
            tableName: tableName,
            recordId: recordId,
            payload: payload,
          );
          await LocalDatabase.instance.deletePendingOp(rowId);
          synced++;
          debugPrint(
              '[SyncService] ✅ $operation on $tableName/$recordId synced');
        } catch (e) {
          await LocalDatabase.instance.incrementAttempts(rowId);
          failed++;
          debugPrint(
              '[SyncService] ⚠️ $operation on $tableName/$recordId failed: $e');
        }
      }
    } finally {
      _isSyncing = false;
    }

    debugPrint(
        '[SyncService] Done — synced: $synced, failed: $failed');
    return SyncResult(synced: synced, failed: failed);
  }

  Future<void> _applyOp({
    required String operation,
    required String tableName,
    required String recordId,
    required Map<String, dynamic> payload,
  }) async {
    switch (operation) {
      case 'INSERT':
        await _supabase.from(tableName).upsert(payload);
        break;
      case 'UPDATE':
        await _supabase
            .from(tableName)
            .update(payload)
            .eq('id', recordId);
        break;
      case 'DELETE':
        // Soft-delete: set deleted_at
        await _supabase
            .from(tableName)
            .update({'deleted_at': DateTime.now().toIso8601String()})
            .eq('id', recordId);
        break;
    }
  }

  Future<int> pendingCount() =>
      LocalDatabase.instance.pendingOpsCount();
}

class SyncResult {
  final int synced;
  final int failed;
  const SyncResult({required this.synced, required this.failed});
}
