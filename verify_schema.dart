import 'dart:io';
import 'dart:convert';
import 'package:supabase/supabase.dart';

void main() async {
  const url = 'https://imyjjyhrqhgyvgpiccbv.supabase.co';
  const key = '';

  final client = SupabaseClient(url, key);
  Map<String, dynamic> results = {};

  try {
    try {
      await client.from('messages_enhanced').select().limit(1);
      results['messages_enhanced'] = '✅ Exists';
    } catch (e) {
      results['messages_enhanced'] = '❌ Missing or inaccessible: $e';
    }

    try {
      await client.from('message_reactions_view').select().limit(1);
      results['message_reactions_view'] = '✅ Exists';
    } catch (e) {
      results['message_reactions_view'] = '❌ Missing or inaccessible: $e';
    }

    try {
      await client.from('conversations_with_status').select().limit(1);
      results['conversations_with_status'] = '✅ Exists';
    } catch (e) {
      results['conversations_with_status'] = '❌ Missing or inaccessible: $e';
    }

    try {
      await client
          .from('conversations_view')
          .select('is_pinned, pinned_at')
          .limit(1);
      results['conversations_view'] = '✅ Pinned columns exist';
    } catch (e) {
      results['conversations_view'] = '❌ Missing pinned columns: $e';
    }

    try {
      await client.rpc('auto_balance_teams',
          params: {'p_game_id': '00000000-0000-0000-0000-000000000000'});
      results['rpc_auto_balance_teams'] = '✅ Exists (call worked)';
    } catch (e) {
      if (e.toString().contains('Could not find the function')) {
        results['rpc_auto_balance_teams'] = '❌ Missing';
      } else {
        results['rpc_auto_balance_teams'] =
            '✅ Exists (called, expected failure)';
      }
    }

    try {
      await client.rpc('unsend_message', params: {
        'p_message_id': '00000000-0000-0000-0000-000000000000',
        'p_user_id': '00000000-0000-0000-0000-000000000000'
      });
      results['rpc_unsend_message'] = '✅ Exists (call worked)';
    } catch (e) {
      if (e.toString().contains('Could not find the function')) {
        results['rpc_unsend_message'] = '❌ Missing';
      } else {
        results['rpc_unsend_message'] = '✅ Exists (called, expected failure)';
      }
    }

    try {
      await client.rpc('get_message_reactions',
          params: {'p_message_id': '00000000-0000-0000-0000-000000000000'});
      results['rpc_get_message_reactions'] = '✅ Exists (call worked)';
    } catch (e) {
      if (e.toString().contains('Could not find the function')) {
        results['rpc_get_message_reactions'] = '❌ Missing';
      } else {
        results['rpc_get_message_reactions'] =
            '✅ Exists (called, expected failure)';
      }
    }
  } catch (e) {
    results['global_error'] = e.toString();
  }

  File('verify_results.json').writeAsStringSync(jsonEncode(results));
  exit(0);
}
