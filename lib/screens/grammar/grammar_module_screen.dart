import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../models/grammar_models.dart';
import '../../providers/course_provider.dart';
import '../../services/grammar_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ai_tutor/ai_tutor_floating_button.dart';
import 'conjugation_drill_screen.dart';
import 'sentence_structure_screen.dart';
import 'grammar_rules_screen.dart';
import 'error_correction_screen.dart';

/// Main Grammar Module Hub - High-end skill tree visualization
class GrammarModuleScreen extends StatefulWidget {
  const GrammarModuleScreen({super.key});

  @override
  State<GrammarModuleScreen> createState() => _GrammarModuleScreenState();
}

class _GrammarModuleScreenState extends State<GrammarModuleScreen>
    with TickerProviderStateMixin {
  final GrammarService _grammarService = GrammarService();
  bool _isLoading = true;
  List<GrammarSkillNode> _skillTree = [];
  UserGrammarStats? _userStats;
  String? _error;
  
  late AnimationController _treeAnimationController;
  
  // Scroll controller for skill tree
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void initState() {
    super.initState();
    _treeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _loadGrammarData();
  }

  @override
  void dispose() {
    _treeAnimationController.dispose();
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  Future<void> _loadGrammarData() async {
    try {
      final courseProvider = context.read<CourseProvider>();
      final activeCourse = courseProvider.activeCourse;
      
      if (activeCourse != null) {
        await _grammarService.initialize(
          activeCourse.courseId,
          activeCourse.targetLanguage,
          activeCourse.nativeLanguage,
        );

        final skillTree = await _grammarService.getUserSkillTree(
          activeCourse.courseId,
          'current_user_id', // TODO: Get from auth provider
        );

        setState(() {
          _skillTree = skillTree;
          _isLoading = false;
        });

        _treeAnimationController.forward();
      } else {
        setState(() {
          _error = 'Please select a course first';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading
          ? _buildLoadingScreen()
          : _error != null
              ? _buildErrorScreen()
              : _buildGrammarHub(),
      floatingActionButton: AiTutorFloatingButton(
        onPressed: () => _showAITutor(context),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
          ),
          SizedBox(height: 20),
          Text(
            'Loading Grammar Module...',
            style: TextStyle(
              color: AppColors.textMedium,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          const Text(
            'Oops!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: const TextStyle(
              color: AppColors.textMedium,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadGrammarData,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildGrammarHub() {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          _buildStatsBar(),
          _buildPracticeModesBar(),
          Expanded(
            child: _buildSkillTreeView(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667eea),
            Color(0xFF764ba2),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Grammar Mastery',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Master the rules of the language',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department, 
                      color: Colors.orange, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${_userStats?.currentStreak ?? 0}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildStatsBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.account_tree,
            value: '${_skillTree.where((s) => s.isCompleted).length}/${_skillTree.length}',
            label: 'Skills',
            color: Colors.blue,
          ),
          _buildDivider(),
          _buildStatItem(
            icon: Icons.trending_up,
            value: '${(_userStats?.overallMastery ?? 0).toInt()}%',
            label: 'Mastery',
            color: Colors.green,
          ),
          _buildDivider(),
          _buildStatItem(
            icon: Icons.emoji_events,
            value: _userStats?.masteryLevel ?? 'Novice',
            label: 'Level',
            color: Colors.amber,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 100.ms);
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.grey.shade200,
    );
  }

  Widget _buildPracticeModesBar() {
    final modes = [
      {
        'title': 'Conjugation',
        'icon': Icons.format_list_numbered,
        'color': Colors.purple,
        'screen': const ConjugationDrillScreen(),
      },
      {
        'title': 'Sentences',
        'icon': Icons.subject,
        'color': Colors.teal,
        'screen': const SentenceStructureScreen(),
      },
      {
        'title': 'Rules',
        'icon': Icons.menu_book,
        'color': Colors.orange,
        'screen': const GrammarRulesScreen(),
      },
      {
        'title': 'Fix Errors',
        'icon': Icons.edit_note,
        'color': Colors.red,
        'screen': const ErrorCorrectionScreen(),
      },
    ];

    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: modes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final mode = modes[index];
          return _buildModeCard(
            title: mode['title'] as String,
            icon: mode['icon'] as IconData,
            color: mode['color'] as Color,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => mode['screen'] as Widget),
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 700.ms, delay: 200.ms);
  }

  Widget _buildModeCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 85,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillTreeView() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Skill Tree',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showLegend(context),
                  icon: const Icon(Icons.help_outline, size: 18),
                  label: const Text('Legend'),
                ),
              ],
            ),
          ),
          Expanded(
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(50),
              minScale: 0.5,
              maxScale: 2.0,
              child: CustomPaint(
                size: const Size(400, 600),
                painter: SkillTreePainter(
                  skillTree: _skillTree,
                  animation: _treeAnimationController,
                ),
                child: _buildSkillNodes(),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms, delay: 300.ms);
  }

  Widget _buildSkillNodes() {
    return Stack(
      children: _skillTree.map((skill) {
        return Positioned(
          left: skill.x * 350 + 25,
          top: skill.y * 500 + 50,
          child: _buildSkillNode(skill),
        );
      }).toList(),
    );
  }

  Widget _buildSkillNode(GrammarSkillNode skill) {
    final isLocked = skill.isLocked;
    final isCompleted = skill.isCompleted;
    final isInProgress = skill.isInProgress;

    Color nodeColor;
    if (isCompleted) {
      nodeColor = Colors.green;
    } else if (isInProgress) {
      nodeColor = Colors.orange;
    } else if (isLocked) {
      nodeColor = Colors.grey.shade400;
    } else {
      nodeColor = skill.color ?? AppColors.primaryTeal;
    }

    return GestureDetector(
      onTap: isLocked ? null : () => _onSkillTap(skill),
      child: AnimatedBuilder(
        animation: _treeAnimationController,
        builder: (context, child) {
          final delay = _skillTree.indexOf(skill) * 0.1;
          final animationValue = (_treeAnimationController.value - delay).clamp(0.0, 1.0);
          
          return Transform.scale(
            scale: animationValue,
            child: Opacity(
              opacity: animationValue,
              child: child,
            ),
          );
        },
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: isLocked ? Colors.grey.shade200 : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: nodeColor,
                  width: isCompleted ? 4 : 3,
                ),
                boxShadow: [
                  if (!isLocked)
                    BoxShadow(
                      color: nodeColor.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Center(
                child: isLocked
                    ? Icon(Icons.lock, color: Colors.grey.shade400, size: 28)
                    : isCompleted
                        ? const Icon(Icons.check, color: Colors.green, size: 32)
                        : Icon(
                            skill.icon ?? Icons.school,
                            color: nodeColor,
                            size: 32,
                          ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isLocked ? Colors.grey.shade100 : nodeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                skill.title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isLocked ? Colors.grey.shade500 : AppColors.textDark,
                ),
              ),
            ),
            if (!isLocked && !isCompleted)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: skill.progressPercentage,
                  child: Container(
                    decoration: BoxDecoration(
                      color: nodeColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'access_time':
        return Icons.access_time;
      case 'article':
        return Icons.article;
      case 'subject':
        return Icons.subject;
      case 'history':
        return Icons.history;
      case 'flare':
        return Icons.flare;
      case 'psychology':
        return Icons.psychology;
      default:
        return Icons.school;
    }
  }

  void _onSkillTap(GrammarSkillNode skill) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildSkillDetailSheet(skill),
    );
  }

  Widget _buildSkillDetailSheet(GrammarSkillNode skill) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (skill.color ?? AppColors.primaryTeal).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  skill.icon ?? Icons.school,
                  color: skill.color ?? AppColors.primaryTeal,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      skill.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSkillProgress(skill),
          const SizedBox(height: 24),
          if (skill.prerequisiteIds.isNotEmpty) ...[
            const Text(
              'Prerequisites:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: skill.prerequisiteIds.map((id) {
                final prereq = _skillTree.firstWhere(
                  (s) => s.id == id,
                  orElse: () => GrammarSkillNode(
                    id: id,
                    title: 'Unknown',
                    description: '',
                    type: GrammarSkillType.rule,
                    x: 0,
                    y: 0,
                  ),
                );
                return Chip(
                  label: Text(prereq.title),
                  backgroundColor: prereq.isCompleted
                      ? Colors.green.shade100
                      : Colors.grey.shade200,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => _startLesson(skill),
              icon: Icon(
                skill.isCompleted ? Icons.replay : Icons.play_arrow,
              ),
              label: Text(
                skill.isCompleted ? 'Review Lesson' : 'Start Lesson',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: skill.color ?? AppColors.primaryTeal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: () => _askAIAboutSkill(skill),
              icon: const Icon(Icons.psychology),
              label: const Text('Ask AI Tutor'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryTeal,
                side: const BorderSide(color: AppColors.primaryTeal),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSkillProgress(GrammarSkillNode skill) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Progress',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            Text(
              '${skill.completedLessons}/${skill.totalLessons} lessons',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: skill.progressPercentage,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              skill.color ?? AppColors.primaryTeal,
            ),
            minHeight: 12,
          ),
        ),
      ],
    );
  }

  void _startLesson(GrammarSkillNode skill) {
    Navigator.pop(context);
    
    // Navigate to appropriate lesson screen based on skill type
    Widget lessonScreen;
    switch (skill.type) {
      case GrammarSkillType.conjugation:
        lessonScreen = const ConjugationDrillScreen();
        break;
      case GrammarSkillType.pattern:
        lessonScreen = const SentenceStructureScreen();
        break;
      case GrammarSkillType.rule:
        lessonScreen = GrammarRulesScreen(skillId: skill.id);
        break;
      case GrammarSkillType.exercise:
      case GrammarSkillType.quiz:
        lessonScreen = const ErrorCorrectionScreen();
        break;
      case GrammarSkillType.mastery:
        lessonScreen = const ErrorCorrectionScreen();
        break;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => lessonScreen),
    );
  }

  void _askAIAboutSkill(GrammarSkillNode skill) {
    Navigator.pop(context);
    // Show AI tutor with context about this skill
    _showAITutor(context, grammarSkillId: skill.id);
  }

  void _showAITutor(BuildContext context, {String? grammarSkillId}) {
    // Implementation for AI tutor modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.psychology,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Grammar Tutor',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Ask me anything about grammar!',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Expanded(
              child: Center(
                child: Text(
                  'AI Tutor integration here',
                  style: TextStyle(color: AppColors.textMedium),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLegend(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skill Tree Legend'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLegendItem(
              icon: Icons.lock,
              color: Colors.grey,
              label: 'Locked - Complete prerequisites first',
            ),
            const SizedBox(height: 12),
            _buildLegendItem(
              icon: Icons.circle,
              color: AppColors.primaryTeal,
              label: 'Available - Ready to learn',
            ),
            const SizedBox(height: 12),
            _buildLegendItem(
              icon: Icons.circle,
              color: Colors.orange,
              label: 'In Progress - Continue learning',
            ),
            const SizedBox(height: 12),
            _buildLegendItem(
              icon: Icons.check,
              color: Colors.green,
              label: 'Completed - Mastered!',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label),
        ),
      ],
    );
  }
}

/// Custom painter for drawing connections between skill nodes
class SkillTreePainter extends CustomPainter {
  final List<GrammarSkillNode> skillTree;
  final Animation<double> animation;

  SkillTreePainter({
    required this.skillTree,
    required this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (final skill in skillTree) {
      for (final unlocksId in skill.unlocksIds) {
        final targetSkill = skillTree.firstWhere(
          (s) => s.id == unlocksId,
          orElse: () => skill,
        );

        if (targetSkill != skill) {
          final startX = skill.x * 350 + 60;
          final startY = skill.y * 500 + 85;
          final endX = targetSkill.x * 350 + 60;
          final endY = targetSkill.y * 500 + 50;

          final isUnlocked = !targetSkill.isLocked || skill.isCompleted;
          paint.color = isUnlocked
              ? const Color(0xFF667eea).withOpacity(0.4)
              : Colors.grey.shade300;

          // Draw curved connection line
          final path = Path();
          path.moveTo(startX, startY);
          path.quadraticBezierTo(
            startX,
            (startY + endY) / 2,
            endX,
            endY,
          );

          // Animate the drawing
          final pathMetrics = path.computeMetrics();
          for (final metric in pathMetrics) {
            final drawPath = metric.extractPath(
              0,
              metric.length * animation.value,
            );
            canvas.drawPath(drawPath, paint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
