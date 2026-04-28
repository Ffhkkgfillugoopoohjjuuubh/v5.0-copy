// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'Echo AI';

  @override
  String get chatTab => 'चैट';

  @override
  String get newsTab => 'समाचार';

  @override
  String get welcomeTitle => 'नमस्ते, मैं Echo AI हूँ';

  @override
  String get welcomeSubtitle => 'कोई सवाल पूछें, एक चित्र जोड़ें, या शुरुआत के लिए सीखने वाला संकेत चुनें।';

  @override
  String get suggestionPhotosynthesis => 'प्रकाश संश्लेषण समझाओ';

  @override
  String get suggestionMath => 'गणित में मदद करो';

  @override
  String get suggestionHistory => 'इतिहास पर क्विज़ लो';

  @override
  String get suggestionConcept => 'एक अवधारणा समझाओ';

  @override
  String get newChat => 'नई चैट';

  @override
  String get starred => 'स्टार किए गए';

  @override
  String get projects => 'प्रोजेक्ट्स';

  @override
  String get recents => 'हाल के';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get drawerSubtitle => 'तेज़ी से सीखें, अनुवाद करें और खोजें।';

  @override
  String get noStarredChats => 'अभी कोई स्टार की गई चैट नहीं है।';

  @override
  String get noProjectsYet => 'अभी कोई प्रोजेक्ट नहीं है।';

  @override
  String get noRecentChats => 'अभी कोई हाल की चैट नहीं है।';

  @override
  String get addProject => 'प्रोजेक्ट जोड़ें';

  @override
  String get projectName => 'प्रोजेक्ट का नाम';

  @override
  String get createProject => 'प्रोजेक्ट बनाएं';

  @override
  String get renameProject => 'प्रोजेक्ट का नाम बदलें';

  @override
  String get renameChat => 'चैट का नाम बदलें';

  @override
  String get rename => 'नाम बदलें';

  @override
  String get delete => 'हटाएं';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get save => 'सहेजें';

  @override
  String get searchHint => 'Echo AI से कुछ भी पूछें';

  @override
  String get imageAttached => 'चित्र जुड़ा हुआ है';

  @override
  String get processingImage => 'चित्र प्रोसेस हो रहा है...';

  @override
  String get camera => 'कैमरा';

  @override
  String get gallery => 'गैलरी';

  @override
  String get send => 'भेजें';

  @override
  String get attachmentPermissionDenied => 'चित्र जोड़ने के लिए अनुमति चाहिए।';

  @override
  String get thinking => 'Echo AI सोच रहा है';

  @override
  String get chatNotFound => 'चैट सत्र नहीं मिला।';

  @override
  String get copy => 'कॉपी';

  @override
  String get speak => 'सुनें';

  @override
  String get copiedMessage => 'संदेश कॉपी हो गया।';

  @override
  String get india => 'भारत';

  @override
  String get technology => 'तकनीक';

  @override
  String get education => 'शिक्षा';

  @override
  String get science => 'विज्ञान';

  @override
  String get noNewsAvailable => 'अभी कोई समाचार उपलब्ध नहीं है।';

  @override
  String get failedToOpenLink => 'लेख नहीं खुल सका।';

  @override
  String get appLanguage => 'ऐप भाषा';

  @override
  String get voiceLanguage => 'आवाज़ की भाषा';

  @override
  String get theme => 'थीम';

  @override
  String get light => 'लाइट';

  @override
  String get dark => 'डार्क';

  @override
  String get system => 'सिस्टम';

  @override
  String get fontSize => 'फ़ॉन्ट आकार';

  @override
  String get volume => 'आवाज़';

  @override
  String get pitch => 'पिच';

  @override
  String get speechRate => 'बोलने की गति';

  @override
  String get clearAllChats => 'सभी चैट साफ करें';

  @override
  String get clearAllChatsConfirm => 'इससे सभी सहेजे गए चैट सत्र स्थायी रूप से हट जाएंगे।';

  @override
  String get storagePath => 'स्टोरेज पाथ';

  @override
  String get storageUnavailable => 'स्टोरेज पाथ उपलब्ध नहीं है।';

  @override
  String get appVersion => 'ऐप संस्करण';

  @override
  String get english => 'अंग्रेज़ी';

  @override
  String get hindi => 'हिंदी';

  @override
  String get bengali => 'बंगाली';

  @override
  String get imageQuestionFallback => 'कृपया महत्वपूर्ण विवरण समझाएं।';

  @override
  String get imageOnlyPrompt => 'इस चित्र को समझने में मेरी मदद करें।';

  @override
  String get justNow => 'अभी अभी';

  @override
  String minutesAgo(int count) {
    return '$countमि पहले';
  }

  @override
  String hoursAgo(int count) {
    return '$countघं पहले';
  }

  @override
  String daysAgo(int count) {
    return '$countदि पहले';
  }

  @override
  String get retry => 'फिर से कोशिश करें';

  @override
  String get noDescriptionAvailable => 'कोई विवरण उपलब्ध नहीं है।';

  @override
  String get startNewChat => 'नई चैट शुरू करें';

  @override
  String get assistantUnavailable => 'मैं अभी Echo AI तक नहीं पहुँच सका। कृपया अपनी Groq API key या कनेक्शन जांचें और फिर कोशिश करें।';
}
