import 'package:dayflow/core/utils/custom_snackbar.dart';
import 'package:dayflow/data/models/app_settings.dart';
import 'package:dayflow/presentation/blocs/settings/settings_bloc.dart';
import 'package:dayflow/presentation/widgets/draggable_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

// This screen displays and allows users to manage application settings.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

// The state class for our SettingsScreen.
class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    // BlocListener listens for state changes from the SettingsBloc
    // and shows appropriate snackbar messages (success or error).
    return BlocListener<SettingsBloc, SettingsState>(
      listener: (context, state) {
        if (state is SettingsOperationSuccess) {
          CustomSnackBar.success(context, state.message);
        }
        if (state is SettingsError) {
          CustomSnackBar.error(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, state) {
              // Show a loading indicator while settings are being fetched.
              if (state is SettingsLoading) {
                return const Center(
                  child: CupertinoActivityIndicator(radius: 20),
                );
              }

              // Get the settings data if available, otherwise null.
              final settings = state is SettingsLoaded ? state.settings : null;

              // Use CustomScrollView for a scrollable screen with a sticky app bar.
              return CustomScrollView(
                physics: const BouncingScrollPhysics(), // iOS-style scroll physics.
                slivers: [
                  _buildHeader(), // The app bar for the settings screen.
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        // Sections for different categories of settings.
                        _buildPersonalizationSection(settings),
                        const SizedBox(height: 16),
                        _buildPreferencesSection(settings),
                        const SizedBox(height: 16),
                        _buildDataSection(),
                        const SizedBox(height: 16),
                        _buildAboutSection(),
                        const SizedBox(height: 100), // Extra space at the bottom.
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // Builds the custom SliverAppBar for the settings screen.
  Widget _buildHeader() {
    return SliverAppBar(
      backgroundColor: Colors.transparent, // Transparent background.
      elevation: 0, // No shadow.
      pinned: true, // Stays at the top when scrolling.
      leading: Container(
        margin: const EdgeInsets.only(left: 8),
        child: CircleAvatar(
          backgroundColor: AppColors.surfaceLight,
          child: IconButton(
            icon: const Icon(
              CupertinoIcons.chevron_back, // Back arrow icon.
              color: AppColors.textPrimary,
              size: 22,
            ),
            onPressed: () => context.pop(), // Pop the current screen to go back.
          ),
        ),
      ),
      title: const Text(
        'Settings',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      centerTitle: true, // Center the title.
    );
  }

  // Builds the "Personalization" section of the settings.
  Widget _buildPersonalizationSection(AppSettings? settings) {
    return _buildSection(
      title: 'Personalization',
      icon: CupertinoIcons.paintbrush_fill, // Paintbrush icon.
      children: [
        // Tile for choosing the app's accent color.
        _buildTapTile(
          title: 'Accent Color',
          subtitle: 'Choose your app theme color',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Display the currently selected accent color.
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color:
                      settings != null
                          ? AppColors.fromHex(settings.accentColor) // Use current setting.
                          : AppColors.accent, // Fallback to default accent.
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.divider, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: (settings != null
                              ? AppColors.fromHex(settings.accentColor)
                              : AppColors.accent)
                          .withAlpha(100), // Subtle shadow for the color circle.
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                CupertinoIcons.chevron_right, // Disclosure indicator.
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          onTap:
              () => _showAccentColorPicker(settings?.accentColor ?? '#0A84FF'), // Open color picker.
          icon: CupertinoIcons.drop_fill, // Droplet icon.
        ),
      ],
    );
  }

  // Builds the "Preferences" section of the settings.
  Widget _buildPreferencesSection(AppSettings? settings) {
    return _buildSection(
      title: 'Preferences',
      icon: CupertinoIcons.settings, // Settings icon.
      children: [
        // Tile for setting the first day of the week.
        _buildTapTile(
          title: 'First Day of Week',
          subtitle: 'Start your week on',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                settings?.firstDayOfWeek == 'saturday' ? 'Saturday' : 'Monday', // Display current selection.
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          onTap:
              () => _showFirstDayPicker(settings?.firstDayOfWeek ?? 'monday'), // Open day picker.
          icon: CupertinoIcons.calendar, // Calendar icon.
        ),

        // Tile for setting the default task priority.
        _buildTapTile(
          title: 'Default Task Priority',
          subtitle: 'Priority for new tasks',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Display the current default priority.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getPriorityColor(
                    settings?.defaultTaskPriority ?? 3,
                  ).withAlpha(20), // Background color based on priority.
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _getPriorityColor(
                      settings?.defaultTaskPriority ?? 3,
                    ).withAlpha(50),
                    width: 1,
                  ),
                ),
                child: Text(
                  'P${settings?.defaultTaskPriority ?? 3}', // "P3", "P5", etc.
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getPriorityColor(
                      settings?.defaultTaskPriority ?? 3,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          onTap: () => _showPriorityPicker(settings?.defaultTaskPriority ?? 3), // Open priority picker.
          icon: CupertinoIcons.flag_fill, // Flag icon.
        ),
      ],
    );
  }

  // Helper method to get a color based on task priority.
  Color _getPriorityColor(int priority) {
    if (priority >= 4) return AppColors.error; // High priority.
    if (priority == 3) return AppColors.warning; // Medium priority.
    return AppColors.textSecondary; // Low priority.
  }

  // Builds the "Data Management" section of the settings.
  Widget _buildDataSection() {
    return _buildSection(
      title: 'Data Management',
      icon: CupertinoIcons.folder_fill, // Folder icon.
      children: [
        // Tile for exporting data.
        _buildTapTile(
          title: 'Export Data',
          subtitle: 'Backup your tasks and notes',
          trailing: Icon(
            CupertinoIcons.share, // Share icon.
            size: 18,
            color: AppColors.accent,
          ),
          onTap: () {
            _exportData(); // Open export options.
          },
          icon: CupertinoIcons.arrow_up_doc, // Upload document icon.
        ),

        // Tile for importing data.
        _buildTapTile(
          title: 'Import Data',
          subtitle: 'Restore from backup file',
          trailing: Icon(
            CupertinoIcons.arrow_down, // Download icon.
            size: 18,
            color: AppColors.accent,
          ),
          onTap: () {
            _importData(); // Open import options.
          },
          icon: CupertinoIcons.arrow_down_doc, // Download document icon.
        ),

        // Tile for clearing all data (destructive action).
        _buildTapTile(
          title: 'Clear All Data',
          subtitle: 'Delete all tasks and notes',
          trailing: const Icon(
            CupertinoIcons.trash, // Trash icon.
            size: 18,
            color: AppColors.error, // Red for destructive action.
          ),
          onTap: () {
            _showClearDataConfirmation(); // Show confirmation dialog.
          },
          icon: CupertinoIcons.trash_fill, // Filled trash icon.
          isDestructive: true, // Mark as destructive for styling.
        ),
      ],
    );
  }

  // Builds the "About" section of the settings.
  Widget _buildAboutSection() {
    return _buildSection(
      title: 'About',
      icon: CupertinoIcons.info_circle_fill, // Info circle icon.
      children: [
        // Tile displaying the app version.
        _buildInfoTile(
          title: 'Version',
          value: '1.0.0', // Hardcoded version.
          icon: CupertinoIcons.device_phone_portrait, // Phone icon.
        ),

        // Tile for sending feedback.
        _buildTapTile(
          title: 'Send Feedback',
          subtitle: 'Help us improve DayFlow',
          trailing: Icon(
            CupertinoIcons.mail, // Mail icon.
            size: 18,
            color: AppColors.accent,
          ),
          onTap: () {
            _sendFeedback(); // Open feedback options.
          },
          icon: CupertinoIcons.chat_bubble_fill, // Chat bubble icon.
        ),

        // Tile for rating the app.
        _buildTapTile(
          title: 'Rate App',
          subtitle: 'Show some love on App Store',
          trailing: const Icon(
            CupertinoIcons.star_fill, // Star icon.
            size: 18,
            color: AppColors.warning, // Warning color for star.
          ),
          onTap: () {
            _rateApp(); // Open rate app dialog.
          },
          icon: CupertinoIcons.heart_fill, // Heart icon.
        ),
      ],
    );
  }

  // A reusable widget to build a section container with a title and icon.
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface, // Background color for the section.
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with icon and title.
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.accent), // Section icon.
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // The content of the section (list of tiles).
          ...children,
        ],
      ),
    );
  }

  // Shows a modal for picking the app's accent color.
  void _showAccentColorPicker(String currentColor) {
    String selectedColorHex = currentColor; // Local state for the picker.

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableModal(
              title: 'Accent Color',
              initialHeight: 420,
              minHeight: 250,
              allowFullScreen: true,
              leftAction: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.pop(modalContext), // Cancel button.
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              rightAction: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  // Dispatch event to update accent color in the bloc.
                  context.read<SettingsBloc>().add(
                    UpdateAccentColor(selectedColorHex),
                  );
                  Navigator.pop(modalContext); // Close the modal.
                  HapticFeedback.mediumImpact(); // Provide haptic feedback.
                },
                child: Text(
                  'Apply',
                  style: TextStyle(
                    color: AppColors.fromHex(selectedColorHex), // Apply button color matches selected accent.
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Live preview section of the selected accent color.
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Color swatch preview.
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.fromHex(selectedColorHex),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.fromHex(
                                        selectedColorHex,
                                      ).withAlpha(100),
                                      blurRadius: 12,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Preview',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Your app accent color',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.fromHex(
                                          selectedColorHex,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Sample UI elements showing the accent color in action.
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              // Sample button.
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.fromHex(selectedColorHex),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Button',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              // Sample icon.
                              Icon(
                                CupertinoIcons.heart_fill,
                                color: AppColors.fromHex(selectedColorHex),
                                size: 24,
                              ),
                              // Sample switch.
                              CupertinoSwitch(
                                value: true,
                                onChanged: null, // Disabled for preview.
                                activeTrackColor: AppColors.fromHex(
                                  selectedColorHex,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // List of selectable accent color options.
                    ...AppColors.accentColors.asMap().entries.map((entry) {
                      final index = entry.key;
                      final color = entry.value;
                      final colorHex = AppColors.toHex(color);
                      final isSelected = selectedColorHex == colorHex;

                      // Define human-readable names for the colors.
                      final colorNames = [
                        'Blue', 'Green', 'Red', 'Orange', 'Yellow',
                        'Indigo', 'Purple', 'Cyan', 'Pink',
                      ];
                      final colorName =
                          index < colorNames.length
                              ? colorNames[index]
                              : 'Custom';

                      return GestureDetector(
                        onTap: () {
                          setModalState(() => selectedColorHex = colorHex); // Update local selection.
                          HapticFeedback.selectionClick(); // Provide haptic feedback.
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? color.withAlpha(10) // Subtle background if selected.
                                    : Colors.transparent,
                            border: const Border(
                              bottom: BorderSide(
                                color: AppColors.divider,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Color preview square.
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? Colors.white // White border if selected.
                                            : AppColors.divider.withAlpha(100), // Subtle border otherwise.
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow:
                                      isSelected
                                          ? [
                                            BoxShadow(
                                              color: color.withAlpha(100),
                                              blurRadius: 8,
                                              spreadRadius: 1,
                                            ),
                                          ]
                                          : [],
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Color name and hex code.
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      colorName,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            isSelected
                                                ? color // Text color matches accent if selected.
                                                : AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      colorHex.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Checkmark indicator if selected.
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child:
                                    isSelected
                                        ? Icon(
                                          CupertinoIcons.checkmark_circle_fill,
                                          key: ValueKey(colorHex), // Key for animation.
                                          color: color,
                                          size: 24,
                                        )
                                        : const SizedBox(
                                          key: ValueKey('empty'), // Key for animation.
                                          width: 24,
                                        ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Shows a modal for picking the first day of the week.
  void _showFirstDayPicker(String currentDay) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => Container(
            height: 260,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Material(
              type: MaterialType.transparency, // Needed for InkWell/ListTile to work correctly.
              child: Column(
                children: [
                  // Header for the picker.
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.divider,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.pop(context), // Cancel button.
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                        const Text(
                          'First Day of Week', // Title.
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.pop(context), // Done button.
                          child: Text(
                            'Done',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Options for Saturday and Monday.
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          // Saturday option.
                          ListTile(
                            leading: const Icon(
                              CupertinoIcons.calendar,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            title: const Text(
                              'Saturday',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: const Text(
                              'Traditional week start',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            trailing:
                                currentDay == 'saturday'
                                    ? Icon(
                                      CupertinoIcons.checkmark_circle_fill, // Checkmark if selected.
                                      color: AppColors.accent,
                                      size: 24,
                                    )
                                    : null,
                            onTap: () {
                              context.read<SettingsBloc>().add(
                                const UpdateFirstDayOfWeek('saturday'), // Dispatch update event.
                              );
                              Navigator.pop(context); // Close modal.
                              HapticFeedback.selectionClick(); // Provide haptic feedback.
                            },
                          ),

                          // Divider between options.
                          const Divider(height: 1, color: AppColors.divider),

                          // Monday option.
                          ListTile(
                            leading: const Icon(
                              CupertinoIcons.calendar,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            title: const Text(
                              'Monday',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: const Text(
                              'International standard',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            trailing:
                                currentDay == 'monday'
                                    ? Icon(
                                      CupertinoIcons.checkmark_circle_fill,
                                      color: AppColors.accent,
                                      size: 24,
                                    )
                                    : null,
                            onTap: () {
                              context.read<SettingsBloc>().add(
                                const UpdateFirstDayOfWeek('monday'), // Dispatch update event.
                              );
                              Navigator.pop(context); // Close modal.
                              HapticFeedback.selectionClick(); // Provide haptic feedback.
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // A reusable widget to build a tappable list tile for settings.
  Widget _buildTapTile({
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
    required IconData icon,
    bool isDestructive = false, // If true, text and icon will be red.
  }) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)), // Top border.
      ),
      child: ListTile(
        leading: Icon(
          icon,
          size: 20,
          color: isDestructive ? AppColors.error : AppColors.textSecondary, // Red if destructive.
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDestructive ? AppColors.error : AppColors.textPrimary, // Red if destructive.
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        trailing: trailing, // Custom trailing widget.
        onTap: onTap, // Action on tap.
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  // A reusable widget to build an info list tile (read-only).
  Widget _buildInfoTile({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: ListTile(
        leading: Icon(icon, size: 20, color: AppColors.textSecondary), // Leading icon.
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        trailing: Text(
          value, // The info value.
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  // Shows a modal for picking the default task priority.
  void _showPriorityPicker(int currentPriority) {
    int selectedPriority = currentPriority; // Local state for the picker.

    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setModalState) {
              return DraggableModal(
                title: 'Default Priority',
                initialHeight: 320,
                minHeight: 200,
                leftAction: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context), // Cancel button.
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                rightAction: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    // Dispatch event to update default priority.
                    context.read<SettingsBloc>().add(
                      UpdateDefaultPriority(selectedPriority),
                    );
                    Navigator.pop(context); // Close modal.
                    HapticFeedback.mediumImpact(); // Provide haptic feedback.
                  },
                  child: Text(
                    'Done',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: List.generate(5, (index) {
                      final priority = index + 1;
                      final isSelected = selectedPriority == priority;

                      Color priorityColor = AppColors.textSecondary;
                      String priorityLabel = 'Normal';
                      IconData priorityIcon = CupertinoIcons.flag;

                      // Determine color, label, and icon based on priority level.
                      switch (priority) {
                        case 5:
                          priorityColor = AppColors.error;
                          priorityLabel = 'Urgent';
                          priorityIcon =
                              CupertinoIcons.exclamationmark_triangle_fill;
                          break;
                        case 4:
                          priorityColor = AppColors.warning;
                          priorityLabel = 'High';
                          priorityIcon = CupertinoIcons.flag_fill;
                          break;
                        case 3:
                          priorityLabel = 'Medium';
                          priorityIcon = CupertinoIcons.flag;
                          break;
                        case 2:
                          priorityLabel = 'Normal';
                          priorityIcon = CupertinoIcons.flag;
                          break;
                        case 1:
                          priorityLabel = 'Low';
                          priorityIcon = CupertinoIcons.flag;
                          break;
                      }

                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            selectedPriority =
                                priority; // Update local selection.
                          });
                          HapticFeedback.selectionClick(); // Provide haptic feedback.
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? priorityColor.withAlpha(10) // Subtle background if selected.
                                    : Colors.transparent,
                            border: const Border(
                              bottom: BorderSide(
                                color: AppColors.divider,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Priority icon with colored background.
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: priorityColor.withAlpha(20),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Icon(
                                    priorityIcon,
                                    size: 20,
                                    color: priorityColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Priority number and label.
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Priority $priority',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            isSelected
                                                ? priorityColor // Text color matches priority if selected.
                                                : AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      priorityLabel,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color:
                                            isSelected
                                                ? priorityColor.withAlpha(200)
                                                : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Checkmark indicator if selected.
                              if (isSelected)
                                Icon(
                                  CupertinoIcons.checkmark_circle_fill,
                                  color: priorityColor,
                                  size: 24,
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              );
            },
          ),
    );
  }

  // Shows options for exporting data (JSON or CSV).
  void _exportData() async {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            title: const Text('Export Data'),
            message: const Text('Choose export format'),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context); // Close action sheet.
                  _exportAsJSON(); // Export as JSON.
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.doc_text, size: 18),
                    SizedBox(width: 8),
                    Text('Export as JSON'),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context); // Close action sheet.
                  _exportAsCSV(); // Export as CSV.
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.table, size: 18),
                    SizedBox(width: 8),
                    Text('Export as CSV'),
                  ],
                ),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(context), // Cancel button.
              child: const Text('Cancel'),
            ),
          ),
    );
  }

  // Simulates exporting data as JSON.
  void _exportAsJSON() async {
    try {
      // Show a loading dialog.
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const CupertinoAlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoActivityIndicator(),
                  SizedBox(height: 16),
                  Text('Preparing export...'),
                ],
              ),
            ),
      );

      // Simulate a delay for the export process.
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.pop(context); // Close loading dialog.

        // Show a success dialog with options to share or save.
        showCupertinoDialog(
          context: context,
          builder:
              (context) => CupertinoAlertDialog(
                title: const Text('Export Ready'),
                content: const Text(
                  'Your data has been exported successfully.',
                ),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Share'),
                  ),
                  CupertinoDialogAction(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Save to Files'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog on error.
        _showErrorDialog('Export failed. Please try again.'); // Show error message.
      }
    }
  }

  // Placeholder for CSV export functionality.
  void _exportAsCSV() async {
    _showErrorDialog('CSV export coming soon!');
  }

  // Shows options for importing data (from files or clipboard).
  void _importData() async {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            title: const Text('Import Data'),
            message: const Text('Select import source'),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context); // Close action sheet.
                  _importFromFiles(); // Import from files.
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.folder, size: 18),
                    SizedBox(width: 8),
                    Text('Import from Files'),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context); // Close action sheet.
                  _importFromClipboard(); // Import from clipboard.
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.doc_on_clipboard, size: 18),
                    SizedBox(width: 8),
                    Text('Import from Clipboard'),
                  ],
                ),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(context), // Cancel button.
              child: const Text('Cancel'),
            ),
          ),
    );
  }

  // Placeholder for file import functionality.
  void _importFromFiles() async {
    _showErrorDialog('File import coming soon!');
  }

  // Imports data from the clipboard.
  void _importFromClipboard() async {
    try {
      // Get text data from the clipboard.
      final ClipboardData? data = await Clipboard.getData('text/plain');

      // If clipboard is empty, show an error.
      if (data?.text?.isEmpty ?? true) {
        if (mounted) {
          _showErrorDialog('Clipboard is empty or contains no text.');
        }
        return;
      }

      // Show a confirmation dialog with a preview of the clipboard data.
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder:
              (context) => CupertinoAlertDialog(
                title: const Text('Import from Clipboard'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Found data in clipboard:'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        data!.text!.length > 100 // Truncate long text for preview.
                            ? '${data.text!.substring(0, 100)}...'
                            : data.text!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Import this data?'),
                  ],
                ),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context), // Cancel import.
                  ),
                  CupertinoDialogAction(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog.
                      _processImportData(data.text!); // Process the imported data.
                    },
                    child: const Text('Import'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to read clipboard data.'); // Show error if clipboard access fails.
      }
    }
  }

  // Simulates processing imported data.
  void _processImportData(String data) async {
    // Show a loading dialog.
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const CupertinoAlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoActivityIndicator(),
                SizedBox(height: 16),
                Text('Processing import...'),
              ],
            ),
          ),
    );

    try {
      // Simulate processing delay.
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.pop(context); // Close loading dialog.

        // Show success dialog.
        showCupertinoDialog(
          context: context,
          builder:
              (context) => CupertinoAlertDialog(
                title: const Text('Import Successful'),
                content: const Text(
                  'Your data has been imported successfully.',
                ),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog on error.
        _showErrorDialog('Import failed. Please check your data format.'); // Show error message.
      }
    }
  }

  // Shows a confirmation dialog before clearing all app data.
  void _showClearDataConfirmation() {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Row(
              children: [
                Icon(
                  CupertinoIcons.exclamationmark_triangle_fill, // Warning icon.
                  color: AppColors.error,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text('Clear All Data'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('This will permanently delete:'),
                SizedBox(height: 8),
                Text('• All tasks and notes'),
                Text('• All settings and preferences'),
                Text('• All app data'),
                SizedBox(height: 12),
                Text(
                  'This action cannot be undone!', // Strong warning.
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context), // Cancel action.
              ),
              CupertinoDialogAction(
                isDestructiveAction: true, // Red button.
                onPressed: () {
                  Navigator.pop(context); // Close dialog.
                  _performClearAllData(); // Proceed with data clearing.
                },
                child: const Text('Clear All Data'),
              ),
            ],
          ),
    );
  }

  // Simulates clearing all app data.
  void _performClearAllData() async {
    // Show a loading indicator.
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) =>
              const Center(child: CupertinoActivityIndicator(radius: 20)),
    );

    try {
      // In a real app, you would call repository methods here:
      // await taskRepository.clearAllTasks();
      // await settingsRepository.clearSettings();

      // Simulate an async operation.
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.pop(context); // Close loading dialog.

        // Show success message and navigate to home screen.
        showCupertinoDialog(
          context: context,
          builder:
              (context) => CupertinoAlertDialog(
                title: const Text('Data Cleared'),
                content: const Text('All data has been successfully cleared.'),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog.
                      context.go('/'); // Navigate to home and clear navigation stack.
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog on error.

        // Show error message.
        showCupertinoDialog(
          context: context,
          builder:
              (context) => CupertinoAlertDialog(
                title: const Text('Error'),
                content: const Text('Failed to clear data. Please try again.'),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    }
  }

  // Shows options for sending feedback (email or copy template).
  void _sendFeedback() {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            title: const Text('Send Feedback'),
            message: const Text('How would you like to contact us?'),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context); // Close action sheet.
                  _openEmail(); // Open email client.
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.mail, size: 18),
                    SizedBox(width: 8),
                    Text('Send Email'),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context); // Close action sheet.
                  _copyFeedbackTemplate(); // Copy feedback template to clipboard.
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.doc_on_clipboard, size: 18),
                    SizedBox(width: 8),
                    Text('Copy Feedback Template'),
                  ],
                ),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(context), // Cancel button.
              child: const Text('Cancel'),
            ),
          ),
    );
  }

  // Placeholder for opening email client.
  void _openEmail() async {
    _showErrorDialog('Email integration coming soon!');
  }

  // Copies a feedback template to the clipboard.
  void _copyFeedbackTemplate() async {
    final now = DateTime.now();
    // The feedback template string.
    final template = '''
DayFlow Feedback

App Version: 1.0.0
Device: iOS/Android
Date: ${now.toString().split('.')[0]}

Feedback Type: [Bug Report / Feature Request / General Feedback]

Description:
[Please describe your feedback here]

Steps to Reproduce (if bug):
1. 
2. 
3. 

Expected Behavior:
[What did you expect to happen?]

Actual Behavior:
[What actually happened?]

Additional Notes:
[Any other information that might be helpful]
''';

    await Clipboard.setData(ClipboardData(text: template)); // Copy to clipboard.

    if (mounted) {
      // Show a success dialog.
      showCupertinoDialog(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
              title: const Text('Template Copied'),
              content: const Text(
                'Feedback template has been copied to clipboard. You can paste it in your email app.',
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  // Shows a dialog asking the user to rate the app.
  void _rateApp() {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Rate DayFlow'),
            content: const Text(
              'Are you enjoying DayFlow? Please consider rating us on the App Store. Your feedback helps us improve!',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Maybe Later'),
                onPressed: () => Navigator.pop(context), // Dismiss dialog.
              ),
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.pop(context); // Close dialog.
                  _openAppStore(); // Open app store.
                },
                child: const Text('Rate Now'),
              ),
            ],
          ),
    );
  }

  // Placeholder for opening the app store.
  void _openAppStore() async {
    _showErrorDialog('App Store integration coming soon!');
  }

  // Helper method to show a generic error/info dialog.
  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Info'),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
