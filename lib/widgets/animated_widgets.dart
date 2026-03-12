import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../animations/animation_config.dart';

class AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final int delayMs;
  
  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.delayMs = 0,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AnimationConfig.micro,
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: AnimationConfig.smooth),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryTeal.withValues(alpha: _isPressed ? 0.2 : 0.1),
                    blurRadius: _isPressed ? 10 : 20,
                    offset: Offset(0, _isPressed ? 4 : 8),
                    spreadRadius: _isPressed ? 0 : 2,
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    ).animate()
      .fadeIn(delay: widget.delayMs.ms)
      .slideY(begin: 0.2, end: 0, delay: widget.delayMs.ms)
      .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), delay: widget.delayMs.ms);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class PulsingButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color? color;
  
  const PulsingButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color,
  });

  @override
  State<PulsingButton> createState() => _PulsingButtonState();
}

class _PulsingButtonState extends State<PulsingButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: (widget.color ?? AppColors.accentCoral).withValues(alpha: 0.4),
                  blurRadius: 20 * _animation.value,
                  spreadRadius: 2 * _animation.value,
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: widget.onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.color ?? AppColors.accentCoral,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class CircularProgressAnimated extends StatelessWidget {
  final double progress;
  final double size;
  final Color? color;
  final Widget? centerChild;
  
  const CircularProgressAnimated({
    super.key,
    required this.progress,
    this.size = 120,
    this.color,
    this.centerChild,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: AnimationConfig.slow,
      curve: AnimationConfig.smooth,
      builder: (context, value, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(color ?? AppColors.primaryTeal),
              ),
            ),
            if (centerChild != null) centerChild!,
          ],
        );
      },
    );
  }
}

class WaveformBars extends StatefulWidget {
  final bool isActive;
  final Color color;
  
  const WaveformBars({
    super.key, 
    this.isActive = false,
    this.color = AppColors.accentOrange,
  });

  @override
  State<WaveformBars> createState() => _WaveformBarsState();
}

class _WaveformBarsState extends State<WaveformBars> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(WaveformBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(20, (index) {
            final height = widget.isActive 
                ? 10 + (index % 3 == 0 ? 20 : 10) * _controller.value
                : 4.0;
            return Container(
              width: 4,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

