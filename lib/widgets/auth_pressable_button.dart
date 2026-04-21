import 'package:flutter/material.dart';

/// Animated press feedback used on auth primary actions.
class AuthPressableButton extends StatefulWidget {
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Widget child;

  const AuthPressableButton({
    super.key,
    required this.onTap,
    required this.backgroundColor,
    required this.child,
  });

  @override
  State<AuthPressableButton> createState() => _AuthPressableButtonState();
}

class _AuthPressableButtonState extends State<AuthPressableButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => _ctrl.forward() : null,
      onTapUp: widget.onTap != null
          ? (_) {
              _ctrl.reverse();
              widget.onTap!();
            }
          : null,
      onTapCancel: widget.onTap != null ? () => _ctrl.reverse() : null,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: widget.onTap != null
                ? widget.backgroundColor
                : widget.backgroundColor.withAlpha(100),
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.onTap != null
                ? [
                    BoxShadow(
                      color: widget.backgroundColor.withAlpha(60),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}
