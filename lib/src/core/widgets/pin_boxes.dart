import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/pin_service.dart';
import '../theme/brand_colors.dart';
import '../theme/design_tokens.dart';

/// A PIN/OTP input widget with 4 rounded boxes driven by a single hidden TextField.
/// Supports digits-only input, backspace, paste, auto-submit on 4th digit,
/// shake animation on error, lockout countdown, and accessibility labels.
class PinBoxes extends StatefulWidget {
  /// Called when 4 digits have been entered.
  final ValueChanged<String> onSubmit;

  /// Called on each text change (for validation).
  final ValueChanged<String>? onChanged;

  /// Whether input is disabled (e.g., during lockout).
  final bool disabled;

  /// Current error message to display under the boxes.
  final String? errorText;

  /// Lockout state: if non-null and isLockedOut, shows countdown and disables input.
  final PinLockoutState? lockoutState;

  /// Semantic label prefix for accessibility (e.g., "PIN" or "OTP").
  final String semanticLabel;

  /// Whether to autofocus on init.
  final bool autofocus;

  /// Optional controller for external control (e.g., clearing).
  final TextEditingController? controller;

  const PinBoxes({
    super.key,
    required this.onSubmit,
    this.onChanged,
    this.disabled = false,
    this.errorText,
    this.lockoutState,
    this.semanticLabel = 'PIN',
    this.autofocus = true,
    this.controller,
  });

  @override
  State<PinBoxes> createState() => _PinBoxesState();
}

class _PinBoxesState extends State<PinBoxes> with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = FocusNode();

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );

    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !widget.disabled) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant PinBoxes oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Trigger shake on error appearance (but not on lockout)
    if (widget.errorText != null && widget.errorText != oldWidget.errorText) {
      if (widget.lockoutState?.isLockedOut != true) {
        _triggerShake();
      }
    }

    // Re-focus when lockout ends
    if (oldWidget.lockoutState?.isLockedOut == true &&
        widget.lockoutState?.isLockedOut == false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !widget.disabled) {
          _focusNode.requestFocus();
        }
      });
    }

    // Re-focus when disabled changes from true to false
    if (oldWidget.disabled && !widget.disabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _triggerShake() {
    _shakeController.forward(from: 0);
    HapticFeedback.heavyImpact();
  }

  void _onChanged(String value) {
    setState(() {});

    // Call onChanged callback if provided (for validation)
    widget.onChanged?.call(value);

    // Only submit once when reaching exactly 4 digits
    if (value.length == 4 && !_submitted) {
      _submitted = true;
      widget.onSubmit(value);
    } else if (value.length < 4) {
      _submitted = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? BrandColors.darkSurface : BrandColors.lightSurface;
    final outlineColor = isDark ? BrandColors.darkOutline : BrandColors.lightOutline;
    final textPrimary = isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary;
    final accentColor = BrandColors.primary;

    // Determine active index (the one being edited)
    final activeIndex = _controller.text.length.clamp(0, 3);

    // Fixed box dimensions - 56x64 as specified
    const boxSize = 56.0;
    const boxHeight = 64.0;
    const gap = 12.0;

    // The PIN boxes row (to be used both for display and as overlay target)
    final pinBoxesRow = AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            _shakeAnimation.value * 15 * (1 - _shakeAnimation.value),
            0,
          ),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
          final filled = index < _controller.text.length;
          final isActive = index == activeIndex && !widget.disabled;
          final digit = filled ? _controller.text[index] : '';

          return Padding(
            padding: EdgeInsets.only(
              right: index < 3 ? gap : 0,
            ),
            child: _PinBox(
              digit: digit,
              filled: filled,
              isActive: isActive,
              isDisabled: widget.disabled,
              size: const Size(boxSize, boxHeight),
              accentColor: accentColor,
              outlineColor: outlineColor,
              bgColor: bgColor,
              textPrimary: textPrimary,
              semanticLabel: '${widget.semanticLabel} digit ${index + 1} of 4',
            ),
          );
        }),
      ),
    );

    return Semantics(
      label: '${widget.semanticLabel} entry, ${_controller.text.length} of 4 digits entered',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The 4 PIN boxes with hidden TextField overlaying ONLY the box row
          Stack(
            alignment: Alignment.center,
            children: [
              pinBoxesRow,
              // Hidden TextField that drives the boxes - only overlays the box row
              Opacity(
                opacity: 0,
                child: SizedBox(
                  width: boxSize * 4 + gap * 3,
                  height: boxHeight,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    showCursor: false,
                    enableSuggestions: false,
                    autocorrect: false,
                    enableIMEPersonalizedLearning: false,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: const TextStyle(
                      fontSize: 1,
                      height: 1,
                      color: Colors.transparent,
                    ),
                    onChanged: widget.disabled ? null : _onChanged,
                    onTapOutside: (_) => _focusNode.unfocus(),
                  ),
                ),
              ),
            ],
          ),

          // Lockout countdown
          if (widget.lockoutState?.isLockedOut == true)
            Padding(
              padding: const EdgeInsets.only(top: DesignTokens.space3),
              child: _LockoutCountdown(
                remaining: widget.lockoutState!.remainingLockout!,
                isDark: isDark,
              ),
            ),

          // Error message (reserved height to prevent layout jump)
          if (widget.errorText != null && widget.lockoutState?.isLockedOut != true)
            Padding(
              padding: const EdgeInsets.only(top: DesignTokens.space3),
              child: SizedBox(
                height: 20, // Reserve height for one line of error text
                child: Text(
                  widget.errorText!,
                  style: DesignTokens.bodySmall.copyWith(
                    color: BrandColors.absentRed,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
          else if (widget.lockoutState?.isLockedOut != true)
            // Reserve space when no error to prevent jump
            const SizedBox(height: 20),
        ],
      ),
    );
  }
}

