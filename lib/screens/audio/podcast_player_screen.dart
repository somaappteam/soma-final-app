import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/podcast_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/study_models.dart';
import '../../theme/app_theme.dart';

/// Podcast/Audio Player Screen with transcripts and learning features
class PodcastPlayerScreen extends StatefulWidget {
  final Podcast? podcast;

  const PodcastPlayerScreen({
    super.key,
    this.podcast,
  });

  @override
  State<PodcastPlayerScreen> createState() => _PodcastPlayerScreenState();
}

class _PodcastPlayerScreenState extends State<PodcastPlayerScreen> {
  bool _isPlaying = false;
  double _progress = 0.0;
  double _playbackSpeed = 1.0;
  bool _showTranscript = true;
  int _currentSegmentIndex = 0;
  bool _isFavorite = false;
  bool _isSleepTimerActive = false;
  int _sleepTimerMinutes = 0;

  // Demo transcript segments (Keep for now until real transcripts are implemented in model)
  final List<TranscriptSegment> _transcript = [
    TranscriptSegment(
      startTime: const Duration(seconds: 0),
      endTime: const Duration(seconds: 5),
      targetText: 'Bienvenidos a Spanish Learning Podcast.',
      nativeText: 'Welcome to Spanish Learning Podcast.',
    ),
    TranscriptSegment(
      startTime: const Duration(seconds: 5),
      endTime: const Duration(seconds: 12),
      targetText: 'Hoy vamos a aprender sobre comida.',
      nativeText: 'Today we are going to learn about food.',
    ),
    TranscriptSegment(
      startTime: const Duration(seconds: 12),
      endTime: const Duration(seconds: 20),
      targetText: 'La comida española es muy deliciosa.',
      nativeText: 'Spanish food is very delicious.',
      keywords: ['comida', 'deliciosa'],
    ),
    TranscriptSegment(
      startTime: const Duration(seconds: 20),
      endTime: const Duration(seconds: 30),
      targetText: 'Me gusta mucho la paella y las tapas.',
      nativeText: 'I really like paella and tapas.',
      keywords: ['paella', 'tapas'],
    ),
    TranscriptSegment(
      startTime: const Duration(seconds: 30),
      endTime: const Duration(seconds: 45),
      targetText: '¿Cuál es tu comida favorita?',
      nativeText: 'What is your favorite food?',
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final podcastProvider = context.read<PodcastProvider>();
      final userId = authProvider.currentUser?.id;

      if (widget.podcast != null && userId != null) {
        podcastProvider.selectPodcast(userId, widget.podcast!);
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  ThemeData get theme => Theme.of(context);

  @override
  Widget build(BuildContext context) {
    final podcastProvider = context.watch<PodcastProvider>();
    final podcast = podcastProvider.currentPodcast ?? widget.podcast;
    final isLoading = podcastProvider.isLoading;

    if (podcast == null && !isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text(
            'No podcast selected',
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: isLoading ? _buildLoadingState() : _buildPlayerContent(podcast!),
            ),
            _buildBottomPlayer(podcastProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.headphones, color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                Text(
                  'NOW PLAYING',
                style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: _showMoreOptions,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Loading episode...',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerContent(Podcast podcast) {
    return Column(
      children: [
        // Podcast artwork
        Container(
          width: 280,
          height: 280,
          margin: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: podcast.coverImageUrl != null
                ? Image.network(
                    podcast.coverImageUrl!,
                    fit: BoxFit.cover,
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [theme.colorScheme.primary, theme.colorScheme.primaryContainer],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.podcasts,
                        size: 100,
                        color: Colors.white,
                      ),
                    ),
                  ),
          ),
        ),
        
        // Episode info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              Text(
                podcast.title,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                podcast.description ?? 'Language Podcast',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        
        // Transcript toggle
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text('Transcript'),
                selected: _showTranscript,
                onSelected: (selected) => setState(() => _showTranscript = selected),
                selectedColor: Colors.white.withValues(alpha: 0.1),
                backgroundColor: Colors.transparent,
                labelStyle: TextStyle(
                  color: _showTranscript ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Notes'),
                selected: !_showTranscript,
                onSelected: (selected) => setState(() => _showTranscript = !selected),
                selectedColor: Colors.white.withValues(alpha: 0.1),
                backgroundColor: Colors.transparent,
                labelStyle: TextStyle(
                  color: !_showTranscript ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        
        // Transcript
        if (_showTranscript)
          Expanded(
            child: _buildTranscript(),
          ),
      ],
    );
  }

  Widget _buildTranscript() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _transcript.length,
        itemBuilder: (context, index) {
          final segment = _transcript[index];
          final isActive = index == _currentSegmentIndex;
          
          return GestureDetector(
            onTap: () {
              setState(() => _currentSegmentIndex = index);
              HapticFeedback.lightImpact();
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isActive 
                    ? Colors.white.withValues(alpha: 0.1) 
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isActive
                    ? Border.all(color: Colors.white.withValues(alpha: 0.1))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _formatDuration(segment.startTime),
                        style: TextStyle(
                          color: isActive ? AppColors.accentOrange : Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.accentOrange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    segment.targetText,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white70,
                      fontSize: 16,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    segment.nativeText,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  if (segment.keywords != null) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: segment.keywords!.map((keyword) {
                        return GestureDetector(
                          onTap: () => _showWordDefinition(keyword),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentOrange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              keyword,
                              style: const TextStyle(
                                color: AppColors.accentOrange,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomPlayer(PodcastProvider podcastProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Progress bar
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white24,
                thumbColor: Colors.white,
                overlayColor: Colors.white.withValues(alpha: 0.1),
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: _progress,
                onChanged: (value) => setState(() => _progress = value),
              ),
            ),
            
            // Time labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '04:32',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.1),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '12:45',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.1),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Speed button
                GestureDetector(
                  onTap: _showSpeedOptions,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_playbackSpeed}x',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                // Rewind
                IconButton(
                  icon: const Icon(Icons.replay_10, color: Colors.white, size: 32),
                  onPressed: () {
                    final newPos = (_progress * (podcastProvider.currentPodcast?.durationSeconds ?? 0)).toInt() - 10;
                    podcastProvider.updatePlaybackPosition(newPos < 0 ? 0 : newPos);
                  },
                ),
                
                // Play/Pause
                GestureDetector(
                  onTap: () {
                    setState(() => _isPlaying = !_isPlaying);
                    if (!_isPlaying) {
                       // Save progress when pausing
                       final currentPos = (_progress * (podcastProvider.currentPodcast?.durationSeconds ?? 0)).toInt();
                       podcastProvider.updatePlaybackPosition(currentPos);
                    }
                  },
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [theme.colorScheme.primary, theme.colorScheme.primaryContainer],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                
                // Forward
                IconButton(
                  icon: const Icon(Icons.forward_10, color: Colors.white, size: 32),
                  onPressed: () {
                    final duration = podcastProvider.currentPodcast?.durationSeconds ?? 0;
                    final newPos = (_progress * duration).toInt() + 10;
                    podcastProvider.updatePlaybackPosition(newPos > duration ? duration : newPos);
                  },
                ),
                
                // Sleep timer
                GestureDetector(
                  onTap: _showSleepTimer,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isSleepTimerActive
                          ? AppColors.accentOrange.withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.bedtime,
                      color: _isSleepTimerActive ? AppColors.accentOrange : Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreOptions() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? AppColors.error : Colors.white,
              ),
              title: const Text(
                'Add to Favorites',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                setState(() => _isFavorite = !_isFavorite);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.download, color: Colors.white),
              title: const Text(
                'Download Episode',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.white),
              title: const Text(
                'Share Episode',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add, color: Colors.white),
              title: const Text(
                'Add to Playlist',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showSpeedOptions() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Playback Speed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...[0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
              return ListTile(
                title: Text(
                  '${speed}x',
                  style: TextStyle(
                    color: _playbackSpeed == speed ? AppColors.accentOrange : Colors.white,
                    fontWeight: _playbackSpeed == speed 
                        ? FontWeight.bold 
                        : FontWeight.normal,
                  ),
                ),
                trailing: _playbackSpeed == speed
                    ? const Icon(Icons.check, color: AppColors.accentOrange)
                    : null,
                onTap: () {
                  setState(() => _playbackSpeed = speed);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showSleepTimer() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Sleep Timer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...[5, 10, 15, 30, 45, 60].map((minutes) {
              return ListTile(
                title: Text(
                  '$minutes minutes',
                  style: TextStyle(
                    color: _sleepTimerMinutes == minutes 
                        ? AppColors.accentOrange 
                        : Colors.white,
                  ),
                ),
                trailing: _sleepTimerMinutes == minutes
                    ? const Icon(Icons.check, color: AppColors.accentOrange)
                    : null,
                onTap: () {
                  setState(() {
                    _sleepTimerMinutes = minutes;
                    _isSleepTimerActive = true;
                  });
                  Navigator.pop(context);
                },
              );
            }),
            ListTile(
              title: const Text(
                'Off',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                setState(() {
                  _sleepTimerMinutes = 0;
                  _isSleepTimerActive = false;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showWordDefinition(String word) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                word,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Noun',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.1),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Definition',
                      style: TextStyle(
                        color: AppColors.accentOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'A traditional Spanish rice dish from Valencia, typically made with saffron, vegetables, and various meats or seafood.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.volume_up),
                      label: const Text('Listen'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add),
                      label: const Text('Add Word'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentOrange,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TranscriptSegment {
  final Duration startTime;
  final Duration endTime;
  final String targetText;
  final String nativeText;
  final List<String>? keywords;

  TranscriptSegment({
    required this.startTime,
    required this.endTime,
    required this.targetText,
    required this.nativeText,
    this.keywords,
  });
}

