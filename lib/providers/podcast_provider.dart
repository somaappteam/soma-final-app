import 'package:flutter/foundation.dart';
import '../models/study_models.dart';
import '../services/podcast_service.dart';

class PodcastProvider with ChangeNotifier {
  final PodcastService _service = PodcastService();
  
  List<Podcast> _podcasts = [];
  List<Podcast> get podcasts => _podcasts;
  
  Podcast? _currentPodcast;
  Podcast? get currentPodcast => _currentPodcast;
  
  UserPodcastProgress? _currentProgress;
  UserPodcastProgress? get currentProgress => _currentProgress;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadPodcasts() async {
    _isLoading = true;
    notifyListeners();
    
    _podcasts = await _service.getAllPodcasts();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> selectPodcast(String userId, Podcast podcast) async {
    _currentPodcast = podcast;
    _isLoading = true;
    notifyListeners();
    
    _currentProgress = await _service.getUserProgress(userId, podcast.id);
    
    // If no progress exists, create a new one
    _currentProgress ??= UserPodcastProgress(
        userId: userId,
        podcastId: podcast.id,
        startedAt: DateTime.now(),
      );
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updatePlaybackPosition(int seconds, {bool isCompleted = false}) async {
    if (_currentProgress == null) return;
    
    final updatedProgress = UserPodcastProgress(
      userId: _currentProgress!.userId,
      podcastId: _currentProgress!.podcastId,
      currentPositionSeconds: seconds,
      isCompleted: isCompleted || _currentProgress!.isCompleted,
      startedAt: _currentProgress!.startedAt,
      completedAt: isCompleted ? DateTime.now() : _currentProgress!.completedAt,
      totalListeningTimeSeconds: _currentProgress!.totalListeningTimeSeconds + 1, // Simple approximation
    );
    
    _currentProgress = updatedProgress;
    await _service.updateProgress(updatedProgress);
    notifyListeners();
  }
}
