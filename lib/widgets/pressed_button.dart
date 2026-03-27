import 'package:flutter/material.dart';

/// 带点击反馈的按钮包装器
class PressedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double scaleFactor;

  const PressedButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.scaleFactor = 0.95,
  });

  @override
  State<PressedButton> createState() => _PressedButtonState();
}

class _PressedButtonState extends State<PressedButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// 列表项渐入动画
class FadeInListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;

  const FadeInListItem({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 50),
  });

  @override
  State<FadeInListItem> createState() => _FadeInListItemState();
}

class _FadeInListItemState extends State<FadeInListItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(widget.delay * widget.index, () {
      if (mounted) {
        _controller.forward();
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// 页面切换动画
class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 250),
        );
}
