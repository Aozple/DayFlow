import 'package:dayflow/core/constants/app_colors.dart';
import 'package:dayflow/core/services/export_import/models/export_import_models.dart';
import 'package:dayflow/presentation/widgets/draggable_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ExportConfig {
  final ExportFormat format;
  final bool includeTasks;
  final bool includeHabits;
  final bool includeSettings;

  ExportConfig({
    required this.format,
    this.includeTasks = true,
    this.includeHabits = true,
    this.includeSettings = true,
  });
}

class ExportSelectionDialog extends StatefulWidget {
  final Function(ExportConfig) onExport;
  final bool canQuickExport;
  final ExportResult? lastExportResult;
  final VoidCallback? onQuickReExport;

  const ExportSelectionDialog({
    super.key,
    required this.onExport,
    this.canQuickExport = false,
    this.lastExportResult,
    this.onQuickReExport,
  });

  static Future<void> show({
    required BuildContext context,
    required Function(ExportConfig) onExport,
    bool canQuickExport = false,
    ExportResult? lastExportResult,
    VoidCallback? onQuickReExport,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => ExportSelectionDialog(
            onExport: onExport,
            canQuickExport: canQuickExport,
            lastExportResult: lastExportResult,
            onQuickReExport: onQuickReExport,
          ),
    );
  }

  @override
  State<ExportSelectionDialog> createState() => _ExportSelectionDialogState();
}

class _ExportSelectionDialogState extends State<ExportSelectionDialog>
    with TickerProviderStateMixin {
  ExportFormat _selectedFormat = ExportFormat.json;
  bool _includeTasks = true;
  bool _includeHabits = true;
  bool _includeSettings = true;

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

  void _handleFormatSelection(ExportFormat format) {
    HapticFeedback.lightImpact();
    _scaleController.forward().then((_) => _scaleController.reverse());
    setState(() => _selectedFormat = format);
  }

  void _confirmExport() {
    if (!_canExport()) return;

    HapticFeedback.mediumImpact();
    Navigator.pop(context);
    widget.onExport(
      ExportConfig(
        format: _selectedFormat,
        includeTasks: _includeTasks,
        includeHabits: _includeHabits,
        includeSettings: _includeSettings,
      ),
    );
  }

  bool _canExport() {
    if (_selectedFormat == ExportFormat.json) {
      return _includeTasks || _includeHabits || _includeSettings;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableModal(
      title: 'Export Data',
      initialHeight: _calculateInitialHeight(),
      minHeight: 400,
      rightAction: _buildExportButton(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.canQuickExport && widget.lastExportResult != null) ...[
              _buildQuickExportSection(),
              const SizedBox(height: 24),
            ],

            _buildFormatSection(),
            const SizedBox(height: 24),

            if (_selectedFormat == ExportFormat.json) ...[
              _buildContentSection(),
              const SizedBox(height: 24),
            ],

            _buildFormatInfoSection(),
            const SizedBox(height: 72),
          ],
        ),
      ),
    );
  }

  double _calculateInitialHeight() {
    double baseHeight = 400;

    if (widget.canQuickExport && widget.lastExportResult != null) {
      baseHeight += 100;
    }

    if (_selectedFormat == ExportFormat.json) {
      baseHeight += 180;
    }

    return baseHeight.clamp(400, 700);
  }

  Widget _buildExportButton() {
    final canExport = _canExport();

    return AnimatedScale(
      scale: canExport ? 1.0 : 0.9,
      duration: const Duration(milliseconds: 200),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: canExport ? _confirmExport : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: canExport ? AppColors.accent : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: canExport ? AppColors.accent : AppColors.divider,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getFormatIcon(_selectedFormat),
                size: 14,
                color: canExport ? Colors.white : AppColors.textTertiary,
              ),
              const SizedBox(width: 6),
              Text(
                'Export',
                style: TextStyle(
                  color: canExport ? Colors.white : AppColors.textTertiary,
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

  Widget _buildQuickExportSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withAlpha(10),
            AppColors.accent.withAlpha(5),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withAlpha(30), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              CupertinoIcons.arrow_counterclockwise,
              size: 18,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Re-export',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Last export: ${widget.lastExportResult!.itemCount} items',
                  style: TextStyle(fontSize: 13, color: AppColors.accent),
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              Navigator.pop(context);
              widget.onQuickReExport?.call();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Re-export',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: CupertinoIcons.doc_text,
          title: 'Export Format',
          subtitle: 'Choose your preferred format',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildFormatOption(ExportFormat.json)),
            const SizedBox(width: 12),
            Expanded(child: _buildFormatOption(ExportFormat.csv)),
            const SizedBox(width: 12),
            Expanded(child: _buildFormatOption(ExportFormat.markdown)),
          ],
        ),
      ],
    );
  }

  Widget _buildFormatOption(ExportFormat format) {
    final isSelected = _selectedFormat == format;
    final info = _getFormatInfo(format);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isSelected ? _scaleAnimation.value : 1.0,
          child: GestureDetector(
            onTap: () => _handleFormatSelection(format),
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
                    _getFormatIcon(format),
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
          icon: CupertinoIcons.square_stack_3d_down_right,
          title: 'Include in Export',
          subtitle: 'Select what data to export',
        ),
        const SizedBox(height: 16),
        _buildContentToggle(
          'Tasks & Notes',
          'All your tasks and notes',
          CupertinoIcons.doc_text_fill,
          _includeTasks,
          (value) => setState(() => _includeTasks = value),
        ),
        _buildContentToggle(
          'Habits & Progress',
          'Habits and completion history',
          CupertinoIcons.chart_bar_fill,
          _includeHabits,
          (value) => setState(() => _includeHabits = value),
        ),
        _buildContentToggle(
          'Settings',
          'App preferences and configuration',
          CupertinoIcons.gear_alt_fill,
          _includeSettings,
          (value) => setState(() => _includeSettings = value),
        ),
      ],
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

  Widget _buildFormatInfoSection() {
    final info = _getFormatInfo(_selectedFormat);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider.withAlpha(40), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.info_circle,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                '${info['title']} Format',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            info['description']!,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
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

  IconData _getFormatIcon(ExportFormat format) {
    switch (format) {
      case ExportFormat.json:
        return CupertinoIcons.doc_text;
      case ExportFormat.csv:
        return CupertinoIcons.table;
      case ExportFormat.markdown:
        return CupertinoIcons.doc_richtext;
    }
  }

  Map<String, String> _getFormatInfo(ExportFormat format) {
    switch (format) {
      case ExportFormat.json:
        return {
          'title': 'JSON',
          'subtitle': 'Complete backup',
          'description':
              'Full data backup with all details. Perfect for importing back to DayFlow or other compatible apps.',
        };
      case ExportFormat.csv:
        return {
          'title': 'CSV',
          'subtitle': 'Spreadsheet',
          'description':
              'Comma-separated values format. Great for opening in Excel, Google Sheets, or other spreadsheet applications.',
        };
      case ExportFormat.markdown:
        return {
          'title': 'Markdown',
          'subtitle': 'Readable',
          'description':
              'Human-readable format perfect for documentation, notes, or sharing. Compatible with most text editors.',
        };
    }
  }
}
