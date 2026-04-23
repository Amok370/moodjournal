import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_theme.dart';

class MoodSlider extends StatefulWidget {
  final int initialValue;
  final ValueChanged<int> onChanged;

  const MoodSlider({
    super.key,
    this.initialValue = 5,
    required this.onChanged,
  });

  @override
  State<MoodSlider> createState() => _MoodSliderState();
}

class _MoodSliderState extends State<MoodSlider> with SingleTickerProviderStateMixin {
  late double _value;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue.toDouble();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final moodIndex = _value.round();
    final moodColor = AppTheme.getMoodColor(moodIndex);
    final moodEmoji = AppTheme.getMoodEmoji(moodIndex);
    final moodLabel = AppTheme.getMoodLabel(moodIndex);

    return Column(
      children: [
        // Emoji ve Label
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: child,
            );
          },
          child: Text(
            moodEmoji,
            style: const TextStyle(fontSize: 64),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            moodLabel,
            key: ValueKey(moodLabel),
            style: theme.textTheme.titleLarge?.copyWith(
              color: moodColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$moodIndex/10',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: moodColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 24),

        // Slider
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              // Emoji skalası
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(10, (index) {
                  final isSelected = index + 1 == moodIndex;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _value = (index + 1).toDouble());
                      widget.onChanged(index + 1);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.getMoodColor(index + 1).withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(
                                color: AppTheme.getMoodColor(index + 1),
                                width: 2,
                              )
                            : null,
                      ),
                      child: Text(
                        AppTheme.getMoodEmoji(index + 1),
                        style: TextStyle(
                          fontSize: isSelected ? 22 : 16,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),

              // Slider bar
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: moodColor,
                  inactiveTrackColor: moodColor.withValues(alpha: 0.2),
                  thumbColor: moodColor,
                  overlayColor: moodColor.withValues(alpha: 0.15),
                  trackHeight: 8,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 14,
                    elevation: 4,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 24,
                  ),
                ),
                child: Slider(
                  value: _value,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() => _value = value);
                    widget.onChanged(value.round());
                  },
                ),
              ),

              // Min-Max etiketleri
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Çok Kötü',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.moodColors[0],
                      ),
                    ),
                    Text(
                      'Muhteşem',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.moodColors[9],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
