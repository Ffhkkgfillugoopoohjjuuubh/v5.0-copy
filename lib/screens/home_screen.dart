import 'package:ai_tutor/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_session.dart';
import '../models/project_model.dart';
import '../providers/chat_provider.dart';
import '../widgets/session_drawer.dart';
import 'chat_screen.dart';
import 'news_screen.dart';
import 'notebook_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      drawer: SessionDrawer(
        onNewChat: () => _openNewChat(context, ref),
        onSelectSession: (session) => _openSession(context, session),
        onSelectProject: (project) => _openProjectChat(context, ref, project),
        onOpenSettings: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const SettingsScreen(),
            ),
          );
        },
      ),
      appBar: AppBar(
        title: Text(l10n.appName),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: <Widget>[
          _ChatLandingView(
            onPromptSelected: (prompt) => _openNewChat(
              context,
              ref,
              initialPrompt: prompt,
            ),
          ),
          const NotebookScreen(),
          const NewsScreen(),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () => _openNewChat(context, ref),
              child: const Icon(Icons.add_comment_outlined),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline),
            selectedIcon: const Icon(Icons.chat_bubble),
            label: l10n.chatTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.book_outlined),
            selectedIcon: const Icon(Icons.book),
            label: 'Notebook',
          ),
          NavigationDestination(
            icon: const Icon(Icons.newspaper_outlined),
            selectedIcon: const Icon(Icons.newspaper_rounded),
            label: l10n.newsTab,
          ),
        ],
      ),
    );
  }

  Future<void> _openNewChat(
    BuildContext context,
    WidgetRef ref, {
    String? initialPrompt,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final session = await ref.read(chatProvider.notifier).createSession(
          name: l10n.newChat,
        );
    if (!context.mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          sessionId: session.id,
          initialPrompt: initialPrompt,
        ),
      ),
    );
  }

  Future<void> _openProjectChat(
    BuildContext context,
    WidgetRef ref,
    ProjectModel project,
  ) async {
    final session = await ref.read(chatProvider.notifier).createSession(
          projectId: project.id,
          name: project.name,
        );
    if (!context.mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(sessionId: session.id),
      ),
    );
  }

  Future<void> _openSession(BuildContext context, ChatSession session) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(sessionId: session.id),
      ),
    );
  }
}

class _ChatLandingView extends StatelessWidget {
  const _ChatLandingView({
    required this.onPromptSelected,
  });

  final ValueChanged<String> onPromptSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final suggestions = <Map<String, dynamic>>[
      {'icon': Icons.lightbulb_outline, 'text': l10n.suggestionPhotosynthesis},
      {'icon': Icons.calculate_outlined, 'text': l10n.suggestionMath},
      {'icon': Icons.history_edu_outlined, 'text': l10n.suggestionHistory},
      {'icon': Icons.science_outlined, 'text': l10n.suggestionGravity},
    ];

    return SafeArea(
      child: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'What do you want to learn today?',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E30) : Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.search,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ask anything...',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.6,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = suggestions[index];
                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          onTap: () => onPromptSelected(suggestion['text'] as String),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: <Widget>[
                                Icon(
                                  suggestion['icon'] as IconData,
                                  color: const Color(0xFF8B5CF6),
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    suggestion['text'] as String,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
