import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/label.dart';
import '../../models/project.dart';
import '../../utils/app_localizations.dart';
import '../../viewmodels/settings_viewmodel.dart';
import '../../viewmodels/label_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/task_viewmodel.dart';
import '../../services/biometric_service.dart';
import '../../services/export_service.dart';
import '../../services/notification_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final settingsVM = context.watch<SettingsViewModel>();

    return Scaffold(
      appBar: AppBar(title: Text(l.get('settings'))),
      body: ListView(
        children: [
          // Theme Mode
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(l.get('theme')),
            subtitle: Text(_themeLabel(settingsVM.themeMode, l)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text(l.get('lightMode')),
                  icon: const Icon(Icons.light_mode),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text(l.get('systemDefault')),
                  icon: const Icon(Icons.settings_brightness),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text(l.get('darkMode')),
                  icon: const Icon(Icons.dark_mode),
                ),
              ],
              selected: {settingsVM.themeMode},
              onSelectionChanged: (s) => settingsVM.setThemeMode(s.first),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),

          // Language
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l.get('language')),
            subtitle: Text(settingsVM.locale.languageCode == 'km'
                ? 'ខ្មែរ (Khmer)'
                : 'English'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'en',
                  label: Text(l.get('english')),
                  icon: const Text('EN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
                ButtonSegment(
                  value: 'km',
                  label: Text(l.get('khmer')),
                  icon: const Text('ខ្មែរ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ],
              selected: {settingsVM.locale.languageCode},
              onSelectionChanged: (s) =>
                  settingsVM.setLocale(Locale(s.first)),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),

          // Labels Management
          ListTile(
            leading: const Icon(Icons.label_outline),
            title: Text(l.get('labels')),
            subtitle: Text('${context.watch<LabelViewModel>().labels.length} ${l.get('labels').toLowerCase()}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLabelsManager(context),
          ),
          const Divider(),

          // Biometric Lock
          FutureBuilder<bool>(
            future: BiometricService().isAvailable(),
            builder: (context, snapshot) {
              if (snapshot.data != true) return const SizedBox.shrink();
              return Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.fingerprint),
                    title: Text(l.get('biometricLock')),
                    subtitle: Text(l.get('biometricLockDesc')),
                    value: settingsVM.biometricEnabled,
                    onChanged: (v) => settingsVM.setBiometricEnabled(v),
                  ),
                  const Divider(),
                ],
              );
            },
          ),

          // Export
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: Text(l.get('exportData')),
            subtitle: Text(l.get('exportDataDesc')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showExportDialog(context),
          ),
          const Divider(),

          // Notifications
          FutureBuilder<bool>(
            future: Future.value(NotificationService().permissionGranted),
            builder: (context, snapshot) {
              final granted = snapshot.data ?? false;
              return SwitchListTile(
                secondary: const Icon(Icons.notifications_outlined),
                title: Text(l.get('notifications')),
                subtitle: Text(granted
                    ? l.get('notificationsEnabled')
                    : l.get('notificationsDisabled')),
                value: settingsVM.notificationsEnabled,
                onChanged: (v) async {
                  if (v && !granted) {
                    await NotificationService().requestPermission();
                  }
                  settingsVM.setNotificationsEnabled(v);
                },
              );
            },
          ),
          const Divider(),

          // Data Protection
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: Text(l.get('dataProtection')),
            subtitle: Text(l.get('dataProtectionDesc')),
            trailing: const Icon(Icons.verified_user, color: Colors.green),
          ),
          const Divider(),

          // Help & Support
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: Text(l.get('helpSupport')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/help'),
          ),
          const Divider(),

          // About
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l.get('about')),
            subtitle: const Text('TaskMaster Pro v1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'TaskMaster Pro',
                applicationVersion: '1.0.0',
                applicationIcon: Icon(
                  Icons.task_alt,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                children: [
                  Text(
                    'A full-featured task management app with Firebase integration, offline support, and multi-language support.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showLabelsManager(BuildContext context) {
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, scrollCtrl) {
          final labelVM = context.watch<LabelViewModel>();
          final labels = labelVM.labels;
          return Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(l.get('labels'),
                        style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _showLabelDialog(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: labels.isEmpty
                    ? Center(child: Text(l.get('noProjectsYet')))
                    : ListView.builder(
                        controller: scrollCtrl,
                        itemCount: labels.length,
                        itemBuilder: (ctx, i) {
                          final label = labels[i];
                          return ListTile(
                            leading: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: label.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            title: Text(label.name),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () =>
                                  labelVM.deleteLabel(label.id),
                            ),
                            onTap: () =>
                                _showLabelDialog(context, label: label),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLabelDialog(BuildContext context, {Label? label}) {
    final l = AppLocalizations.of(context);
    final nameCtrl = TextEditingController(text: label?.name ?? '');
    int selectedColor = label?.colorValue ?? Project.presetColors[4];
    final isEditing = label != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEditing ? l.get('editLabel') : l.get('addLabel')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: l.get('labelName'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: Project.presetColors.map((colorVal) {
                  final isSelected = selectedColor == colorVal;
                  return GestureDetector(
                    onTap: () =>
                        setDialogState(() => selectedColor = colorVal),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(colorVal),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 3)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              size: 16, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.get('cancel')),
            ),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;

                final labelVM = context.read<LabelViewModel>();
                final authVM = context.read<AuthViewModel>();

                if (isEditing) {
                  label.name = name;
                  label.colorValue = selectedColor;
                  labelVM.updateLabel(label);
                } else {
                  labelVM.addLabel(Label(
                    id: const Uuid().v4(),
                    name: name,
                    colorValue: selectedColor,
                    userId: authVM.user?.uid,
                  ));
                }
                Navigator.pop(ctx);
              },
              child: Text(l.get('save')),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    final l = AppLocalizations.of(context);
    final exportService = ExportService();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.get('exportData')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('PDF'),
              subtitle: Text(l.get('exportPdfDesc')),
              onTap: () async {
                Navigator.pop(ctx);
                final tasks = context.read<TaskViewModel>().tasks;
                final path = await exportService.exportToPdf(tasks);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l.get('exportSuccess')),
                      action: SnackBarAction(
                        label: l.get('open'),
                        onPressed: () => exportService.openFile(path),
                      ),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('CSV'),
              subtitle: Text(l.get('exportCsvDesc')),
              onTap: () async {
                Navigator.pop(ctx);
                final tasks = context.read<TaskViewModel>().tasks;
                final path = await exportService.exportToCsv(tasks);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l.get('exportSuccess')),
                      action: SnackBarAction(
                        label: l.get('open'),
                        onPressed: () => exportService.openFile(path),
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.get('cancel')),
          ),
        ],
      ),
    );
  }

  String _themeLabel(ThemeMode mode, AppLocalizations l) {
    switch (mode) {
      case ThemeMode.light:
        return l.get('lightMode');
      case ThemeMode.dark:
        return l.get('darkMode');
      default:
        return l.get('systemDefault');
    }
  }
}
