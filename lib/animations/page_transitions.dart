import 'package:flutter/cupertino.dart';

/// Custom page transitions for smooth navigation
class PageTransitions {
  // Fade transition
  static Route<T> fade<T>(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  // Slide from right
  static Route<T> slideRight<T>(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        
        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  // Slide from bottom (modal style)
  static Route<T> slideUp<T>(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOutExpo;
        
        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 500),
    );
  }

  // Scale transition
  static Route<T> scale<T>(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  // Shared element hero transition
  static Route<T> sharedAxis<T>(Widget page, {SharedAxisTransitionType type = SharedAxisTransitionType.scaled}) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: type,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 500),
    );
  }

  // Cupertino style (iOS)
  static Route<T> cupertino<T>(Widget page) {
    return CupertinoPageRoute(builder: (_) => page);
  }

  // Ripple/Expansion transition
  static Route<T> ripple<T>(Widget page, {required BuildContext context, required Rect fromRect}) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final screenSize = MediaQuery.of(context).size;
        final centerX = fromRect.left + fromRect.width / 2;
        final centerY = fromRect.top + fromRect.height / 2;
        
        final maxRadius = _dist(centerX, centerY, 0, 0).abs();
        
        return ClipPath(
          clipper: CircularRevealClipper(
            fraction: animation.value,
            centerOffset: Offset(centerX, centerY),
            maxRadius: maxRadius,
          ),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 600),
    );
  }

  static double _dist(double x1, double y1, double x2, double y2) {
    return (x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2);
  }
}

enum SharedAxisTransitionType {
  scaled,
  horizontal,
  vertical,
}

class SharedAxisTransition extends StatelessWidget {
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final SharedAxisTransitionType transitionType;
  final Widget child;

  const SharedAxisTransition({
    super.key,
    required this.animation,
    required this.secondaryAnimation,
    required this.transitionType,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final double t = animation.value;
        final double secondaryT = secondaryAnimation.value;
        
        // Scale and fade for the entering page
        final double scale = _scaleFromT(t);
        final double opacity = _opacityFromT(t);
        
        // Scale and fade for the exiting page
        final double secondaryScale = _scaleFromT(1 - secondaryT);
        final double secondaryOpacity = _opacityFromT(1 - secondaryT);
        
        return Stack(
          children: [
            // Exiting page
            FadeTransition(
              opacity: AlwaysStoppedAnimation(secondaryOpacity),
              child: Transform.scale(
                scale: secondaryScale,
                child: child,
              ),
            ),
            // Entering page
            FadeTransition(
              opacity: AlwaysStoppedAnimation(opacity),
              child: Transform.scale(
                scale: scale,
                child: child,
              ),
            ),
          ],
        );
      },
      child: child,
    );
  }

  double _scaleFromT(double t) {
    return 0.8 + (0.2 * t);
  }

  double _opacityFromT(double t) {
    return t.clamp(0.0, 1.0);
  }
}

class CircularRevealClipper extends CustomClipper<Path> {
  final double fraction;
  final Offset centerOffset;
  final double maxRadius;

  CircularRevealClipper({
    required this.fraction,
    required this.centerOffset,
    required this.maxRadius,
  });

  @override
  Path getClip(Size size) {
    final radius = maxRadius * fraction;
    return Path()
      ..addOval(Rect.fromCircle(center: centerOffset, radius: radius));
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}

/// Page transition observer for tracking navigation
class PageTransitionObserver extends NavigatorObserver {

}
