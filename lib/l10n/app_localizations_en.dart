// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Echo AI';

  @override
  String get chatTab => 'Chat';

  @override
  String get newsTab => 'News';

  @override
  String get welcomeTitle => 'Hello, I\'m Echo AI';

  @override
  String get welcomeSubtitle => 'Ask a question, attach an image, or pick a learning prompt to get started.';

  @override
  String get suggestionPhotosynthesis => 'Explain photosynthesis';

  @override
  String get suggestionMath => 'Help with math';

  @override
  String get suggestionHistory => 'Quiz me on history';

  @override
  String get suggestionConcept => 'Explain a concept';

  @override
  String get newChat => 'New Chat';

  @override
  String get starred => 'Starred';

  @override
  String get projects => 'Projects';

  @override
  String get recents => 'Recents';

  @override
  String get settings => 'Settings';

  @override
  String get drawerSubtitle => 'Learn, translate, and explore faster.';

  @override
  String get noStarredChats => 'No starred chats yet.';

  @override
  String get noProjectsYet => 'No projects yet.';

  @override
  String get noRecentChats => 'No recent chats yet.';

  @override
  String get addProject => 'Add project';

  @override
  String get projectName => 'Project name';

  @override
  String get createProject => 'Create project';

  @override
  String get renameProject => 'Rename project';

  @override
  String get renameChat => 'Rename chat';

  @override
  String get rename => 'Rename';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get searchHint => 'Ask Echo AI anything';

  @override
  String get imageAttached => 'Image attached';

  @override
  String get processingImage => 'Processing image...';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get send => 'Send';

  @override
  String get attachmentPermissionDenied => 'Permission is needed to attach an image.';

  @override
  String get thinking => 'Echo AI is thinking';

  @override
  String get chatNotFound => 'Chat session not found.';

  @override
  String get copy => 'Copy';

  @override
  String get speak => 'Speak';

  @override
  String get copiedMessage => 'Message copied.';

  @override
  String get india => 'India';

  @override
  String get technology => 'Technology';

  @override
  String get education => 'Education';

  @override
  String get science => 'Science';

  @override
  String get noNewsAvailable => 'No news available right now.';

  @override
  String get failedToOpenLink => 'Couldn\'t open that article.';

  @override
  String get appLanguage => 'App language';

  @override
  String get voiceLanguage => 'Voice language';

  @override
  String get theme => 'Theme';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get system => 'System';

  @override
  String get fontSize => 'Font size';

  @override
  String get volume => 'Volume';

  @override
  String get pitch => 'Pitch';

  @override
  String get speechRate => 'Speech rate';

  @override
  String get clearAllChats => 'Clear all chats';

  @override
  String get clearAllChatsConfirm => 'This will permanently remove every saved chat session.';

  @override
  String get storagePath => 'Storage path';

  @override
  String get storageUnavailable => 'Storage path unavailable.';

  @override
  String get appVersion => 'App version';

  @override
  String get english => 'English';

  @override
  String get hindi => 'Hindi';

  @override
  String get bengali => 'Bengali';

  @override
  String get imageQuestionFallback => 'Please explain the important details.';

  @override
  String get imageOnlyPrompt => 'Help me understand this image.';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String hoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String daysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get retry => 'Retry';

  @override
  String get noDescriptionAvailable => 'No description available.';

  @override
  String get startNewChat => 'Start a new chat';

  @override
  String get assistantUnavailable => 'I couldn\'t reach Echo AI right now. Please check your Groq API key or connection and try again.';
}
