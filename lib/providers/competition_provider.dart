import 'package:flutter/material.dart';
import '../models/competition_model.dart';
import '../services/competition_service.dart';

class CompetitionProvider extends ChangeNotifier {
  final CompetitionService _service = CompetitionService();

  List<ActiveGame> _activeGames = [];
  List<ActiveGame> _myActiveGames = [];
  CompetitionModel? _currentCompetition;
  List<GameInvite> _pendingInvites = [];
  bool _isLoading = false;
  String? _error;

  List<ActiveGame> get activeGames => _activeGames;
  List<ActiveGame> get myActiveGames => _myActiveGames;
  CompetitionModel? get currentCompetition => _currentCompetition;
  List<GameInvite> get pendingInvites => _pendingInvites;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get pendingInvitesCount => _pendingInvites.length;

  Future<void> loadActiveGames({
    String? language,
    String? difficulty,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      _activeGames = await _service.getActiveGames(
        language: language,
        difficulty: difficulty,
      );

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMyActiveGames() async {
    try {
      _isLoading = true;
      notifyListeners();

      _myActiveGames = await _service.getMyActiveGames();

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPendingInvites() async {
    try {
      _pendingInvites = await _service.getPendingInvites();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> createCompetition({
    required String title,
    String? description,
    required String gameType,
    required String language,
    required String difficulty,
    required int maxPlayers,
    required DateTime scheduledStart,
    int durationMinutes = 30,
    bool isPrivate = false,
    bool isPremiumOnly = false,
    int entryFee = 0,
    int prizeXP = 100,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final competition = await _service.createCompetition(
        title: title,
        description: description,
        gameType: gameType,
        language: language,
        difficulty: difficulty,
        maxPlayers: maxPlayers,
        scheduledStart: scheduledStart,
        durationMinutes: durationMinutes,
        isPrivate: isPrivate,
        isPremiumOnly: isPremiumOnly,
        entryFee: entryFee,
        prizeXP: prizeXP,
      );

      _currentCompetition = competition;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> joinCompetition(String competitionId, {String? inviteCode}) async {
    try {
      _isLoading = true;
      notifyListeners();

      final competition = await _service.joinCompetition(
        competitionId,
        inviteCode: inviteCode,
      );

      _currentCompetition = competition;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> leaveCompetition(String competitionId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _service.leaveCompetition(competitionId);
      _currentCompetition = null;

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCompetitionDetails(String competitionId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _currentCompetition = await _service.getCompetitionDetails(competitionId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setPlayerReady(String competitionId, bool isReady) async {
    try {
      await _service.setPlayerReady(competitionId, isReady);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> inviteFriend({
    required String competitionId,
    required String friendId,
  }) async {
    try {
      await _service.inviteFriendToGame(
        competitionId: competitionId,
        friendId: friendId,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> respondToInvite({
    required String inviteId,
    required bool accept,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _service.respondToInvite(inviteId: inviteId, accept: accept);
      await loadPendingInvites();

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearCurrentCompetition() {
    _currentCompetition = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
