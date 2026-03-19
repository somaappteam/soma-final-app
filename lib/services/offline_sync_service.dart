import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

const syncTaskName = "syncOfflineActionsTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == syncTaskName) {
        // Initialize dependencies if needed in background
        await Hive.initFlutter();
        final box = await Hive.openBox(OfflineSyncService.actionQueueBoxName);
        
        if (box.isEmpty) return Future.value(true);

        final supabase = SupabaseService();
        await supabase.initialize();
        if (!supabase.isAuthenticated) return Future.value(true);

        final List<dynamic> keysToDelete = [];

        for (final key in box.keys) {
          try {
            final actionMap = box.get(key) as Map<dynamic, dynamic>;
            final type = actionMap['type'];
            
            if (type == 'addXP') {
              final xp = actionMap['xp'] as int;
              await supabase.client.rpc('increment_xp', params: {'points': xp});
              keysToDelete.add(key);
            } 
            // Add other background sync patterns here
            
          } catch (e) {
            debugPrint("Failed to sync action $key: $e");
          }
        }

        await box.deleteAll(keysToDelete);
        debugPrint("Background Sync Executed Successfully.");
      }
      return Future.value(true);
    } catch (e) {
      debugPrint("Background Sync Failed: $e");
      return Future.value(false);
    }
  });
}

class OfflineSyncService {
  static const String actionQueueBoxName = 'offlineActionsQueue';

  static Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox(actionQueueBoxName);

    // Initialize Workmanager
    await Workmanager().initialize(
      callbackDispatcher,
    );
  }

  /// Queues an action to be synced later
  static Future<void> enqueueAction(Map<String, dynamic> actionMap) async {
    final box = Hive.box(actionQueueBoxName);
    await box.add(actionMap);
    
    // Register one-off task when device has internet
    Workmanager().registerOneOffTask(
      "sync_${DateTime.now().millisecondsSinceEpoch}",
      syncTaskName,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
}
