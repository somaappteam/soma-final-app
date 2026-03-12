import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  NotificationCount? _notificationCount;
  List<NotificationModel> _notifications = [];
  NotificationPreferences? _preferences;
  bool _isLoading = false;
  String? _error;

  NotificationCount? get notificationCount => _notificationCount;
  List<NotificationModel> get notifications => _notifications;
  NotificationPreferences? get preferences => _preferences;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _notificationCount?.unread ?? 0;

  Future<void> loadNotificationCount() async {
    try {
      _notificationCount = await _service.getNotificationCount();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadNotifications({bool unreadOnly = false}) async {
    try {
      _isLoading = true;
      notifyListeners();

      _notifications = await _service.getNotifications(unreadOnly: unreadOnly);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPreferences() async {
    try {
      _preferences = await _service.getPreferences();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updatePreferences(NotificationPreferences preferences) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _service.updatePreferences(preferences);
      _preferences = preferences;

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _service.markAsRead(notificationId);
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          userId: _notifications[index].userId,
          type: _notifications[index].type,
          title: _notifications[index].title,
          body: _notifications[index].body,
          createdAt: _notifications[index].createdAt,
          isRead: true,
          readAt: DateTime.now(),
          isArchived: _notifications[index].isArchived,
          data: _notifications[index].data,
          imageUrl: _notifications[index].imageUrl,
          actionUrl: _notifications[index].actionUrl,
          senderId: _notifications[index].senderId,
          senderName: _notifications[index].senderName,
          senderAvatarUrl: _notifications[index].senderAvatarUrl,
        );
        await loadNotificationCount();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _service.markAllAsRead();
      await loadNotifications();
      await loadNotificationCount();

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> archiveNotification(String notificationId) async {
    try {
      await _service.archiveNotification(notificationId);
      _notifications.removeWhere((n) => n.id == notificationId);
      await loadNotificationCount();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _service.deleteNotification(notificationId);
      _notifications.removeWhere((n) => n.id == notificationId);
      await loadNotificationCount();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> sendTestNotification() async {
    try {
      await _service.sendTestNotification();
      await loadNotifications();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
