import 'dart:io';
import 'package:dayflow/core/services/export_import/export_import_service.dart';
import 'package:dayflow/core/services/export_import/file_manager.dart';
import 'package:dayflow/core/services/export_import/models/export_import_models.dart';
import 'package:dayflow/data/models/app_settings.dart';
import 'package:dayflow/presentation/blocs/habits/habit_bloc.dart';
import 'package:dayflow/presentation/blocs/tasks/task_bloc.dart';
import 'package:dayflow/presentation/screens/settings/widgets/export_selection_dialog.dart';
import 'package:dayflow/presentation/screens/settings/widgets/import_selection_dialog.dart';
import 'package:dayflow/presentation/screens/settings/widgets/notification_time_picker.dart';
import 'package:dayflow/presentation/widgets/status_bar_padding.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dayflow/core/utils/custom_snackbar.dart';
import 'package:dayflow/presentation/blocs/settings/settings_bloc.dart';
import 'package:dayflow/core/constants/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'widgets/settings_header.dart';
import 'widgets/settings_section.dart';
import 'widgets/settings_tile.dart';
import 'widgets/accent_color_picker.dart';
import 'widgets/first_day_picker.dart';
import 'widgets/priority_picker.dart';
import 'widgets/about_section.dart';
import 'widgets/confirmation_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ExportImportService _exportImportService = ExportImportService();
  bool _isProcessing = false;
  DateTime? _lastExportTime;
  ExportResult? _lastExportResult;

  @override
  Widget build(BuildContext context) {
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
        body: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            if (state is SettingsLoading) {
              return const Center(
                child: CupertinoActivityIndicator(radius: 20),
              );
            }

            final settings = state is SettingsLoaded ? state.settings : null;

            return Column(
              children: [
                const StatusBarPadding(),
                const SettingsHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        _buildPersonalizationSection(settings),
                        const SizedBox(height: 16),
                        _buildPreferencesSection(settings),
                        const SizedBox(height: 16),
                        _buildNotificationSection(settings),
                        const SizedBox(height: 16),
                        _buildDataSection(),
                        const SizedBox(height: 16),
                        _buildAboutSection(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPersonalizationSection(AppSettings? settings) {
    return SettingsSection(
      title: 'Personalization',
      icon: CupertinoIcons.paintbrush_fill,
      children: [
        SettingsTile(
          title: 'Accent Color',
          subtitle: 'Choose your app theme color',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color:
                      settings != null
                          ? AppColors.fromHex(settings.accentColor)
                          : AppColors.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.divider, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: (settings != null
                              ? AppColors.fromHex(settings.accentColor)
                              : AppColors.accent)
                          .withAlpha(100),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
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
              () => _showAccentColorPicker(settings?.accentColor ?? '#0A84FF'),
          icon: CupertinoIcons.drop_fill,
        ),
      ],
    );
  }

  Widget _buildPreferencesSection(AppSettings? settings) {
    return SettingsSection(
      title: 'Preferences',
      icon: CupertinoIcons.settings,
      children: [
        SettingsTile(
          title: 'First Day of Week',
          subtitle: 'Start your week on',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                settings?.firstDayOfWeek == 'saturday' ? 'Saturday' : 'Monday',
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
          icon: CupertinoIcons.calendar,
        ),
        SettingsTile(
          title: 'Default Task Priority',
          subtitle: 'Priority for new tasks',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.getPriorityColor(
                    settings?.defaultTaskPriority ?? 3,
                  ).withAlpha(20),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.getPriorityColor(
                      settings?.defaultTaskPriority ?? 3,
                    ).withAlpha(50),
                    width: 1,
                  ),
                ),
                child: Text(
                  'P${settings?.defaultTaskPriority ?? 3}',
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
          icon: CupertinoIcons.flag_fill,
        ),
      ],
    );
  }

  Widget _buildNotificationSection(AppSettings? settings) {
    return SettingsSection(
      title: 'Notifications',
      icon: CupertinoIcons.bell_fill,
      children: [
        SettingsTile(
          title: 'Default Reminder',
          subtitle: 'Enable reminders for new tasks',
          trailing: CupertinoSwitch(
            value: settings?.defaultNotificationEnabled ?? false,
            onChanged: (value) {
              context.read<SettingsBloc>().add(
                UpdateNotificationEnabled(value),
              );
            },
            activeTrackColor: AppColors.accent,
          ),
          onTap: () {},
          icon: CupertinoIcons.bell,
        ),
        if (settings?.defaultNotificationEnabled ?? false)
          SettingsTile(
            title: 'Default Reminder Time',
            subtitle: 'When to remind before tasks',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.accent.withAlpha(50),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getNotificationTimeText(
                      settings?.defaultNotificationMinutesBefore ?? 5,
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
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
            onTap:
                () => _showNotificationTimePicker(
                  settings?.defaultNotificationMinutesBefore ?? 5,
                ),
            icon: CupertinoIcons.time,
          ),
        SettingsTile(
          title: 'Notification Sound',
          subtitle: 'Play sound for reminders',
          trailing: CupertinoSwitch(
            value: settings?.notificationSound ?? true,
            onChanged: (value) {
              context.read<SettingsBloc>().add(UpdateNotificationSound(value));
            },
            activeTrackColor: AppColors.accent,
          ),
          onTap: () {},
          icon: CupertinoIcons.speaker_2_fill,
        ),
        SettingsTile(
          title: 'Vibration',
          subtitle: 'Vibrate for reminders',
          trailing: CupertinoSwitch(
            value: settings?.notificationVibration ?? true,
            onChanged: (value) {
              context.read<SettingsBloc>().add(
                UpdateNotificationVibration(value),
              );
            },
            activeTrackColor: AppColors.accent,
          ),
          onTap: () {},
          icon: CupertinoIcons.waveform,
        ),
      ],
    );
  }

  Widget _buildDataSection() {
    return SettingsSection(
      title: 'Data Management',
      icon: CupertinoIcons.folder_fill,
      children: [
        SettingsTile(
          title: 'Export Data',
          subtitle: 'Backup your data',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_lastExportTime != null)
                Text(
                  _getTimeSinceExport(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              const SizedBox(width: 8),
              Icon(CupertinoIcons.share, size: 18, color: AppColors.accent),
            ],
          ),
          onTap: _showExportOptions,
          icon: CupertinoIcons.arrow_up_doc,
        ),
        SettingsTile(
          title: 'Import Data',
          subtitle: 'Restore from backup',
          trailing: Icon(
            CupertinoIcons.arrow_down,
            size: 18,
            color: AppColors.accent,
          ),
          onTap: _showImportOptions,
          icon: CupertinoIcons.arrow_down_doc,
        ),
        SettingsTile(
          title: 'Clear All Data',
          subtitle: 'Delete all data',
          trailing: const Icon(
            CupertinoIcons.trash,
            size: 18,
            color: AppColors.error,
          ),
          onTap: _showClearDataConfirmation,
          icon: CupertinoIcons.trash_fill,
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return SettingsSection(
      title: 'About',
      icon: CupertinoIcons.info_circle_fill,
      children: [
        const SettingsInfoTile(
          title: 'Version',
          value: '1.0.0',
          icon: CupertinoIcons.device_phone_portrait,
        ),
        SettingsTile(
          title: 'Send Feedback',
          subtitle: 'Help us improve DayFlow',
          trailing: Icon(
            CupertinoIcons.mail,
            size: 18,
            color: AppColors.accent,
          ),
          onTap: _sendFeedback,
          icon: CupertinoIcons.chat_bubble_fill,
        ),
        SettingsTile(
          title: 'Rate App',
          subtitle: 'Show some love on App Store',
          trailing: const Icon(
            CupertinoIcons.star_fill,
            size: 18,
            color: AppColors.warning,
          ),
          onTap: _rateApp,
          icon: CupertinoIcons.heart_fill,
        ),
      ],
    );
  }

  // Export/Import Methods
  void _showExportOptions() {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => ExportSelectionDialog(
            onExport: _performExport,
            canQuickExport: _exportImportService.canQuickExport,
            lastExportResult: _lastExportResult,
            onQuickReExport: _quickReExport,
          ),
    );
  }

  void _showImportOptions() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => ImportSelectionDialog(onImport: _performImport),
    );
  }

  Future<void> _performExport(ExportConfig config) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      _showLoadingDialog('Preparing export...');

      ExportResult result;

      switch (config.format) {
        case ExportFormat.json:
          result = await _exportImportService.exportAllToJson(
            includeCompletedTasks: config.includeTasks,
            includeHabitInstances: config.includeHabits,
            includeSettings: config.includeSettings,
          );
          break;
        case ExportFormat.csv:
          if (config.includeTasks && !config.includeHabits) {
            result = await _exportImportService.exportTasksOnly(
              ExportFormat.csv,
            );
          } else if (config.includeHabits && !config.includeTasks) {
            result = await _exportImportService.exportHabitsOnly(
              ExportFormat.csv,
            );
          } else {
            // For CSV, we need to export separately and combine
            result = await _exportImportService.exportTasksOnly(
              ExportFormat.csv,
            );
          }
          break;
        case ExportFormat.markdown:
          if (config.includeTasks && !config.includeHabits) {
            result = await _exportImportService.exportTasksOnly(
              ExportFormat.markdown,
            );
          } else if (config.includeHabits && !config.includeTasks) {
            result = await _exportImportService.exportHabitsOnly(
              ExportFormat.markdown,
            );
          } else {
            result = await _exportImportService.exportTasksOnly(
              ExportFormat.markdown,
            );
          }
          break;
      }

      if (mounted) {
        Navigator.pop(context);

        if (result.success) {
          setState(() {
            _lastExportResult = result;
            _lastExportTime = DateTime.now();
          });
          _showExportOptionsDialog(result);
        } else {
          CustomSnackBar.error(context, result.error ?? 'Export failed');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        CustomSnackBar.error(context, 'Export failed: $e');
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _performImport(ImportConfig config) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      String? content;

      if (config.source == ImportSource.file) {
        content = await FileManager.pickFileForImport();
      } else {
        final clipboardData = await Clipboard.getData('text/plain');
        content = clipboardData?.text;
      }

      if (content == null || content.isEmpty) {
        if (mounted) {
          CustomSnackBar.error(
            context,
            config.source == ImportSource.file
                ? 'No file selected'
                : 'Clipboard is empty',
          );
        }
        return;
      }

      final validation = await _exportImportService.validateImport(content);

      if (mounted) {
        if (validation.isValid) {
          _showImportConfirmDialog(content, validation, config);
        } else {
          CustomSnackBar.error(context, 'Invalid data: ${validation.error}');
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.error(context, 'Import failed: $e');
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _processImport(
    String data,
    ImportValidation validation,
    ImportConfig config,
  ) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      _showLoadingDialog('Importing data...');

      ImportResult result;

      if (validation.format == 'csv') {
        // For CSV, determine type based on content or user selection
        result = await _exportImportService.importFromCsv(
          data,
          config.importTasks ? ImportType.tasks : ImportType.habits,
        );
      } else {
        result = await _exportImportService.importFromJson(
          data,
          merge: config.mergeData,
          importTasks: config.importTasks,
          importHabits: config.importHabits,
          importSettings: config.importSettings,
        );
      }

      if (mounted) {
        Navigator.pop(context);

        if (result.success) {
          // Refresh relevant blocs
          if (config.importTasks) {
            context.read<TaskBloc>().add(const LoadTasks());
          }
          if (config.importHabits) {
            context.read<HabitBloc>().add(const LoadHabits());
          }
          if (config.importSettings) {
            context.read<SettingsBloc>().add(const LoadSettings());
          }

          _showImportSuccessDialog(result);
        } else {
          CustomSnackBar.error(context, result.error ?? 'Import failed');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        CustomSnackBar.error(context, 'Import failed: $e');
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _performClearAllData() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      _showLoadingDialog('Creating backup and clearing data...');

      final success = await _exportImportService.clearAllDataWithBackup();

      if (mounted) {
        Navigator.pop(context);

        if (success) {
          context.read<TaskBloc>().add(const LoadTasks());
          context.read<HabitBloc>().add(const LoadHabits());
          context.read<SettingsBloc>().add(const LoadSettings());

          CustomSnackBar.success(context, 'All data cleared (backup saved)');
          context.go('/');
        } else {
          CustomSnackBar.error(context, 'Failed to clear data');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        CustomSnackBar.error(context, 'Failed to clear data');
      }
    } finally {
      _isProcessing = false;
    }
  }

  // Dialog Methods
  void _showLoadingDialog(String message) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => CupertinoAlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CupertinoActivityIndicator(),
                const SizedBox(height: 16),
                Text(message),
              ],
            ),
          ),
    );
  }

  void _showExportOptionsDialog(ExportResult result) {
    showCupertinoDialog(
      context: context,
      builder:
          (dialogContext) => CupertinoAlertDialog(
            title: const Text('Export Ready'),
            content: Text(
              '${result.itemCount} items exported\n'
              'Size: ${result.formattedSize}',
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  final shared = await FileManager.shareExport(result);
                  if (!shared && mounted) {
                    CustomSnackBar.error(context, 'Failed to share');
                  }
                },
                child: const Text('Share'),
              ),
              CupertinoDialogAction(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  final path = await FileManager.saveToDevice(result);
                  if (mounted) {
                    if (path != null) {
                      CustomSnackBar.success(
                        context,
                        'Saved to DayFlow folder',
                      );
                    } else {
                      CustomSnackBar.error(context, 'Failed to save');
                    }
                  }
                },
                child: const Text('Save to Device'),
              ),
            ],
          ),
    );
  }

  void _showImportConfirmDialog(
    String data,
    ImportValidation validation,
    ImportConfig config,
  ) {
    showCupertinoDialog(
      context: context,
      builder:
          (dialogContext) => CupertinoAlertDialog(
            title: const Text('Import Data'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Format: ${validation.format?.toUpperCase()}'),
                Text('Items: ${validation.totalItems}'),
                if (validation.hasTasks) const Text('• Contains tasks'),
                if (validation.hasHabits) const Text('• Contains habits'),
                if (validation.hasSettings) const Text('• Contains settings'),
              ],
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(dialogContext),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _processImport(data, validation, config);
                },
                child: const Text('Import'),
              ),
            ],
          ),
    );
  }

  void _showImportSuccessDialog(ImportResult result) {
    showCupertinoDialog(
      context: context,
      builder:
          (dialogContext) => CupertinoAlertDialog(
            title: const Text('Import Complete'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (result.importedCount != null)
                  Text('✅ Imported: ${result.importedCount}'),
                if (result.failedCount != null && result.failedCount! > 0)
                  Text(
                    '❌ Failed: ${result.failedCount}',
                    style: const TextStyle(color: AppColors.error),
                  ),
              ],
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  context.go('/');
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

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
              Text('• All habits and progress'),
              Text('• All settings'),
              SizedBox(height: 12),
              Text(
                '✅ A backup will be created first',
                style: TextStyle(color: CupertinoColors.systemGreen),
              ),
              SizedBox(height: 8),
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

  // Helper Methods
  String _getTimeSinceExport() {
    if (_lastExportTime == null) return '';

    final difference = DateTime.now().difference(_lastExportTime!);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String _getNotificationTimeText(int minutes) {
    if (minutes == 0) return 'At time';
    if (minutes == 5) return '5 min before';
    if (minutes == 10) return '10 min before';
    if (minutes == 15) return '15 min before';
    if (minutes == 30) return '30 min before';
    if (minutes == 60) return '1 hour before';
    return '$minutes min before';
  }

  void _quickReExport() {
    if (_lastExportResult != null) {
      _showExportOptionsDialog(_lastExportResult!);
      CustomSnackBar.info(context, 'Showing last successful export...');
    }
  }

  // Settings Methods
  void _showAccentColorPicker(String currentColor) {
    AccentColorPicker.show(
      context: context,
      currentColor: currentColor,
      onColorSelected: (colorHex) {
        context.read<SettingsBloc>().add(UpdateAccentColor(colorHex));
      },
    );
  }

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

  void _showNotificationTimePicker(int currentMinutes) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return NotificationTimePicker(
          currentMinutes: currentMinutes,
          onTimeSelected: (minutes) {
            context.read<SettingsBloc>().add(
              UpdateDefaultNotificationTime(minutes),
            );
          },
        );
      },
    );
  }

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

  void _openEmail() async {
    CustomSnackBar.info(context, 'Email integration coming soon!');
  }

  void _copyFeedbackTemplate() async {
    final now = DateTime.now();
    final template = '''
DayFlow Feedback
App Version: 1.0.0
Device: ${Platform.operatingSystem}
Date: ${DateFormat('yyyy-MM-dd HH:mm').format(now)}
---
Feedback Type: [Bug/Feature Request/Other]
Description:
[Your feedback here]
''';

    await Clipboard.setData(ClipboardData(text: template));

    if (mounted) {
      CustomSnackBar.success(context, 'Feedback template copied');
    }
  }

  void _rateApp() {
    showCupertinoDialog(
      context: context,
      builder:
          (dialogContext) => CupertinoAlertDialog(
            title: const Text('Rate DayFlow'),
            content: const Text(
              'Enjoying DayFlow? Your rating helps us improve!',
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Maybe Later'),
              ),
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  CustomSnackBar.info(context, 'Opening app store...');
                },
                child: const Text('Rate Now'),
              ),
            ],
          ),
    );
  }
}
