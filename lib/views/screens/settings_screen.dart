import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/category.dart';
import '../../models/label.dart';
import '../../models/project.dart';
import '../../utils/app_localizations.dart';
import '../../viewmodels/settings_viewmodel.dart';
import '../../viewmodels/category_viewmodel.dart';
import '../../viewmodels/label_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/note_viewmodel.dart';
import '../../viewmodels/project_viewmodel.dart';
import '../../viewmodels/task_viewmodel.dart';
import '../../services/biometric_service.dart';
import '../../services/export_service.dart';
import '../../services/notification_service.dart';

// Icons users can pick when creating or editing a category. Kept short so
// the dialog stays scannable; expand the list if needed later.
const List<IconData> _kCategoryIcons = [
  Icons.label,
  Icons.work,
  Icons.person,
  Icons.shopping_cart,
  Icons.favorite,
  Icons.school,
  Icons.home,
  Icons.fitness_center,
  Icons.restaurant,
  Icons.flight,
  Icons.book,
  Icons.music_note,
  Icons.attach_money,
  Icons.local_hospital,
  Icons.code,
  Icons.brush,
];

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

          // Categories Management
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: Text(l.get('category')),
            subtitle: Text(
                '${context.watch<CategoryViewModel>().categories.length} ${l.get('categories').toLowerCase()}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showCategoriesManager(context),
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

          // Restore from JSON backup
          ListTile(
            leading: const Icon(Icons.restore_outlined),
            title: Text(l.get('restoreBackup')),
            subtitle: Text(l.get('restoreBackupDesc')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showRestoreDialog(context),
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

          // ---- New-task defaults ----
          ListTile(
            leading: const Icon(Icons.tune),
            title: Text(l.get('newTaskDefaults')),
            subtitle: Text(l.get('newTaskDefaultsDesc')),
            dense: true,
          ),
          // Default priority
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                    child: Text(l.get('priority'),
                        style: theme.textTheme.bodyMedium)),
                SegmentedButton<int>(
                  segments: [
                    ButtonSegment(value: 1, label: Text(l.get('low'))),
                    ButtonSegment(value: 2, label: Text(l.get('priorityMed'))),
                    ButtonSegment(value: 3, label: Text(l.get('high'))),
                  ],
                  selected: {settingsVM.defaultPriority},
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity:
                        VisualDensity(horizontal: -2, vertical: -2),
                  ),
                  onSelectionChanged: (s) =>
                      settingsVM.setDefaultPriority(s.first),
                ),
              ],
            ),
          ),
          // Default reminder offset — preset choices keep this scannable;
          // power users can still set custom reminders per-task.
          ListTile(
            leading: const Icon(Icons.alarm_outlined),
            title: Text(l.get('defaultReminder')),
            subtitle: Text(_reminderOffsetLabel(
                settingsVM.defaultReminderOffsetMinutes, l)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showReminderOffsetPicker(context, settingsVM),
          ),
          // Default category — uses a popup so the list of categories
          // isn't squashed onto a single row.
          Consumer<CategoryViewModel>(
            builder: (ctx, catVM, _) => ListTile(
              leading: const Icon(Icons.category_outlined),
              title: Text(l.get('category')),
              subtitle: Text(settingsVM.defaultCategory),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showDefaultCategoryPicker(
                context,
                settingsVM,
                catVM,
              ),
            ),
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
            subtitle: const Text('Focus24 v1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Focus24',
                applicationVersion: '1.0.0',
                applicationIcon: Icon(
                  Icons.task_alt,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                children: [
                  Text(
                    l.get('appDescription'),
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

  void _showCategoriesManager(BuildContext context) {
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
          final categoryVM = context.watch<CategoryViewModel>();
          final categories = categoryVM.categories;
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
                    Text(l.get('categories'),
                        style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _showCategoryDialog(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  itemCount: categories.length,
                  itemBuilder: (ctx, i) {
                    final cat = categories[i];
                    final isBuiltIn = cat.userId == null;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: cat.color.withValues(alpha: 0.2),
                        child: Icon(cat.icon, color: cat.color),
                      ),
                      title: Text(cat.name),
                      subtitle:
                          isBuiltIn ? Text(l.get('builtIn')) : null,
                      trailing: isBuiltIn
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 20),
                              onPressed: () => context
                                  .read<CategoryViewModel>()
                                  .deleteCategory(cat.id),
                            ),
                      onTap: () =>
                          _showCategoryDialog(context, category: cat),
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

  void _showCategoryDialog(BuildContext context, {TaskCategory? category}) {
    final l = AppLocalizations.of(context);
    final nameCtrl = TextEditingController(text: category?.name ?? '');
    var selectedColorValue =
        category?.color.toARGB32() ?? Project.presetColors[4];
    var selectedIcon = category?.icon ?? _kCategoryIcons.first;
    final isEditing = category != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEditing ? l.get('editCategory') : l.get('addCategory')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: l.get('name'),
                    border: const OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                Text(l.get('icon')),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _kCategoryIcons.map((icon) {
                    final isSelected = icon.codePoint == selectedIcon.codePoint;
                    return GestureDetector(
                      onTap: () =>
                          setDialogState(() => selectedIcon = icon),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Color(selectedColorValue)
                                  .withValues(alpha: 0.2)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Color(selectedColorValue)
                                : Theme.of(context).colorScheme.outline,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: isSelected
                              ? Color(selectedColorValue)
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(l.get('color')),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: Project.presetColors.map((colorVal) {
                    final isSelected = selectedColorValue == colorVal;
                    return GestureDetector(
                      onTap: () => setDialogState(
                          () => selectedColorValue = colorVal),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(colorVal),
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary,
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
                final categoryVM = context.read<CategoryViewModel>();
                final authVM = context.read<AuthViewModel>();
                final uid = authVM.user?.uid;
                if (uid == null) return;

                if (isEditing) {
                  // Reuses the same id so editing a built-in default writes
                  // a custom override that the merge prefers.
                  final updated = TaskCategory(
                    id: category.id,
                    name: name,
                    icon: selectedIcon,
                    color: Color(selectedColorValue),
                    userId: uid,
                  );
                  if (category.userId == null) {
                    // Built-in being customized for the first time → create.
                    categoryVM.addCategory(updated);
                  } else {
                    categoryVM.updateCategory(updated);
                  }
                } else {
                  categoryVM.addCategory(TaskCategory(
                    id: const Uuid().v4(),
                    name: name,
                    icon: selectedIcon,
                    color: Color(selectedColorValue),
                    userId: uid,
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
            ListTile(
              leading: const Icon(Icons.code, color: Colors.blueGrey),
              title: Text(l.get('jsonBackup')),
              subtitle: Text(l.get('jsonBackupDesc')),
              onTap: () async {
                Navigator.pop(ctx);
                final tasks = context.read<TaskViewModel>().tasks;
                final projects = context.read<ProjectViewModel>().projects;
                final labels = context.read<LabelViewModel>().labels;
                final notes = context.read<NoteViewModel>().notes;
                final categories =
                    context.read<CategoryViewModel>().categories;
                final path = await exportService.exportBackupJson(
                  tasks: tasks,
                  projects: projects,
                  labels: labels,
                  notes: notes,
                  categories: categories,
                );
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

  Future<void> _showRestoreDialog(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final exportService = ExportService();
    final backups = await exportService.listBackups();
    if (!context.mounted) return;

    // Offer two paths: pick a JSON file from the OS file picker (covers
    // Drive / Downloads / iCloud Drive etc.) and the in-app backup history
    // produced by Export → JSON backup. Sentinels distinguish "external
    // file picker" from "use this in-app file" so we can branch cleanly
    // without nested dialogs.
    final action = await showDialog<_RestoreSelection>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.get('restoreBackup')),
        children: [
          SimpleDialogOption(
            onPressed: () =>
                Navigator.pop(ctx, const _RestoreSelection.fromFilePicker()),
            child: Row(
              children: [
                const Icon(Icons.folder_open),
                const SizedBox(width: 12),
                Expanded(child: Text(l.get('pickFileFromDevice'))),
              ],
            ),
          ),
          if (backups.isNotEmpty) const Divider(),
          if (backups.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
              child: Text(
                l.get('recentBackups'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ...backups.map((f) {
            final stat = f.statSync();
            final mtime = DateFormat.yMMMd().add_jm().format(stat.modified);
            final sizeKb = (stat.size / 1024).toStringAsFixed(1);
            return SimpleDialogOption(
              onPressed: () =>
                  Navigator.pop(ctx, _RestoreSelection.fromInApp(f)),
              child: Row(
                children: [
                  const Icon(Icons.history),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(mtime),
                        Text(
                          '$sizeKb KB',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
    if (action == null) return; // Dialog dismissed.
    if (!context.mounted) return;

    File? picked;
    if (action.usePicker) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        // Read full bytes only when the OS doesn't expose a direct path
        // (some Android content URIs). The path branch is preferred — it
        // avoids loading the entire file into memory just to write a copy.
      );
      if (result == null) return;
      final p = result.files.single.path;
      if (p == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.get('cantReadFile'))),
        );
        return;
      }
      picked = File(p);
    } else {
      picked = action.inAppFile;
    }
    if (picked == null) return;
    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.get('restoreThisBackup')),
        content: Text(l.get('restoreWarning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.get('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.get('restoreAction')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    final auth = context.read<AuthViewModel>();
    final uid = auth.user?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.get('signInToRestore'))),
      );
      return;
    }

    final taskVM = context.read<TaskViewModel>();
    final projectVM = context.read<ProjectViewModel>();
    final labelVM = context.read<LabelViewModel>();
    final noteVM = context.read<NoteViewModel>();
    final categoryVM = context.read<CategoryViewModel>();

    try {
      final result = await exportService.restoreFromBackupJson(
        path: picked.path,
        userId: uid,
        addTask: taskVM.addTask,
        addProject: projectVM.addProject,
        addLabel: labelVM.addLabel,
        addNote: noteVM.addNote,
        addCategory: categoryVM.addCategory,
        existingTaskIds: taskVM.tasks.map((t) => t.id).toSet(),
        existingProjectIds: projectVM.projects.map((p) => p.id).toSet(),
        existingLabelIds: labelVM.labels.map((l) => l.id).toSet(),
        existingNoteIds: noteVM.notes.map((n) => n.id).toSet(),
        // Includes built-in default ids so old v1 backups containing
        // unfiltered defaults skip them rather than re-creating duplicates.
        existingCategoryIds: categoryVM.categories.map((c) => c.id).toSet(),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.summary())),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l.format('restoreFailed', {'error': e.toString()}))),
      );
    }
  }

  String _reminderOffsetLabel(int? minutes, AppLocalizations l) {
    if (minutes == null) return l.get('reminderOff');
    if (minutes == 0) return l.get('reminderAtDue');
    if (minutes >= 1440 && minutes % 1440 == 0) {
      final days = minutes ~/ 1440;
      return days == 1
          ? l.get('reminderDayBeforeOne')
          : l.format('reminderDayBeforeOther', {'n': days});
    }
    if (minutes >= 60 && minutes % 60 == 0) {
      final hours = minutes ~/ 60;
      return hours == 1
          ? l.get('reminderHourBeforeOne')
          : l.format('reminderHourBeforeOther', {'n': hours});
    }
    return l.format('reminderMinBefore', {'n': minutes});
  }

  Future<void> _showReminderOffsetPicker(
    BuildContext context,
    SettingsViewModel settingsVM,
  ) async {
    final l = AppLocalizations.of(context);
    // Common offsets cover ~95% of realistic defaults. Custom-per-task
    // remains available via the dedicated reminders screen.
    // Wrapper distinguishes a user-chosen "Off" (null) from a dialog-
    // dismiss (no _OffsetPick at all).
    const presets = <int?>[null, 0, 5, 30, 60, 1440];
    final picked = await showDialog<_OffsetPick>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.get('defaultReminder')),
        children: presets
            .map((p) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, _OffsetPick(p)),
                  child: Row(
                    children: [
                      Expanded(child: Text(_reminderOffsetLabel(p, l))),
                      if (p == settingsVM.defaultReminderOffsetMinutes)
                        Icon(Icons.check,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
    if (picked == null) return; // Dialog dismissed without a choice.
    await settingsVM.setDefaultReminderOffsetMinutes(picked.minutes);
  }

  Future<void> _showDefaultCategoryPicker(
    BuildContext context,
    SettingsViewModel settingsVM,
    CategoryViewModel catVM,
  ) async {
    final l = AppLocalizations.of(context);
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.get('defaultCategoryTitle')),
        children: catVM.categories
            .map((c) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, c.name),
                  child: Row(
                    children: [
                      Icon(c.icon, size: 18, color: c.color),
                      const SizedBox(width: 12),
                      Expanded(child: Text(c.name)),
                      if (c.name == settingsVM.defaultCategory)
                        Icon(Icons.check,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
    if (picked == null) return;
    await settingsVM.setDefaultCategory(picked);
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

/// Distinguishes a user-picked null ("Off") from a dialog-dismiss-without-
/// choice in [_showReminderOffsetPicker].
class _OffsetPick {
  final int? minutes;
  const _OffsetPick(this.minutes);
}

/// Restore-source picked from the dialog. Either the user wants the OS
/// file picker (`usePicker == true`) or they tapped a specific in-app
/// backup file.
class _RestoreSelection {
  final bool usePicker;
  final File? inAppFile;

  const _RestoreSelection.fromFilePicker()
      : usePicker = true,
        inAppFile = null;

  const _RestoreSelection.fromInApp(File file)
      : usePicker = false,
        inAppFile = file;
}
