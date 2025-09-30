import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/presentation/widgets/draggable_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ImportSource { file, clipboard }

class ImportConfig {
  final ImportSource source;
  final bool importTasks;
  final bool importHabits;
  final bool importSettings;
  final bool mergeData;

  ImportConfig({
    required this.source,
    this.importTasks = true,
    this.importHabits = true,
    this.importSettings = true,
    this.mergeData = true,
  });
}

class ImportSelectionDialog extends StatefulWidget {
  final Function(ImportConfig) onImport;

  const ImportSelectionDialog({super.key, required this.onImport});

  static Future<void> show({
    required BuildContext context,
    required Function(ImportConfig) onImport,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ImportSelectionDialog(onImport: onImport),
    );
  }

  @override
  State<ImportSelectionDialog> createState() => _ImportSelectionDialogState();
}

class _ImportSelectionDialogState extends State<ImportSelectionDialog>
    with TickerProviderStateMixin {
  ImportSource _selectedSource = ImportSource.file;
  bool _importTasks = true;
  bool _importHabits = true;
  bool _importSettings = true;
  bool _mergeData = true;

  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  void _handleSourceSelection(ImportSource source) {
    HapticFeedback.lightImpact();
    _scaleController.forward().then((_) => _scaleController.reverse());
    setState(() => _selectedSource = source);
  }

  void _confirmImport() {
    if (!_canImport()) return;

    HapticFeedback.mediumImpact();
    Navigator.pop(context);
    widget.onImport(
      ImportConfig(
        source: _selectedSource,
        importTasks: _importTasks,
        importHabits: _importHabits,
        importSettings: _importSettings,
        mergeData: _mergeData,
      ),
    );
  }

  bool _canImport() {
    return _importTasks || _importHabits || _importSettings;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableModal(
      title: 'Import Data',
      initialHeight: 650,
      minHeight: 500,
      rightAction: _buildImportButton(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSourceSection(),
            const SizedBox(height: 24),

            _buildContentSection(),
            const SizedBox(height: 24),

            _buildMethodSection(),
            const SizedBox(height: 24),

            _buildWarningSection(),
            const SizedBox(height: 72),
          ],
        ),
      ),
    );
  }

  Widget _buildImportButton() {
    final canImport = _canImport();

    return AnimatedScale(
      scale: canImport ? 1.0 : 0.9,
      duration: const Duration(milliseconds: 200),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: canImport ? _confirmImport : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: canImport ? AppColors.accent : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: canImport ? AppColors.accent : AppColors.divider,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _selectedSource == ImportSource.file
                    ? CupertinoIcons.folder
                    : CupertinoIcons.doc_on_clipboard,
                size: 14,
                color: canImport ? Colors.white : AppColors.textTertiary,
              ),
              const SizedBox(width: 6),
              Text(
                'Import',
                style: TextStyle(
                  color: canImport ? Colors.white : AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: CupertinoIcons.arrow_down_doc,
          title: 'Import Source',
          subtitle: 'Where is your backup data?',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildSourceOption(ImportSource.file)),
            const SizedBox(width: 12),
            Expanded(child: _buildSourceOption(ImportSource.clipboard)),
          ],
        ),
      ],
    );
  }

  Widget _buildSourceOption(ImportSource source) {
    final isSelected = _selectedSource == source;
    final info = _getSourceInfo(source);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isSelected ? _scaleAnimation.value : 1.0,
          child: GestureDetector(
            onTap: () => _handleSourceSelection(source),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? AppColors.accent.withAlpha(15)
                        : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.accent : AppColors.divider,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    info['icon'] as IconData,
                    size: 28,
                    color:
                        isSelected ? AppColors.accent : AppColors.textSecondary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    info['title']!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                          isSelected ? AppColors.accent : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    info['subtitle']!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: CupertinoIcons.square_stack_3d_up_fill,
          title: 'What to Import',
          subtitle: 'Select the data you want to import',
        ),
        const SizedBox(height: 16),
        _buildContentToggle(
          'Tasks & Notes',
          'Import all tasks and notes',
          CupertinoIcons.doc_text_fill,
          _importTasks,
          (value) => setState(() => _importTasks = value),
        ),
        _buildContentToggle(
          'Habits & Progress',
          'Import habits and completion history',
          CupertinoIcons.chart_bar_fill,
          _importHabits,
          (value) => setState(() => _importHabits = value),
        ),
        _buildContentToggle(
          'Settings',
          'Import app preferences',
          CupertinoIcons.gear_alt_fill,
          _importSettings,
          (value) => setState(() => _importSettings = value),
        ),
      ],
    );
  }

  Widget _buildMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: CupertinoIcons.arrow_merge,
          title: 'Import Method',
          subtitle: 'How to handle existing data',
        ),
        const SizedBox(height: 16),
        _buildMethodOption(
          'Merge with existing data',
          'Keep current data and add new items',
          CupertinoIcons.plus_circle_fill,
          _mergeData,
          () => setState(() => _mergeData = true),
        ),
        const SizedBox(height: 8),
        _buildMethodOption(
          'Replace all data',
          'Delete current data and import new',
          CupertinoIcons.arrow_2_squarepath,
          !_mergeData,
          () => setState(() => _mergeData = false),
        ),
      ],
    );
  }

  Widget _buildWarningSection() {
    if (_mergeData) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withAlpha(30), width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle_fill,
            size: 20,
            color: AppColors.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data Replacement Warning',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This will permanently delete all your current data. Make sure you have a backup first!',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.error.withAlpha(180),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentToggle(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: value ? AppColors.accent : AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color:
                        value ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.accent,
          ),
        ],
      ),
    );
  }

  Widget _buildMethodOption(
    String title,
    String subtitle,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.accent.withAlpha(10) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? AppColors.accent.withAlpha(50) : AppColors.divider,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.accent : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color:
                          isSelected ? AppColors.accent : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          isSelected
                              ? AppColors.accent.withAlpha(180)
                              : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isSelected ? AppColors.accent : AppColors.textSecondary,
                  width: 2,
                ),
              ),
              child:
                  isSelected
                      ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accent,
                          ),
                        ),
                      )
                      : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 34),
          child: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _getSourceInfo(ImportSource source) {
    switch (source) {
      case ImportSource.file:
        return {
          'title': 'From File',
          'subtitle': 'Select backup file',
          'icon': CupertinoIcons.folder,
        };
      case ImportSource.clipboard:
        return {
          'title': 'From Clipboard',
          'subtitle': 'Paste backup data',
          'icon': CupertinoIcons.doc_on_clipboard,
        };
    }
  }
}
