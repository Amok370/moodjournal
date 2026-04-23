import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/coping_strategy.dart';

class CopingTile extends StatelessWidget {
  final CopingStrategy strategy;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const CopingTile({
    super.key,
    required this.strategy,
    this.isSelected = false,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: isDark ? 0.25 : 0.1)
              : (isDark ? AppTheme.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2)),
          ] : null,
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : AppTheme.accentGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isSelected ? Icons.check_rounded : Icons.spa_rounded,
                color: isSelected ? Colors.white : AppTheme.accentGreen,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strategy.name, style: theme.textTheme.titleMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w600)),
                  if (strategy.description != null && strategy.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(strategy.description!, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            if (strategy.usageCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${strategy.usageCount}x', style: TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
              ),
            if (onDelete != null && !strategy.isDefault) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete,
                child: Icon(Icons.close_rounded, size: 18, color: Colors.red.withValues(alpha: 0.7)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
