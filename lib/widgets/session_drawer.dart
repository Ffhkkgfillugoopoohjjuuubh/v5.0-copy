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
    final sessions = ref.watch(chatProvider);
    final projects = ref.watch(projectsProvider);
    final starred = sessions.where((session) => session.isStarred).toList();
    final recents = <ChatSession>[...sessions]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return Drawer(
      width: 280,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xEE0F0F1A),
          border: Border(
            right: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              _DrawerHeader(
                onNewChat: () {
                  Navigator.of(context).pop();
                  onNewChat();
                },
              ),
              Expanded(
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: <Widget>[
                    _DrawerSection(
                      icon: Icons.star_rounded,
                      title: l10n.starred,
                      children: starred.isEmpty
                          ? <Widget>[_EmptyState(label: l10n.noStarredChats)]
                          : starred
                              .map(
                                (session) => _SessionTile(
                                  session: session,
                                  onTap: () => _selectSession(context, session),
                                  onLongPress: () => _showSessionActions(
                                    context,
                                    ref,
                                    session,
                                    projects,
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                    _DrawerSection(
                      icon: Icons.folder_outlined,
                      title: l10n.projects,
                      trailing: IconButton(
                        tooltip: l10n.addProject,
                        onPressed: () => _showProjectDialog(context, ref),
                        icon: const Icon(Icons.add_rounded, color: Colors.white),
                      ),
                      children: projects.isEmpty
                          ? <Widget>[_EmptyState(label: l10n.noProjectsYet)]
                          : projects
                              .map(
                                (project) => _ProjectTile(
                                  project: project,
                                  sessions: sessions
                                      .where(
                                        (session) =>
                                            session.projectId == project.id,
                                      )
                                      .toList(),
                                  onProjectTap: () {
                                    Navigator.of(context).pop();
                                    onSelectProject(project);
                                  },
                                  onSessionTap: (session) =>
                                      _selectSession(context, session),
                                  onSessionLongPress: (session) =>
                                      _showSessionActions(
                                    context,
                                    ref,
                                    session,
                                    projects,
                                  ),
                                  onRename: () => _showProjectDialog(
                                    context,
                                    ref,
                                    project: project,
                                  ),
                                  onDelete: () => ref
                                      .read(projectsProvider.notifier)
                                      .deleteProject(project.id),
                                ),
                              )
                              .toList(),
                    ),
                    _DrawerSection(
                      icon: Icons.schedule_rounded,
                      title: l10n.recents,
                      children: recents.isEmpty
                          ? <Widget>[_EmptyState(label: l10n.noRecentChats)]
                          : recents
                              .map(
                                (session) => _SessionTile(
                                  session: session,
                                  onTap: () => _selectSession(context, session),
                                  onLongPress: () => _showSessionActions(
                                    context,
                                    ref,
                                    session,
                                    projects,
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined, color: Colors.white),
                title: Text(
                  l10n.settings,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  onOpenSettings();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectSession(BuildContext context, ChatSession session) {
    Navigator.of(context).pop();
    onSelectSession(session);
  }

  Future<void> _showSessionActions(
    BuildContext context,
    WidgetRef ref,
    ChatSession session,
    List<ProjectModel> projects,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(l10n.rename),
                onTap: () => Navigator.of(context).pop('rename'),
              ),
              ListTile(
                leading: Icon(
                  session.isStarred
                      ? Icons.star_outline_rounded
                      : Icons.star_rounded,
                ),
                title: Text(session.isStarred ? l10n.unstar : l10n.star),
                onTap: () => Navigator.of(context).pop('star'),
              ),
              ListTile(
                leading: const Icon(Icons.folder_copy_outlined),
                title: Text(l10n.addToProject),
                onTap: () => Navigator.of(context).pop('project'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(l10n.delete),
                onTap: () => Navigator.of(context).pop('delete'),
              ),
            ],
          ),
        );
      },
    );

    if (!context.mounted || action == null) {
      return;
    }

    switch (action) {
      case 'rename':
        await _showRenameSessionDialog(context, ref, session);
        break;
      case 'star':
        await ref.read(chatProvider.notifier).toggleStar(session.id);
        break;
      case 'project':
        await _showAssignProjectDialog(context, ref, session, projects);
        break;
      case 'delete':
        await ref.read(chatProvider.notifier).deleteSession(session.id);
        break;
    }
  }

  Future<void> _showRenameSessionDialog(
    BuildContext context,
    WidgetRef ref,
    ChatSession session,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: session.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.renameChat),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(hintText: l10n.renameChat),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );

    if (result == null || result.isEmpty) {
      return;
    }

    await ref.read(chatProvider.notifier).renameSession(session.id, result);
  }

  Future<void> _showAssignProjectDialog(
    BuildContext context,
    WidgetRef ref,
    ChatSession session,
    List<ProjectModel> projects,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final projectId = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(l10n.addToProject),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop('__none__'),
              child: Text(l10n.noProject),
            ),
            ...projects.map(
              (project) => SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(project.id),
                child: Text(project.name),
              ),
            ),
          ],
        );
      },
    );

    if (projectId == null) {
      return;
    }

    await ref
        .read(chatProvider.notifier)
        .assignToProject(session.id, projectId == '__none__' ? null : projectId);
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

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.onNewChat});

  final VoidCallback onNewChat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: <Color>[Color(0xFF8B5CF6), Color(0xFFB794F4)],
                  ),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.appName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      l10n.drawerSubtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onNewChat,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF8B5CF6)),
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.newChat),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerSection extends StatelessWidget {
  const _DrawerSection({
    required this.icon,
    required this.title,
    required this.children,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        listTileTheme: const ListTileThemeData(iconColor: Colors.white),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        trailing: trailing,
        children: children,
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.58)),
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.onTap,
    required this.onLongPress,
  });

  final ChatSession session;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: Icon(
        session.isStarred ? Icons.star_rounded : Icons.chat_bubble_outline,
        color: session.isStarred ? const Color(0xFFB794F4) : Colors.white70,
      ),
      title: Text(
        session.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        session.messages.isEmpty ? '...' : session.messages.last.content,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.58)),
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({
    required this.project,
    required this.sessions,
    required this.onProjectTap,
    required this.onSessionTap,
    required this.onSessionLongPress,
    required this.onRename,
    required this.onDelete,
  });

  final ProjectModel project;
  final List<ChatSession> sessions;
  final VoidCallback onProjectTap;
  final ValueChanged<ChatSession> onSessionTap;
  final ValueChanged<ChatSession> onSessionLongPress;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ExpansionTile(
      leading: const Icon(Icons.folder_outlined, color: Colors.white70),
      title: Text(
        project.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white),
      ),
      trailing: PopupMenuButton<String>(
        iconColor: Colors.white,
        onSelected: (value) {
          if (value == 'open') {
            onProjectTap();
          } else if (value == 'rename') {
            onRename();
          } else if (value == 'delete') {
            onDelete();
          }
        },
        itemBuilder: (context) => <PopupMenuEntry<String>>[
          PopupMenuItem<String>(value: 'open', child: Text(l10n.newChat)),
          PopupMenuItem<String>(value: 'rename', child: Text(l10n.rename)),
          PopupMenuItem<String>(value: 'delete', child: Text(l10n.delete)),
        ],
      ),
      children: sessions.isEmpty
          ? <Widget>[_EmptyState(label: l10n.noRecentChats)]
          : sessions
              .map(
                (session) => _SessionTile(
                  session: session,
                  onTap: () => onSessionTap(session),
                  onLongPress: () => onSessionLongPress(session),
                ),
              )
              .toList(),
    );
  }
}
