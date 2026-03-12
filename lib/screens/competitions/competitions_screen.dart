import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../models/competition_model.dart';
import '../../providers/competition_provider.dart';
import '../../services/live_game_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import 'create_competition_screen.dart';
import 'game_lobby_screen.dart';

/// Premium Competitions Screen - Enhanced with matchmaking and filtering
/// Features: Quick match, game filters, search, categories, live updates
class CompetitionsScreen extends StatefulWidget {
  const CompetitionsScreen({super.key});

  @override
  State<CompetitionsScreen> createState() => _CompetitionsScreenState();
}

class _CompetitionsScreenState extends State<CompetitionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  
  // Filters
  String? _selectedLanguage;
  String? _selectedDifficulty;
  String? _selectedGameType;
  final bool _showFilters = false;
  
  // Matchmaking
  bool _isMatchmaking = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    await context.read<CompetitionProvider>().loadActiveGames();
    if (!mounted) return;
    await context.read<CompetitionProvider>().loadMyActiveGames();
    if (!mounted) return;
    await context.read<CompetitionProvider>().loadPendingInvites();
  }

  void _startQuickMatch() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isMatchmaking = true;
    });
    
    // Simulate matchmaking
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          // Timer logic removed or simplified
        });
      }
    });
  }

  void _cancelMatchmaking() {
    setState(() {
      _isMatchmaking = false;
    });
  }

  Future<void> _joinWithCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-character code')),
      );
      return;
    }
    
    HapticFeedback.mediumImpact();
    
    try {
      final gameService = LiveGameService();
      final userId = SupabaseService().currentUser?.id;
      
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to join games')),
        );
        return;
      }
      
      final gameData = await gameService.joinGame(code, userId);
      
      if (!mounted) return;
      
      if (gameData != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GameLobbyScreen(gameId: gameData['id']),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join game: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final competitionProvider = context.watch<CompetitionProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 180,
                  floating: true,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: theme.scaffoldBackgroundColor,
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildHeader(),
                  ),
                  bottom: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primaryTeal,
                    unselectedLabelColor: AppColors.textLight,
                    indicatorColor: AppColors.primaryTeal,
                    tabs: const [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.public),
                            SizedBox(width: 8),
                            Text('Public'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.videogame_asset),
                            SizedBox(width: 8),
                            Text('My Games'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history),
                            SizedBox(width: 8),
                            Text('History'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildPublicGamesTab(competitionProvider),
                _buildMyGamesTab(competitionProvider),
                _buildHistoryTab(),
              ],
            ),
          ),
          if (_isMatchmaking)
            _buildMatchmakingOverlay(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateGameDialog(context),
        backgroundColor: AppColors.primaryTeal,
        icon: const Icon(Icons.add),
        label: const Text('Create Game'),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryTeal.withValues(alpha: 0.15),
            AppColors.darkTeal.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Competitions',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Challenge players worldwide',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
              _buildQuickMatchButton(),
            ],
          ),
          const SizedBox(height: 16),
          _buildJoinCodeSection(),
        ],
      ),
    );
  }

  Widget _buildQuickMatchButton() {
    return GestureDetector(
      onTap: _startQuickMatch,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.accentCoral, AppColors.accentOrange],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentCoral.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flash_on, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Quick Match',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinCodeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              decoration: InputDecoration(
                hintText: 'Enter game code',
                prefixIcon: const Icon(Icons.vpn_key),
                counterText: '',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _joinWithCode,
            icon: const Icon(Icons.login),
            label: const Text('Join'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublicGamesTab(CompetitionProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredGames = _filterGames(provider.activeGames);

    if (filteredGames.isEmpty) {
      return _buildEmptyState(
        icon: Icons.sports_esports,
        title: 'No games available',
        subtitle: 'Create a game or try Quick Match',
        action: ElevatedButton.icon(
          onPressed: () => _showCreateGameDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Create Game'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadActiveGames(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredGames.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildFilterSection();
          }
          return _buildGameCard(filteredGames[index - 1], provider);
        },
      ),
    );
  }

  Widget _buildMyGamesTab(CompetitionProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.myActiveGames.isEmpty) {
      return _buildEmptyState(
        icon: Icons.videogame_asset_off,
        title: 'No active games',
        subtitle: 'Join a game or create your own',
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadMyActiveGames(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.myActiveGames.length,
        itemBuilder: (context, index) {
          return _buildGameCard(provider.myActiveGames[index], provider);
        },
      ),
    );
  }

  Widget _buildHistoryTab() {
    // TODO: Load game history
    return _buildEmptyState(
      icon: Icons.history,
      title: 'No game history',
      subtitle: 'Play some games to see your history',
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: AppColors.textLight.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textMedium,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _showFilters ? null : 0,
      child: _showFilters
          ? Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedLanguage = null;
                            _selectedDifficulty = null;
                            _selectedGameType = null;
                          });
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFilterDropdown(
                    label: 'Language',
                    value: _selectedLanguage,
                    items: const ['Spanish', 'French', 'German', 'Italian', 'Japanese'],
                    onChanged: (value) {
                      setState(() {
                        _selectedLanguage = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildFilterDropdown(
                    label: 'Difficulty',
                    value: _selectedDifficulty,
                    items: const ['Beginner', 'Intermediate', 'Advanced'],
                    onChanged: (value) {
                      setState(() {
                        _selectedDifficulty = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildFilterDropdown(
                    label: 'Game Type',
                    value: _selectedGameType,
                    items: const ['Word Race', 'Vocabulary Challenge', 'Translation Battle', 'Grammar Showdown'],
                    onChanged: (value) {
                      setState(() {
                        _selectedGameType = value;
                      });
                    },
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('All'),
        ),
        ...items.map((item) => DropdownMenuItem(
          value: item,
          child: Text(item),
        )),
      ],
      onChanged: onChanged,
    );
  }

  List<ActiveGame> _filterGames(List<ActiveGame> games) {
    return games.where((game) {
      if (_selectedLanguage != null && game.language != _selectedLanguage) {
        return false;
      }
      if (_selectedDifficulty != null && game.difficulty != _selectedDifficulty) {
        return false;
      }
      if (_selectedGameType != null) {
        final gameTypeMap = {
          'Word Race': 'word_race',
          'Vocabulary Challenge': 'vocabulary_challenge',
          'Translation Battle': 'translation_battle',
          'Grammar Showdown': 'grammar_showdown',
        };
        if (game.gameType != gameTypeMap[_selectedGameType]) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Widget _buildGameCard(ActiveGame game, CompetitionProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () => _joinGame(context, game.id),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: game.isPremiumOnly
                ? LinearGradient(
                    colors: [
                      Colors.amber.withValues(alpha: 0.05),
                      Colors.orange.withValues(alpha: 0.02),
                    ],
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            game.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.grey.shade300,
                                child: Text(
                                  game.hostName[0].toUpperCase(),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Host: ${game.hostName}',
                                style: const TextStyle(
                                  color: AppColors.textMedium,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (game.isPremiumOnly)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.goldGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Premium',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildGameChip(Icons.language, game.language),
                    const SizedBox(width: 8),
                    _buildGameChip(Icons.speed, game.difficulty),
                    const SizedBox(width: 8),
                    _buildGameChip(
                      Icons.people,
                      '${game.currentPlayers}/${game.maxPlayers}',
                      color: game.currentPlayers >= game.maxPlayers
                          ? Colors.red
                          : game.currentPlayers >= game.maxPlayers - 1
                              ? Colors.orange
                              : Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.emoji_events,
                            color: Colors.amber,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${game.prizeXP} XP',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: game.currentPlayers >= game.maxPlayers
                          ? null
                          : () => _joinGame(context, game.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        game.currentPlayers >= game.maxPlayers ? 'Full' : 'Join',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }

  Widget _buildGameChip(IconData icon, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? AppColors.primaryTeal).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? AppColors.primaryTeal),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color ?? AppColors.primaryTeal,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchmakingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accentCoral, AppColors.accentOrange],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentCoral.withValues(alpha: 0.5),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.flash_on,
                color: Colors.white,
                size: 60,
              ),
            )
            .animate(
              onComplete: (controller) => controller.repeat(),
            )
            .scale(duration: 1000.ms, begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
            const SizedBox(height: 32),
            const Text(
              'Finding Match...',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Searching for players',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _cancelMatchmaking,
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateGameDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateCompetitionScreen(),
    );
  }

  void _joinGame(BuildContext context, String gameId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameLobbyScreen(gameId: gameId),
      ),
    );
  }
}

