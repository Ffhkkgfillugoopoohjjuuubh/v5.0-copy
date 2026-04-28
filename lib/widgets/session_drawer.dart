import 'package:ai_tutor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_session.dart';
import '../models/project_model.dart';
import '../providers/chat_provider.dart';
import '../providers/projects_provider.dart';

class SessionDrawer extends ConsumerWidget {
  const SessionDrawer({
    super.key,
    required this.onNewChat,
    required this.onSelectSession,
    required this.onSelectProject,
    required this.onOpenSettings,
  });

  final VoidCallback onNewChat;
  final ValueChanged<ChatSession> onSelectSession;
  final ValueChanged<ProjectModel> onSelectProject;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final sessions = ref.watch(chatProvider);
    final projects = ref.watch(projectsProvider);
    final starred = sessions.where((session) => session.isStarred).toList();
    final recents = sessions.where((session) => !session.isStarred).toList();

    return Drawer(
      width: 280,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.appName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.drawerSubtitle,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onNewChat();
                      },
                      icon: const Icon(Icons.add_comment_outlined),
                      label: Text(l10n.newChat),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                children: <Widget>[
                  _SectionTitle(title: l10n.starred),
                  if (starred.isEmpty)
                    _EmptyState(label: l10n.noStarredChats)
                  else
                    ...starred.map(
                      (session) => _SessionTile(
                        session: session,
                        onTap: () {
                          Navigator.of(context).pop();
                          onSelectSession(session);
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      Expanded(child: _SectionTitle(title: l10n.projects)),
                      IconButton(
                        tooltip: l10n.addProject,
                        onPressed: () => _showProjectDialog(context, ref),
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                  if (projects.isEmpty)
                    _EmptyState(label: l10n.noProjectsYet)
                  else
                    ...projects.map(
                      (project) => _ProjectTile(
                        project: project,
                        onTap: () {
                          Navigator.of(context).pop();
                          onSelectProject(project);
                        },
                        onRename: () =>
                            _showProjectDialog(context, ref, project: project),
                        onDelete: () {
                          ref
                              .read(projectsProvider.notifier)
                              .deleteProject(project.id);
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  _SectionTitle(title: l10n.recents),
                  if (recents.isEmpty)
                    _EmptyState(label: l10n.noRecentChats)
                  else
                    ...recents.map(
                      (session) => _SessionTile(
                        session: session,
                        onTap: () {
                          Navigator.of(context).pop();
                          onSelectSession(session);
                        },
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: Text(l10n.settings),
              onTap: () {
                Navigator.of(context).pop();
                onOpenSettings();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showProjectDialog(
    BuildContext context,
    WidgetRef ref, {
    ProjectModel? project,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: project?.name ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(project == null ? l10n.createProject : l10n.renameProject),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(hintText: l10n.projectName),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: Text(project == null ? l10n.createProject : l10n.save),
            ),
          ],
        );
      },
    );

    if (result == null || result.isEmpty) {
      return;
    }

    if (project == null) {
      await ref.read(projectsProvider.notifier).createProject(result);
    } else {
      await ref.read(projectsProvider.notifier).renameProject(project.id, result);
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.onTap,
  });

  final ChatSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(
        session.isStarred ? Icons.star_rounded : Icons.chat_bubble_outline,
        color: session.isStarred ? const Color(0xFF8B5CF6) : null,
      ),
      title: Text(
        session.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        session.messages.isEmpty ? '...' : session.messages.last.content,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
    );
  }
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({
    required this.project,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  final ProjectModel project;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: const Icon(Icons.folder_outlined),
      title: Text(
        project.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'rename') {
            onRename();
          } else if (value == 'delete') {
            onDelete();
          }
        },
        itemBuilder: (context) => <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: 'rename',
            child: Text(l10n.rename),
          ),
          PopupMenuItem<String>(
            value: 'delete',
            child: Text(l10n.delete),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
