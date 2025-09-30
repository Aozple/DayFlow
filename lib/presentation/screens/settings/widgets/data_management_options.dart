import 'package:flutter/cupertino.dart';

class DataManagementOptions extends StatelessWidget {
  final VoidCallback onExportJSON;

  final VoidCallback onExportCSV;

  final VoidCallback onImportFromFiles;

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
            Navigator.pop(context); 
            onExportJSON(); 
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
            Navigator.pop(context); 
            onExportCSV(); 
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
            Navigator.pop(context); 
            onImportFromFiles(); 
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
            Navigator.pop(context); 
            onImportFromClipboard(); 
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
        onPressed: () => Navigator.pop(context), 
        child: const Text('Cancel'),
      ),
    );
  }
}
