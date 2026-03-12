import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message_model.dart';
import 'supabase_service.dart';

class MessageService {
  final SupabaseService _supabase = SupabaseService();
  final String _messagesTable = 'messages';
  final String _conversationsTable = 'conversations';

  Future<InboxSummary> getInboxSummary() async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase.client
        .from('inbox_summary')
        .select()
        .eq('user_id', userId)
        .single();

    return InboxSummary.fromJson(response);
  }

  Future<List<ConversationModel>> getConversations({
    int limit = 20,
    int offset = 0,
  }) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase.client
        .from('conversations_view')
        .select()
        .or('participant1_id.eq.$userId,participant2_id.eq.$userId')
        .eq('is_archived', false)
        .order('updated_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((conv) => ConversationModel.fromJson(conv))
        .toList();
  }

  Future<ConversationModel?> getConversation(String conversationId) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase.client
        .from('conversations_view')
        .select()
        .eq('id', conversationId)
        .or('participant1_id.eq.$userId,participant2_id.eq.$userId')
        .single();

    return ConversationModel.fromJson(response);
  }

  Future<ConversationModel?> getOrCreateConversation(String otherUserId) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final existing = await _supabase.client
        .from(_conversationsTable)
        .select()
        .or('and(participant1_id.eq.$userId,participant2_id.eq.$otherUserId),and(participant1_id.eq.$otherUserId,participant2_id.eq.$userId)')
        .maybeSingle();

    if (existing != null) {
      return getConversation(existing['id']);
    }

    final response = await _supabase.client
        .from(_conversationsTable)
        .insert({
          'participant1_id': userId,
          'participant2_id': otherUserId,
        })
        .select()
        .single();

    return getConversation(response['id']);
  }

  Future<List<MessageModel>> getMessages({
    required String conversationId,
    int limit = 50,
    int? beforeMessageId,
  }) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    PostgrestFilterBuilder query = _supabase.client
        .from(_messagesTable)
        .select()
        .eq('conversation_id', conversationId);

    if (beforeMessageId != null) {
      query = query.lt('id', beforeMessageId);
    }

    final response = await query
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((msg) => MessageModel.fromJson(msg))
        .toList()
        .reversed
        .toList();
  }

  Future<MessageModel> sendMessage({
    required String conversationId,
    required String content,
    String? replyToMessageId,
  }) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final user = await _supabase.client
        .from('users')
        .select('username, avatar_url')
        .eq('id', userId)
        .single();

    String? replyContent;
    if (replyToMessageId != null) {
      final replyMsg = await _supabase.client
          .from(_messagesTable)
          .select('content')
          .eq('id', replyToMessageId)
          .single();
      replyContent = replyMsg['content'];
    }

    final response = await _supabase.client
        .from(_messagesTable)
        .insert({
          'conversation_id': conversationId,
          'sender_id': userId,
          'sender_username': user['username'],
          'sender_avatar_url': user['avatar_url'],
          'content': content,
          'reply_to_message_id': replyToMessageId,
          'reply_to_content': replyContent,
        })
        .select()
        .single();

    await _supabase.client.rpc('update_conversation_timestamp', params: {
      'conv_id': conversationId,
    });

    return MessageModel.fromJson(response);
  }

  Future<void> markConversationAsRead(String conversationId) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.client.rpc('mark_messages_read', params: {
      'conv_id': conversationId,
      'user_id': userId,
    });
  }

  Future<void> deleteMessage(String messageId) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.client
        .from(_messagesTable)
        .update({
          'is_deleted': true,
          'content': '[deleted]',
        })
        .eq('id', messageId)
        .eq('sender_id', userId);
  }

  Future<void> editMessage({
    required String messageId,
    required String newContent,
  }) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.client
        .from(_messagesTable)
        .update({
          'content': newContent,
          'is_edited': true,
          'edited_at': DateTime.now().toIso8601String(),
        })
        .eq('id', messageId)
        .eq('sender_id', userId);
  }

  Future<void> addReaction({
    required String messageId,
    required String emoji,
  }) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.client.rpc('add_message_reaction', params: {
      'msg_id': messageId,
      'user_id': userId,
      'emoji': emoji,
    });
  }

  Future<void> removeReaction({
    required String messageId,
    required String emoji,
  }) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.client.rpc('remove_message_reaction', params: {
      'msg_id': messageId,
      'user_id': userId,
      'emoji': emoji,
    });
  }

  Future<void> toggleArchiveConversation(
    String conversationId,
    bool isArchived,
  ) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.client
        .from(_conversationsTable)
        .update({'is_archived': isArchived})
        .eq('id', conversationId)
        .or('participant1_id.eq.$userId,participant2_id.eq.$userId');
  }

  Future<void> toggleMuteConversation(
    String conversationId,
    bool isMuted,
  ) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.client
        .from(_conversationsTable)
        .update({'is_muted': isMuted})
        .eq('id', conversationId)
        .or('participant1_id.eq.$userId,participant2_id.eq.$userId');
  }

  Future<void> deleteConversation(String conversationId) async {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final conversation = await _supabase.client
        .from(_conversationsTable)
        .select('participant1_id, participant2_id')
        .eq('id', conversationId)
        .single();

    final isParticipant1 = conversation['participant1_id'] == userId;
    final updateField = isParticipant1 ? 'participant1_deleted' : 'participant2_deleted';

    await _supabase.client
        .from(_conversationsTable)
        .update({updateField: true})
        .eq('id', conversationId);
  }

  Stream<List<MessageModel>> subscribeToMessages(String conversationId) {
    return _supabase.client
        .from(_messagesTable)
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .map((data) => data
            .map((msg) => MessageModel.fromJson(msg))
            .toList());
  }

  Stream<List<ConversationModel>> subscribeToConversations() {
    final userId = _supabase.currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    return _supabase.client
        .from('conversations_view')
        .stream(primaryKey: ['id'])
        .order('updated_at', ascending: false)
        .map((data) => data
            .where((conv) => conv['participant1_id'] == userId || conv['participant2_id'] == userId)
            .map((conv) => ConversationModel.fromJson(conv))
            .toList());
  }
}
