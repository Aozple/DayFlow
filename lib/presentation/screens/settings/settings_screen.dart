import 'package:dayflow/data/models/app_settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dayflow/core/utils/custom_snackbar.dart';
import 'package:dayflow/presentation/blocs/settings/settings_bloc.dart';
import 'package:dayflow/core/constants/app_colors.dart';
import 'widgets/settings_header.dart';
import 'widgets/settings_section.dart';
import 'widgets/settings_tile.dart';
import 'widgets/accent_color_picker.dart';
import 'widgets/first_day_picker.dart';
import 'widgets/priority_picker.dart';
import 'widgets/data_management_options.dart';
import 'widgets/about_section.dart';
import 'widgets/confirmation_dialog.dart';

/// Screen for displaying and managing application settings.
///
/// This screen provides a comprehensive interface for users to customize
/// various aspects of the app, including appearance preferences, data management,
/// and app information. It uses BLoC for state management and follows
/// a clean architecture pattern.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

/// State class for SettingsScreen.
///
/// This class manages the UI state and interactions for the settings screen,
/// including handling settings updates and displaying appropriate feedback.
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
                physics:
                    const BouncingScrollPhysics(), // iOS-style scroll physics.
                slivers: [
                  const SettingsHeader(), // The app bar for the settings screen.
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
                        const SizedBox(
                          height: 100,
                        ), // Extra space at the bottom.
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

  /// Builds the "Personalization" section of the settings.
  Widget _buildPersonalizationSection(AppSettings? settings) {
    return SettingsSection(
      title: 'Personalization',
      icon: CupertinoIcons.paintbrush_fill, // Paintbrush icon.
      children: [
        // Tile for choosing the app's accent color.
        SettingsTile(
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
                          ? AppColors.fromHex(
                            settings.accentColor,
                          ) // Use current setting.
                          : AppColors.accent, // Fallback to default accent.
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.divider, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: (settings != null
                              ? AppColors.fromHex(settings.accentColor)
                              : AppColors.accent)
                          .withAlpha(
                            100,
                          ), // Subtle shadow for the color circle.
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
              () => _showAccentColorPicker(settings?.accentColor ?? '#0A84FF'),
          icon: CupertinoIcons.drop_fill, // Droplet icon.
        ),
      ],
    );
  }

  /// Builds the "Preferences" section of the settings.
  Widget _buildPreferencesSection(AppSettings? settings) {
    return SettingsSection(
      title: 'Preferences',
      icon: CupertinoIcons.settings, // Settings icon.
      children: [
        // Tile for setting the first day of the week.
        SettingsTile(
          title: 'First Day of Week',
          subtitle: 'Start your week on',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                settings?.firstDayOfWeek == 'saturday'
                    ? 'Saturday'
                    : 'Monday', // Display current selection.
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
              () => _showFirstDayPicker(settings?.firstDayOfWeek ?? 'monday'),
          icon: CupertinoIcons.calendar, // Calendar icon.
        ),
        // Tile for setting the default task priority.
        SettingsTile(
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
                  color: AppColors.getPriorityColor(
                    settings?.defaultTaskPriority ?? 3,
                  ).withAlpha(20), // Background color based on priority.
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.getPriorityColor(
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
                    color: AppColors.getPriorityColor(
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
          onTap: () => _showPriorityPicker(settings?.defaultTaskPriority ?? 3),
          icon: CupertinoIcons.flag_fill, // Flag icon.
        ),
      ],
    );
  }

  /// Builds the "Data Management" section of the settings.
  Widget _buildDataSection() {
    return SettingsSection(
      title: 'Data Management',
      icon: CupertinoIcons.folder_fill, // Folder icon.
      children: [
        // Tile for exporting data.
        SettingsTile(
          title: 'Export Data',
          subtitle: 'Backup your tasks and notes',
          trailing: Icon(
            CupertinoIcons.share, // Share icon.
            size: 18,
            color: AppColors.accent,
          ),
          onTap: () => _showDataManagementOptions(),
          icon: CupertinoIcons.arrow_up_doc, // Upload document icon.
        ),
        // Tile for importing data.
        SettingsTile(
          title: 'Import Data',
          subtitle: 'Restore from backup file',
          trailing: Icon(
            CupertinoIcons.arrow_down, // Download icon.
            size: 18,
            color: AppColors.accent,
          ),
          onTap: () => _showDataManagementOptions(),
          icon: CupertinoIcons.arrow_down_doc, // Download document icon.
        ),
        // Tile for clearing all data (destructive action).
        SettingsTile(
          title: 'Clear All Data',
          subtitle: 'Delete all tasks and notes',
          trailing: const Icon(
            CupertinoIcons.trash, // Trash icon.
            size: 18,
            color: AppColors.error, // Red for destructive action.
          ),
          onTap: () => _showClearDataConfirmation(),
          icon: CupertinoIcons.trash_fill, // Filled trash icon.
          isDestructive: true, // Mark as destructive for styling.
        ),
      ],
    );
  }

  /// Builds the "About" section of the settings.
  Widget _buildAboutSection() {
    return SettingsSection(
      title: 'About',
      icon: CupertinoIcons.info_circle_fill, // Info circle icon.
      children: [
        // Tile displaying the app version.
        const SettingsInfoTile(
          title: 'Version',
          value: '1.0.0', // Hardcoded version.
          icon: CupertinoIcons.device_phone_portrait, // Phone icon.
        ),
        // Tile for sending feedback.
        SettingsTile(
          title: 'Send Feedback',
          subtitle: 'Help us improve DayFlow',
          trailing: Icon(
            CupertinoIcons.mail, // Mail icon.
            size: 18,
            color: AppColors.accent,
          ),
          onTap: () => _sendFeedback(),
          icon: CupertinoIcons.chat_bubble_fill, // Chat bubble icon.
        ),
        // Tile for rating the app.
        SettingsTile(
          title: 'Rate App',
          subtitle: 'Show some love on App Store',
          trailing: const Icon(
            CupertinoIcons.star_fill, // Star icon.
            size: 18,
            color: AppColors.warning, // Warning color for star.
          ),
          onTap: () => _rateApp(),
          icon: CupertinoIcons.heart_fill, // Heart icon.
        ),
      ],
    );
  }

  /// Shows a modal for picking the app's accent color.
  void _showAccentColorPicker(String currentColor) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext modalContext) {
        return AccentColorPicker(
          currentColor: currentColor,
          onColorSelected: (colorHex) {
            context.read<SettingsBloc>().add(UpdateAccentColor(colorHex));
          },
        );
      },
    );
  }

  /// Shows a modal for picking the first day of the week.
  void _showFirstDayPicker(String currentDay) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return FirstDayPicker(
          currentDay: currentDay,
          onDaySelected: (day) {
            context.read<SettingsBloc>().add(UpdateFirstDayOfWeek(day));
          },
        );
      },
    );
  }

  /// Shows a modal for picking the default task priority.
  void _showPriorityPicker(int currentPriority) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return PriorityPicker(
          currentPriority: currentPriority,
          onPrioritySelected: (priority) {
            context.read<SettingsBloc>().add(UpdateDefaultPriority(priority));
          },
        );
      },
    );
  }

  /// Shows options for data management (export/import).
  void _showDataManagementOptions() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return DataManagementOptions(
          onExportJSON: _exportAsJSON,
          onExportCSV: _exportAsCSV,
          onImportFromFiles: _importFromFiles,
          onImportFromClipboard: _importFromClipboard,
        );
      },
    );
  }

  /// Shows a confirmation dialog before clearing all app data.
  void _showClearDataConfirmation() {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return ConfirmationDialog(
          title: 'Clear All Data',
          icon: CupertinoIcons.exclamationmark_triangle_fill,
          iconColor: AppColors.error,
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
                'This action cannot be undone!',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          onConfirm: _performClearAllData,
          confirmText: 'Clear All Data',
          isDestructive: true,
        );
      },
    );
  }

  /// Shows options for sending feedback (email or copy template).
  void _sendFeedback() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return AboutSection(
          onSendEmail: _openEmail,
          onCopyTemplate: _copyFeedbackTemplate,
        );
      },
    );
  }

  /// Simulates exporting data as JSON.
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
              (context) => const CupertinoAlertDialog(
                title: Text('Export Ready'),
                content: Text('Your data has been exported successfully.'),
                actions: [
                  CupertinoDialogAction(onPressed: null, child: Text('Share')),
                  CupertinoDialogAction(
                    onPressed: null,
                    child: Text('Save to Files'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog on error.
        _showErrorDialog(
          'Export failed. Please try again.',
        ); // Show error message.
      }
    }
  }

  /// Placeholder for CSV export functionality.
  void _exportAsCSV() async {
    _showErrorDialog('CSV export coming soon!');
  }

  /// Placeholder for file import functionality.
  void _importFromFiles() async {
    _showErrorDialog('File import coming soon!');
  }

  /// Imports data from the clipboard.
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
                        data!.text!.length >
                                100 // Truncate long text for preview.
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
                      _processImportData(
                        data.text!,
                      ); // Process the imported data.
                    },
                    child: const Text('Import'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(
          'Failed to read clipboard data.',
        ); // Show error if clipboard access fails.
      }
    }
  }

  /// Simulates processing imported data.
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
              (context) => const CupertinoAlertDialog(
                title: Text('Import Successful'),
                content: Text('Your data has been imported successfully.'),
                actions: [
                  CupertinoDialogAction(onPressed: null, child: Text('OK')),
                ],
              ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog on error.
        _showErrorDialog(
          'Import failed. Please check your data format.',
        ); // Show error message.
      }
    }
  }

  /// Simulates clearing all app data.
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
                      // Navigate to home and clear navigation stack.
                      // Note: This would be context.go('/') in a real app
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
              (context) => const CupertinoAlertDialog(
                title: Text('Error'),
                content: Text('Failed to clear data. Please try again.'),
                actions: [
                  CupertinoDialogAction(onPressed: null, child: Text('OK')),
                ],
              ),
        );
      }
    }
  }

  /// Placeholder for opening email client.
  void _openEmail() async {
    _showErrorDialog('Email integration coming soon!');
  }

  /// Copies a feedback template to the clipboard.
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
    await Clipboard.setData(
      ClipboardData(text: template),
    ); // Copy to clipboard.
    if (mounted) {
      // Show a success dialog.
      showCupertinoDialog(
        context: context,
        builder:
            (context) => const CupertinoAlertDialog(
              title: Text('Template Copied'),
              content: Text(
                'Feedback template has been copied to clipboard. You can paste it in your email app.',
              ),
              actions: [
                CupertinoDialogAction(onPressed: null, child: Text('OK')),
              ],
            ),
      );
    }
  }

  /// Shows a dialog asking the user to rate the app.
  void _rateApp() {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => const CupertinoAlertDialog(
            title: Text('Rate DayFlow'),
            content: Text(
              'Are you enjoying DayFlow? Please consider rating us on the App Store. Your feedback helps us improve!',
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: null,
                child: Text('Maybe Later'), // Dismiss dialog.
              ),
              CupertinoDialogAction(
                onPressed: null, // Close dialog.
                child: Text('Rate Now'),
              ),
            ],
          ),
    );
  }

  /// Helper method to show a generic error/info dialog.
  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Info'),
            content: Text(message),
            actions: const [
              CupertinoDialogAction(onPressed: null, child: Text('OK')),
            ],
          ),
    );
  }
}
