import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';

/// Section displaying the task's tags.
///
/// This widget displays the task's tags in a visually appealing format,
/// with appropriate styling and spacing.
class TaskDetailsTags extends StatelessWidget {
  /// The list of tags to display.
  final List<String> tags;

  const TaskDetailsTags({super.key, required this.tags});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // Full width.
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface, // Background color.
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                CupertinoIcons.tag, // Tag icon.
                size: 18,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: 8),
              Text(
                'Tags',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10, // Horizontal spacing between tags.
            runSpacing: 10, // Vertical spacing between rows of tags.
            children:
                tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withAlpha(
                        25,
                      ), // Subtle accent background.
                      borderRadius: BorderRadius.circular(
                        20,
                      ), // Capsule shape for tags.
                      border: Border.all(
                        color: AppColors.accent.withAlpha(50),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons
                              .number, // Number icon (could be a generic tag icon too).
                          size: 14,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          tag, // The tag text.
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}
