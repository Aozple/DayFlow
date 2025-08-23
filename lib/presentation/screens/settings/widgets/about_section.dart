import 'package:flutter/cupertino.dart';

/// Options for the "About" section.
///
/// This widget provides a modal with options for sending feedback,
/// with different methods for contacting the support team.
class AboutSection extends StatelessWidget {
  /// Callback function for sending email.
  final VoidCallback onSendEmail;

  /// Callback function for copying feedback template.
  final VoidCallback onCopyTemplate;

  const AboutSection({
    super.key,
    required this.onSendEmail,
    required this.onCopyTemplate,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoActionSheet(
      title: const Text('Send Feedback'),
      message: const Text('How would you like to contact us?'),
      actions: [
        CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context); // Close action sheet.
            onSendEmail(); // Open email client.
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
            onCopyTemplate(); // Copy feedback template to clipboard.
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
    );
  }
}
