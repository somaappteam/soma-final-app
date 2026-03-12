import 'package:flutter/material.dart';
import '../models/friend_model.dart';
import '../services/friend_service.dart';

class FriendProvider extends ChangeNotifier {
  final FriendService _service = FriendService();

  List<FriendModel> _friends = [];
  List<FriendModel> _favoriteFriends = [];
  List<FriendRequest> _pendingRequests = [];
  List<FriendRequest> _sentRequests = [];
  List<BlockedUser> _blockedUsers = [];
  bool _isLoading = false;
  String? _error;

  List<FriendModel> get friends => _friends;
  List<FriendModel> get favoriteFriends => _favoriteFriends;
  List<FriendRequest> get pendingRequests => _pendingRequests;
  List<FriendRequest> get sentRequests => _sentRequests;
  List<BlockedUser> get blockedUsers => _blockedUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get pendingRequestsCount => _pendingRequests.length;

  Future<void> loadFriends() async {
    try {
      _isLoading = true;
      notifyListeners();

      _friends = await _service.getFriends();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFavoriteFriends() async {
    try {
      _favoriteFriends = await _service.getFavoriteFriends();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadPendingRequests() async {
    try {
      _pendingRequests = await _service.getPendingRequests();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadSentRequests() async {
    try {
      _sentRequests = await _service.getSentRequests();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadBlockedUsers() async {
    try {
      _blockedUsers = await _service.getBlockedUsers();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> sendFriendRequest({
    required String receiverId,
    String? message,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _service.sendFriendRequest(
        receiverId: receiverId,
        message: message,
      );

      await loadSentRequests();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> acceptFriendRequest(String requestId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _service.acceptFriendRequest(requestId);
      await loadPendingRequests();
      await loadFriends();

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> rejectFriendRequest(String requestId) async {
    try {
      await _service.rejectFriendRequest(requestId);
      await loadPendingRequests();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> cancelFriendRequest(String requestId) async {
    try {
      await _service.cancelFriendRequest(requestId);
      await loadSentRequests();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> removeFriend(String friendId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _service.removeFriend(friendId);
      await loadFriends();
      await loadFavoriteFriends();

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(String friendId, bool isFavorite) async {
    try {
      await _service.toggleFavorite(friendId, isFavorite);
      await loadFriends();
      await loadFavoriteFriends();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleMute(String friendId, bool isMuted) async {
    try {
      await _service.toggleMute(friendId, isMuted);
      await loadFriends();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> blockUser({
    required String blockedId,
    String? reason,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _service.blockUser(blockedId: blockedId, reason: reason);
      await loadBlockedUsers();
      await loadFriends();

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> unblockUser(String blockedId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _service.unblockUser(blockedId);
      await loadBlockedUsers();

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
