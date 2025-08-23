import 'package:flutter/cupertino.dart';

/// Options for data management (export/import).
///
/// This widget provides a modal with options for exporting and importing data,
/// with different methods for each operation.
class DataManagementOptions extends StatelessWidget {
  /// Callback function for exporting as JSON.
  final VoidCallback onExportJSON;

  /// Callback function for exporting as CSV.
  final VoidCallback onExportCSV;

  /// Callback function for importing from files.
  final VoidCallback onImportFromFiles;

  /// Callback function for importing from clipboard.
  final VoidCallback onImportFromClipboard;

  const DataManagementOptions({
    super.key,
    required this.onExportJSON,
    required this.onExportCSV,
    required this.onImportFromFiles,
    required this.onImportFromClipboard,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoActionSheet(
      title: const Text('Data Management'),
      message: const Text('Choose an action'),
      actions: [
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context); // Close action sheet.
            onExportJSON(); // Export as JSON.
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
            onExportCSV(); // Export as CSV.
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
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context); // Close action sheet.
            onImportFromFiles(); // Import from files.
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
            onImportFromClipboard(); // Import from clipboard.
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
    );
  }
}
