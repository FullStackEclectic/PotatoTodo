import 'package:flutter/material.dart';
import 'dart:math' show sin, pi;

/// 页面切换动画跳转
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final SlideDirection direction;
  
  SlidePageRoute({
    required this.page, 
    this.direction = SlideDirection.right
  }) : super(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      var begin = direction == SlideDirection.right 
          ? const Offset(1.0, 0.0) 
          : direction == SlideDirection.left
              ? const Offset(-1.0, 0.0)
              : direction == SlideDirection.up
                  ? const Offset(0.0, -1.0)
                  : const Offset(0.0, 1.0);
      
      var end = Offset.zero;
      var curve = Curves.easeInOutCubic;
      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      
      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}

enum SlideDirection {
  left,
  right,
  up,
  down,
}

/// 淡入动画小部件
class FadeInWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  
  const FadeInWidget({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
  }) : super(key: key);
  
  @override
  State<FadeInWidget> createState() => _FadeInWidgetState();
}

class _FadeInWidgetState extends State<FadeInWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut)
    );
    
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}

/// 从下方滑入动画小部件
class SlideInUpWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double offset;
  
  const SlideInUpWidget({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
    this.offset = 100.0,
  }) : super(key: key);
  
  @override
  State<SlideInUpWidget> createState() => _SlideInUpWidgetState();
}

class _SlideInUpWidgetState extends State<SlideInUpWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    
    _offsetAnimation = Tween<Offset>(
      begin: Offset(0, widget.offset / 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut)
    );
    
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _offsetAnimation,
        child: widget.child,
      ),
    );
  }
}

/// 交错动画构建器，用于创建列表的交错动画
class StaggeredAnimationBuilder extends StatelessWidget {
  final int position;
  final int itemCount;
  final Widget Function(BuildContext context, Animation<double> animation) builder;
  final Duration staggeredDuration;
  final Duration itemDuration;
  
  const StaggeredAnimationBuilder({
    Key? key,
    required this.position,
    required this.itemCount,
    required this.builder,
    this.staggeredDuration = const Duration(milliseconds: 50),
    this.itemDuration = const Duration(milliseconds: 400),
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(
        milliseconds: itemDuration.inMilliseconds + 
            (position * staggeredDuration.inMilliseconds)
      ),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        // 创建延迟效果的动画
        final delayedAnimation = position / itemCount;
        final Animation<double> customAnimation = AlwaysStoppedAnimation(
          value > delayedAnimation ? (value - delayedAnimation) / (1 - delayedAnimation) : 0.0
        );
        
        return builder(context, customAnimation);
      },
    );
  }
}

/// 脉冲动画小部件
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final bool repeat;
  
  const PulseAnimation({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.repeat = true,
  }) : super(key: key);
  
  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    
    _animation = Tween<double>(begin: 1.0, end: 1.1)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_controller);
    
    if (widget.repeat) {
      _controller.repeat(reverse: true);
    } else {
      _controller.forward();
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: widget.child,
    );
  }
}

/// 旋转动画小部件
class RotateAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final bool repeat;
  
  const RotateAnimation({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 2000),
    this.repeat = true,
  }) : super(key: key);
  
  @override
  State<RotateAnimation> createState() => _RotateAnimationState();
}

class _RotateAnimationState extends State<RotateAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 2 * 3.141592, // 2π 完整旋转
    ).animate(_controller);
    
    if (widget.repeat) {
      _controller.repeat();
    } else {
      _controller.forward();
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        return Transform.rotate(
          angle: _animation.value,
          child: child,
        );
      },
    );
  }
}

/// 抖动动画小部件，常用于错误提示
class ShakeAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double offset;
  final Function? onEnd;
  
  const ShakeAnimation({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.offset = 10.0,
    this.onEnd,
  }) : super(key: key);
  
  @override
  State<ShakeAnimation> createState() => _ShakeAnimationState();
}

class _ShakeAnimationState extends State<ShakeAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    
    _animation = Tween<double>(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: _ShakeCurve(count: 4, offset: widget.offset)))
        .animate(_controller);
    
    _controller.forward();
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.onEnd != null) {
        widget.onEnd!();
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_animation.value, 0.0),
          child: child,
        );
      },
    );
  }
}

/// 自定义抖动曲线
class _ShakeCurve extends Curve {
  final double offset;
  final int count;
  
  _ShakeCurve({this.count = 3, this.offset = 10.0});
  
  @override
  double transformInternal(double t) {
    return sin(t * count * 2 * 3.141592) * offset * (1 - t);
  }
}

/// Hero动画包装器，方便添加Hero动画
class HeroWrapper extends StatelessWidget {
  final String tag;
  final Widget child;
  
  const HeroWrapper({
    Key? key,
    required this.tag,
    required this.child,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      child: Material(
        type: MaterialType.transparency,
        child: child,
      ),
    );
  }
}

/// 飞入动画小部件，从屏幕外飞入
class FlyInAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final FlyDirection direction;
  
  const FlyInAnimation({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.delay = Duration.zero,
    this.direction = FlyDirection.right,
  }) : super(key: key);
  
  @override
  State<FlyInAnimation> createState() => _FlyInAnimationState();
}

enum FlyDirection {
  left,
  right,
  top,
  bottom,
}

class _FlyInAnimationState extends State<FlyInAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    );
    
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        double dx = 0.0;
        double dy = 0.0;
        
        switch (widget.direction) {
          case FlyDirection.left:
            dx = -300 * (1 - _animation.value);
            break;
          case FlyDirection.right:
            dx = 300 * (1 - _animation.value);
            break;
          case FlyDirection.top:
            dy = -300 * (1 - _animation.value);
            break;
          case FlyDirection.bottom:
            dy = 300 * (1 - _animation.value);
            break;
        }
        
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(dx, dy),
            child: widget.child,
          ),
        );
      },
    );
  }
} 