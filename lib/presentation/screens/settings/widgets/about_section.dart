import 'package:flutter/cupertino.dart';

class AboutSection extends StatelessWidget {
  final VoidCallback onSendEmail;

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
            Navigator.pop(context);
            onSendEmail();
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
            Navigator.pop(context);
            onCopyTemplate();
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
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
    );
  }
}
