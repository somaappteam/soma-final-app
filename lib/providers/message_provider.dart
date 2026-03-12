import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/message_service.dart';

class MessageProvider extends ChangeNotifier {
  final MessageService _service = MessageService();

  InboxSummary? _inboxSummary;
  List<ConversationModel> _conversations = [];
  ConversationModel? _currentConversation;
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  String? _error;

  InboxSummary? get inboxSummary => _inboxSummary;
  List<ConversationModel> get conversations => _conversations;
  ConversationModel? get currentConversation => _currentConversation;
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _inboxSummary?.totalUnread ?? 0;

  Future<void> loadInboxSummary() async {
    try {
      _inboxSummary = await _service.getInboxSummary();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadConversations() async {
    try {
      _isLoading = true;
      notifyListeners();

      _conversations = await _service.getConversations();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMessages(String conversationId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _messages = await _service.getMessages(conversationId: conversationId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startConversation(String otherUserId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _currentConversation = await _service.getOrCreateConversation(otherUserId);
      if (_currentConversation != null) {
        await loadMessages(_currentConversation!.id);
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage({
    required String content,
    String? replyToMessageId,
  }) async {
    if (_currentConversation == null) return;

    try {
      final message = await _service.sendMessage(
        conversationId: _currentConversation!.id,
        content: content,
        replyToMessageId: replyToMessageId,
      );

      _messages.add(message);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAsRead(String conversationId) async {
    try {
      await _service.markConversationAsRead(conversationId);
      await loadInboxSummary();
      await loadConversations();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _service.deleteMessage(messageId);
      _messages.removeWhere((m) => m.id == messageId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> editMessage({
    required String messageId,
    required String newContent,
  }) async {
    try {
      await _service.editMessage(
        messageId: messageId,
        newContent: newContent,
      );

      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        _messages[index] = MessageModel(
          id: _messages[index].id,
          senderId: _messages[index].senderId,
          senderUsername: _messages[index].senderUsername,
          senderAvatarUrl: _messages[index].senderAvatarUrl,
          receiverId: _messages[index].receiverId,
          content: newContent,
          createdAt: _messages[index].createdAt,
          isRead: _messages[index].isRead,
          isEdited: true,
          editedAt: DateTime.now(),
          replyToMessageId: _messages[index].replyToMessageId,
          replyToContent: _messages[index].replyToContent,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> archiveConversation(String conversationId, bool archive) async {
    try {
      await _service.toggleArchiveConversation(conversationId, archive);
      await loadConversations();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> muteConversation(String conversationId, bool mute) async {
    try {
      await _service.toggleMuteConversation(conversationId, mute);
      await loadConversations();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void setCurrentConversation(ConversationModel conversation) {
    _currentConversation = conversation;
    notifyListeners();
  }

  void clearCurrentConversation() {
    _currentConversation = null;
    _messages = [];
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
