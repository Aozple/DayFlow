import 'package:dayflow/core/constants/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The section containing the note title input, color picker, date/time, and tags.
///
/// This widget provides input fields for the note title and tags, along with
/// interactive elements for selecting the note color and date/time. It's designed
/// to be a self-contained component that manages its own layout and interactions.
class CreateNoteTitleSection extends StatelessWidget {
  /// Controller for the note title input field.
  final TextEditingController titleController;

  /// Focus node for the note title input field.
  final FocusNode titleFocus;

  /// The currently selected color for the note (in hex format).
  final String selectedColor;

  /// The currently selected time for the note.
  final TimeOfDay selectedTime;

  /// Whether the date was prefilled (affects visual styling).
  final DateTime? prefilledDate;

  /// Callback function when the color indicator is tapped.
  final VoidCallback onColorTap;

  /// Callback function when the date/time button is tapped.
  final VoidCallback onDateTimeTap;

  /// Controller for the tags input field.
  final TextEditingController tagsController;

  const CreateNoteTitleSection({
    super.key,
    required this.titleController,
    required this.titleFocus,
    required this.selectedColor,
    required this.selectedTime,
    required this.prefilledDate,
    required this.onColorTap,
    required this.onDateTimeTap,
    required this.tagsController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface, // Background color for this section.
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Row for color indicator, title field, and date/time button.
          Row(
            children: [
              // Circular color indicator, tappable to open color picker.
              GestureDetector(
                onTap: onColorTap, // Opens the color selection modal.
                child: Container(
                  margin: const EdgeInsets.only(left: 16, top: 16, bottom: 16),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.fromHex(
                      selectedColor,
                    ), // Display selected color.
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.divider, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.fromHex(
                          selectedColor,
                        ).withAlpha(50), // Subtle shadow.
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(
                    CupertinoIcons
                        .doc_text_fill, // Note icon inside the circle.
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              // Expanded text field for the note title.
              Expanded(
                child: TextField(
                  controller: titleController,
                  focusNode: titleFocus,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Note title...', // Placeholder text.
                    hintStyle: TextStyle(color: AppColors.textTertiary),
                    border: InputBorder.none, // No border for the input field.
                    contentPadding: EdgeInsets.all(16),
                  ),
                  textCapitalization:
                      TextCapitalization
                          .sentences, // Capitalize first letter of sentences.
                ),
              ),
              // Button to select date and time for the note.
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 32,
                onPressed: onDateTimeTap, // Opens the date/time picker.
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(
                      20,
                    ), // Subtle accent background.
                    borderRadius: BorderRadius.circular(8),
                    // Add a border if the date was prefilled.
                    border:
                        prefilledDate != null
                            ? Border.all(
                              color: AppColors.accent.withAlpha(50),
                              width: 1,
                            )
                            : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.clock, // Clock icon.
                        size: 16,
                        color: AppColors.accent,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedTime.format(context), // Display selected time.
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.accent,
                          fontWeight:
                              prefilledDate != null
                                  ? FontWeight
                                      .w700 // Bolder if prefilled.
                                  : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Divider below the title/date section.
          Container(
            height: 0.5,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: AppColors.divider,
          ),
          // Text field for adding tags to the note.
          TextField(
            controller: tagsController,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Add tags (comma separated)...', // Placeholder text.
              hintStyle: TextStyle(color: AppColors.textTertiary),
              prefixIcon: Icon(
                CupertinoIcons.tag, // Tag icon.
                color: AppColors.textSecondary,
                size: 18,
              ),
              border: InputBorder.none, // No border.
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }
}
