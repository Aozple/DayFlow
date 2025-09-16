import 'dart:io';
import 'package:dayflow/core/services/export_import_service.dart';
import 'package:dayflow/data/models/app_settings.dart';
import 'package:dayflow/data/repositories/settings_repository.dart';
import 'package:dayflow/data/repositories/task_repository.dart';
import 'package:dayflow/presentation/blocs/tasks/task_bloc.dart';
import 'package:dayflow/presentation/screens/settings/widgets/notification_time_picker.dart';
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
  late final ExportImportService _exportImportService;
  bool _isProcessing = false;
  DateTime? _lastExportTime;
  ExportResult? _lastExportResult;

  @override
  void initState() {
    super.initState();
    _exportImportService = ExportImportService(
      taskRepository: TaskRepository(),
      settingsRepository: SettingsRepository(),
    );
  }

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
        body: SafeArea(
          child: BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, state) {
              if (state is SettingsLoading) {
                return const Center(
                  child: CupertinoActivityIndicator(radius: 20),
                );
              }

              final settings = state is SettingsLoaded ? state.settings : null;

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  const SettingsHeader(),
                  SliverToBoxAdapter(
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
                ],
              );
            },
          ),
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
          subtitle: 'Backup your tasks and notes',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // This is the new part that displays the time
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
          onTap: () => _showExportOptions(),
          icon: CupertinoIcons.arrow_up_doc,
        ),
        SettingsTile(
          title: 'Import Data',
          subtitle: 'Restore from backup file',
          trailing: Icon(
            CupertinoIcons.arrow_down,
            size: 18,
            color: AppColors.accent,
          ),
          onTap: () => _showImportOptions(),
          icon: CupertinoIcons.arrow_down_doc,
        ),
        SettingsTile(
          title: 'Clear All Data',
          subtitle: 'Delete all tasks and notes',
          trailing: const Icon(
            CupertinoIcons.trash,
            size: 18,
            color: AppColors.error,
          ),
          onTap: () => _showClearDataConfirmation(),
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
          onTap: () => _sendFeedback(),
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
          onTap: () => _rateApp(),
          icon: CupertinoIcons.heart_fill,
        ),
      ],
    );
  }

  // Export Options
  void _showExportOptions() {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            title: const Text('Export Data'),
            message: const Text('Choose export format'),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  _exportAsJSON();
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.doc_text, size: 18),
                    SizedBox(width: 8),
                    Text('JSON (Complete Backup)'),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  _exportAsCSV();
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.table, size: 18),
                    SizedBox(width: 8),
                    Text('CSV (Spreadsheet)'),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  _exportAsMarkdown();
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.doc_richtext, size: 18),
                    SizedBox(width: 8),
                    Text('Markdown (Readable)'),
                  ],
                ),
              ),
              // This is the new conditional button
              if (_lastExportResult != null &&
                  _exportImportService.canQuickExport)
                CupertinoActionSheetAction(
                  onPressed: () {
                    Navigator.pop(context);
                    _quickReExport();
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.arrow_counterclockwise, size: 18),
                      SizedBox(width: 8),
                      Text('Re-export Last File'),
                    ],
                  ),
                ),
            ],
            cancelButton: CupertinoActionSheetAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
    );
  }

  void _showImportOptions() {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            title: const Text('Import Data'),
            message: const Text('Choose import source'),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  _importFromFiles();
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.folder, size: 18),
                    SizedBox(width: 8),
                    Text('From Files'),
                  ],
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  _importFromClipboard();
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.doc_on_clipboard, size: 18),
                    SizedBox(width: 8),
                    Text('From Clipboard'),
                  ],
                ),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
    );
  }

  // Export Methods
  Future<void> _exportAsJSON() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      _showLoadingDialog('Preparing export...');

      final result = await _exportImportService.exportToJSON(
        includeCompleted: true,
        includeSettings: true,
      );

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

  Future<void> _exportAsCSV() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      _showLoadingDialog('Preparing CSV export...');

      final result = await _exportImportService.exportToCSV(
        includeCompleted: true,
        includeNotes: true,
      );

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

  Future<void> _exportAsMarkdown() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      _showLoadingDialog('Preparing Markdown export...');

      final result = await _exportImportService.exportToMarkdown(
        includeCompleted: true,
        groupByDate: true,
      );

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

  // Import Methods
  Future<void> _importFromFiles() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final content = await _exportImportService.pickFileForImport();

      if (content != null && mounted) {
        final validation = await _exportImportService.validateImport(content);

        if (mounted) {
          if (validation.isValid) {
            _showImportConfirmDialog(content, validation);
          } else {
            CustomSnackBar.error(context, 'Invalid file: ${validation.error}');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.error(context, 'Failed to read file: $e');
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _importFromClipboard() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final ClipboardData? data = await Clipboard.getData('text/plain');

      if (data?.text?.isEmpty ?? true) {
        if (mounted) {
          CustomSnackBar.error(context, 'Clipboard is empty');
        }
        return;
      }

      final validation = await _exportImportService.validateImport(data!.text!);

      if (mounted) {
        if (validation.isValid) {
          _showImportConfirmDialog(data.text!, validation);
        } else {
          CustomSnackBar.error(context, 'Invalid data in clipboard');
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.error(context, 'Failed to read clipboard');
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _processImport(
    String data,
    ImportValidation validation, {
    bool merge = true,
  }) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      _showLoadingDialog('Importing data...');

      ImportResult result;

      if (validation.format == 'csv') {
        result = await _exportImportService.importFromCSV(data);
      } else {
        result = await _exportImportService.importFromJSON(data, merge: merge);
      }

      if (mounted) {
        Navigator.pop(context);

        if (result.success) {
          context.read<TaskBloc>().add(const LoadTasks());
          if (validation.hasSettings) {
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

      final success = await _exportImportService.clearAllData(
        createBackup: true,
      );

      if (mounted) {
        Navigator.pop(context);

        if (success) {
          context.read<TaskBloc>().add(const LoadTasks());
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
                  final shared = await _exportImportService.shareExport(result);
                  if (!shared && mounted) {
                    CustomSnackBar.error(context, 'Failed to share');
                  }
                },
                child: const Text('Share'),
              ),
              CupertinoDialogAction(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  final path = await _exportImportService.saveToDevice(result);
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

  void _showImportConfirmDialog(String data, ImportValidation validation) {
    showCupertinoDialog(
      context: context,
      builder:
          (dialogContext) => CupertinoAlertDialog(
            title: const Text('Import Data'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Format: ${validation.format?.toUpperCase()}'),
                Text('Items to import: ${validation.totalItems}'),
                if (validation.hasSettings)
                  const Text(
                    '\nIncludes settings',
                    style: TextStyle(fontSize: 12),
                  ),
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
                  _processImport(data, validation, merge: true);
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

  // Other settings methods
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
                  // TODO: Open app store
                  CustomSnackBar.info(context, 'Opening app store...');
                },
                child: const Text('Rate Now'),
              ),
            ],
          ),
    );
  }
}
