import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_localizations.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    final faqs = [
      _FaqItem(
        question: l.get('faq1Q'),
        answer: l.get('faq1A'),
      ),
      _FaqItem(
        question: l.get('faq2Q'),
        answer: l.get('faq2A'),
      ),
      _FaqItem(
        question: l.get('faq3Q'),
        answer: l.get('faq3A'),
      ),
      _FaqItem(
        question: l.get('faq4Q'),
        answer: l.get('faq4A'),
      ),
      _FaqItem(
        question: l.get('faq5Q'),
        answer: l.get('faq5A'),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l.get('helpSupport'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Quick tips
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline,
                      color: theme.colorScheme.onPrimaryContainer, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.get('quickTips'),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l.get('quickTipsDesc'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // FAQ section
          Text(
            l.get('faq'),
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...faqs.map((faq) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  title: Text(faq.question,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500)),
                  childrenPadding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    Text(faq.answer, style: theme.textTheme.bodyMedium),
                  ],
                ),
              )),
          const SizedBox(height: 20),

          // Contact support
          Text(
            l.get('contactSupport'),
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: Text(l.get('emailSupport')),
                  subtitle: const Text('support@focus24.app'),
                  onTap: () {
                    launchUrl(Uri.parse('mailto:support@focus24.app'));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.feedback_outlined),
                  title: Text(l.get('sendFeedback')),
                  subtitle: Text(l.get('sendFeedbackDesc')),
                  onTap: () => _showFeedbackDialog(context, l),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context, AppLocalizations l) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.get('sendFeedback')),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: l.get('feedbackHint'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.get('cancel')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l.get('feedbackThanks'))),
              );
            },
            child: Text(l.get('send')),
          ),
        ],
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});
}
