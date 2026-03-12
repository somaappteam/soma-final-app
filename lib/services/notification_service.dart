import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import 'supabase_service.dart';

class NotificationService {
  final SupabaseService _supabase = SupabaseService();
  final String _table = 'notifications';
  final String _preferencesTable = 'notification_preferences';

  Future<NotificationCount> getNotificationCount() async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase.client
        .from('notification_counts')
        .select()
        .eq('user_id', userId)
        .single();

    return NotificationCount.fromJson(response);
  }

  Future<List<NotificationModel>> getNotifications({
    bool unreadOnly = false,
    int limit = 50,
    int offset = 0,
  }) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    PostgrestFilterBuilder query = _supabase.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .eq('is_archived', false);

    if (unreadOnly) {
      query = query.eq('is_read', false);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((notification) => NotificationModel.fromJson(notification))
        .toList();
  }

  Future<List<NotificationModel>> getNotificationsByType(String type) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .eq('type', type)
        .eq('is_archived', false)
        .order('created_at', ascending: false);

    return (response as List)
        .map((notification) => NotificationModel.fromJson(notification))
        .toList();
  }

  Future<void> markAsRead(String notificationId) async {
    await _supabase.client
        .from(_table)
        .update({
          'is_read': true,
          'read_at': DateTime.now().toIso8601String(),
        })
        .eq('id', notificationId);
  }

  Future<void> markAllAsRead() async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.client.rpc('mark_all_notifications_read', params: {
      'user_id': userId,
    });
  }

  Future<void> archiveNotification(String notificationId) async {
    await _supabase.client
        .from(_table)
        .update({'is_archived': true})
        .eq('id', notificationId);
  }

  Future<void> deleteNotification(String notificationId) async {
    await _supabase.client
        .from(_table)
        .delete()
        .eq('id', notificationId);
  }

  Future<NotificationPreferences> getPreferences() async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase.client
        .from(_preferencesTable)
        .select()
        .eq('user_id', userId)
        .single();

    return NotificationPreferences.fromJson(response);
  }

  Future<void> updatePreferences(NotificationPreferences preferences) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.client
        .from(_preferencesTable)
        .update({
          ...preferences.toJson(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId);
  }

  Future<void> sendTestNotification() async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.client.rpc('create_notification', params: {
      'user_id': userId,
      'notification_type': 'test',
      'title': 'Test Notification',
      'body': 'This is a test notification from Soma!',
    });
  }

  Stream<List<NotificationModel>> subscribeToNotifications() {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    return _supabase.client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data
            .where((notification) => notification['is_archived'] == false)
            .map((notification) => NotificationModel.fromJson(notification))
            .toList());
  }

  Stream<NotificationCount> subscribeToNotificationCount() {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    return _supabase.client
        .from('notification_counts')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', userId)
        .map((data) => NotificationCount.fromJson(data.first));
  }
}
