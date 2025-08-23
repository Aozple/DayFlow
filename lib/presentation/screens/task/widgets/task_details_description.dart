import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';

/// Section displaying the task's description.
///
/// This widget displays the task description in a formatted container,
/// with appropriate styling and readability.
class TaskDetailsDescription extends StatelessWidget {
  /// The description text to display.
  final String description;

  const TaskDetailsDescription({super.key, required this.description});

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
                CupertinoIcons.doc_text, // Document icon.
                size: 18,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: 8),
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description, // Display the description text.
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
              height: 1.5, // Line height for readability.
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
