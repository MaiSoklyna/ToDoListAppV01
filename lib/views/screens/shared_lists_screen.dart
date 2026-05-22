import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/shared_list.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/shared_list_viewmodel.dart';

class SharedListsScreen extends StatelessWidget {
  const SharedListsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = context.watch<SharedListViewModel>();
    final authVM = context.read<AuthViewModel>();
    final myUid = authVM.user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared lists'),
        actions: [
          IconButton(
            tooltip: 'Join with code',
            icon: const Icon(Icons.input),
            onPressed: () => _showJoinDialog(context),
          ),
        ],
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.lists.isEmpty
              ? _EmptyState(
                  onCreate: () => _showCreateDialog(context),
                  onJoin: () => _showJoinDialog(context),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: vm.lists.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final list = vm.lists[index];
                    final isOwner = myUid != null && list.ownerId == myUid;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            theme.colorScheme.primaryContainer,
                        child: Icon(
                          isOwner ? Icons.workspaces : Icons.group,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      title: Text(list.name),
                      subtitle: Text(
                        '${list.memberIds.length} member'
                        '${list.memberIds.length == 1 ? '' : 's'}'
                        '${isOwner ? ' • Owner' : ''}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showListDetails(context, list),
                      onLongPress: isOwner
                          ? () => _showRenameDialog(context, list)
                          : null,
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New list'),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create shared list'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'List name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              final vm = context.read<SharedListViewModel>();
              final list = await vm.create(name);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (list != null && context.mounted) {
                _showListDetails(context, list);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, SharedList list) {
    final ctrl = TextEditingController(text: list.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename list'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              context.read<SharedListViewModel>().rename(list.id, name);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showJoinDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join with code'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Invite code',
            hintText: 'e.g. AB23CD',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final code = ctrl.text.trim().toUpperCase();
              if (code.isEmpty) return;
              final vm = context.read<SharedListViewModel>();
              final joined = await vm.joinByCode(code);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              messenger.showSnackBar(SnackBar(
                content: Text(joined != null
                    ? 'Joined "${joined.name}"'
                    : 'Invalid invite code'),
              ));
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  void _showListDetails(BuildContext context, SharedList list) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _ListDetailsSheet(listId: list.id),
    );
  }
}

class _ListDetailsSheet extends StatelessWidget {
  final String listId;
  const _ListDetailsSheet({required this.listId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = context.watch<SharedListViewModel>();
    final myUid = context.read<AuthViewModel>().user?.uid;
    final list = vm.getById(listId);

    if (list == null) {
      // List was deleted/left while sheet was open.
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('List no longer available.'),
      );
    }

    final isOwner = myUid != null && list.ownerId == myUid;
    final code = list.inviteCode;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(list.name, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              '${list.memberIds.length} member'
              '${list.memberIds.length == 1 ? '' : 's'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Text('Invite code', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            if (code != null)
              _InviteCodeRow(code: code, listName: list.name)
            else
              Text(
                'Invite code revoked.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            if (isOwner) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      final newCode =
                          await context.read<SharedListViewModel>().regenerateInviteCode(list);
                      if (!context.mounted || newCode == null) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('New code: $newCode')),
                      );
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Regenerate'),
                  ),
                ],
              ),
            ],
            const Divider(height: 32),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                context.push('/shared-lists/${list.id}/activity');
              },
              icon: const Icon(Icons.history),
              label: const Text('View activity'),
            ),
            const SizedBox(height: 12),
            if (isOwner)
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                onPressed: () async {
                  final ok = await _confirm(context,
                      'Delete list?',
                      'All members will lose access. Tasks already created in this list will keep their data but lose the link.');
                  if (!ok || !context.mounted) return;
                  await context.read<SharedListViewModel>().delete(list);
                  if (context.mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete list'),
              )
            else
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                onPressed: () async {
                  final ok = await _confirm(context, 'Leave list?',
                      'You will stop receiving updates from this list.');
                  if (!ok || !context.mounted) return;
                  await context.read<SharedListViewModel>().leave(list);
                  if (context.mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.logout),
                label: const Text('Leave list'),
              ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirm(
      BuildContext context, String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result == true;
  }
}

class _InviteCodeRow extends StatelessWidget {
  final String code;
  final String listName;
  const _InviteCodeRow({required this.code, required this.listName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              code,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
                letterSpacing: 4,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Copy',
            icon: const Icon(Icons.copy),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Code copied')),
              );
            },
          ),
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.share),
            onPressed: () {
              SharePlus.instance.share(ShareParams(
                text: 'Join "$listName" on Focus365 with code: $code',
              ));
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onJoin;
  const _EmptyState({required this.onCreate, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspaces_outline,
                size: 72, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'No shared lists yet',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a list to collaborate with others, or join one with a code.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add),
                  label: const Text('Create list'),
                ),
                OutlinedButton.icon(
                  onPressed: onJoin,
                  icon: const Icon(Icons.input),
                  label: const Text('Join with code'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