/// Individual PIN box widget
class _PinBox extends StatelessWidget {
  final String digit;
  final bool filled;
  final bool isActive;
  final bool isDisabled;
  final Size size;
  final Color accentColor;
  final Color outlineColor;
  final Color bgColor;
  final Color textPrimary;
  final String semanticLabel;

  const _PinBox({
    required this.digit,
    required this.filled,
    required this.isActive,
    required this.isDisabled,
    required this.size,
    required this.accentColor,
    required this.outlineColor,
    required this.bgColor,
    required this.textPrimary,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isActive ? accentColor : (filled ? accentColor : outlineColor);
    final borderWidth = isActive ? 2.0 : 1.5;
    final boxColor = filled ? accentColor.withValues(alpha: 0.12) : bgColor;

    return Semantics(
      label: semanticLabel,
      textField: true,
      child: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          color: boxColor,
          borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        alignment: Alignment.center,
        child: filled
            ? Text(
                digit,
                style: DesignTokens.headlineMedium.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              )
            : isActive
                ? _BlinkingCursor(
                    color: accentColor,
                    height: size.height * 0.5,
                  )
                : null,
      ),
    );
  }
}

/// Blinking cursor for the active empty box
class _BlinkingCursor extends StatefulWidget {
  final Color color;
  final double height;

  const _BlinkingCursor({required this.color, required this.height});

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Container(
            width: 2,
            height: widget.height,
            color: widget.color,
          ),
        );
      },
    );
  }
}

/// Lockout countdown display
class _LockoutCountdown extends StatefulWidget {
  final Duration remaining;
  final bool isDark;

  const _LockoutCountdown({required this.remaining, required this.isDark});

  @override
  State<_LockoutCountdown> createState() => _LockoutCountdownState();
}

class _LockoutCountdownState extends State<_LockoutCountdown> {
  late Duration _remaining;
  late StreamSubscription<Duration> _subscription;

  @override
  void initState() {
    super.initState();
    _remaining = widget.remaining;
    _subscription = Stream.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _remaining = _remaining - const Duration(seconds: 1);
          if (_remaining.isNegative) _remaining = Duration.zero;
        });
      }
      return _remaining;
    }).takeWhile((d) => !d.isNegative).listen((_) {});
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seconds = _remaining.inSeconds;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space4,
        vertical: DesignTokens.space2,
      ),
      decoration: BoxDecoration(
        color: BrandColors.absentRed.withValues(alpha: widget.isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
        border: Border.all(
          color: BrandColors.absentRed.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            color: BrandColors.absentRed,
            size: 20,
          ),
          const SizedBox(width: DesignTokens.space2),
          Text(
            'Locked for ${seconds}s',
            style: DesignTokens.bodyMedium.copyWith(
              color: BrandColors.absentRed,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}