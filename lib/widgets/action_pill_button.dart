import 'package:flutter/material.dart';

enum PillButtonVariant {
  primaryOrange,
  outlinedGreen,
}

class ActionPillButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final PillButtonVariant variant;
  final IconData icon;
  final bool isLoading;

  const ActionPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = PillButtonVariant.primaryOrange,
    this.icon = Icons.arrow_forward_rounded,
    this.isLoading = false,
  });

  @override
  State<ActionPillButton> createState() => _ActionPillButtonState();
}

class _ActionPillButtonState extends State<ActionPillButton> with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPrimary = widget.variant == PillButtonVariant.primaryOrange;

    final screenWidth = MediaQuery.of(context).size.width;
    final buttonHeight = screenWidth > 600 ? 60.0 : 54.0;
    final fontSize = screenWidth > 600 ? 19.0 : 17.0;
    // Sharp corners: 12px radius instead of full pill
    const cornerRadius = 12.0;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: (_) => _pressController.forward(),
        onTapUp: (_) {
          _pressController.reverse();
          widget.onPressed();
        },
        onTapCancel: () => _pressController.reverse(),
        child: Container(
          width: double.infinity,
          height: buttonHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cornerRadius),
            gradient: isPrimary
                ? const LinearGradient(
                    colors: [Color(0xFFFF6D00), Color(0xFFE64A19)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isPrimary ? null : Colors.white,
            border: isPrimary
                ? null
                : Border.all(
                    color: const Color(0xFF1B5E20),
                    width: 2.0,
                  ),
            boxShadow: [
              BoxShadow(
                color: isPrimary
                    ? const Color(0xFFF4511E).withValues(alpha: 0.40)
                    : Colors.black.withValues(alpha: 0.07),
                offset: const Offset(0, 5),
                blurRadius: 14,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isPrimary ? Colors.white : const Color(0xFF1B5E20),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: isPrimary ? Colors.white : const Color(0xFF1B5E20),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        widget.icon,
                        size: fontSize + 3,
                        color: isPrimary ? Colors.white : const Color(0xFF1B5E20),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
