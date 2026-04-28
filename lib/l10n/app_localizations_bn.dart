// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appName => 'Echo AI';

  @override
  String get chatTab => 'চ্যাট';

  @override
  String get newsTab => 'সংবাদ';

  @override
  String get welcomeTitle => 'হ্যালো, আমি Echo AI';

  @override
  String get welcomeSubtitle => 'একটি প্রশ্ন করুন, ছবি যুক্ত করুন, অথবা শুরু করতে একটি শেখার প্রম্পট বেছে নিন।';

  @override
  String get suggestionPhotosynthesis => 'ফটোসিন্থেসিস ব্যাখ্যা করো';

  @override
  String get suggestionMath => 'গণিতে সাহায্য করো';

  @override
  String get suggestionHistory => 'ইতিহাসে কুইজ নাও';

  @override
  String get suggestionConcept => 'একটি ধারণা ব্যাখ্যা করো';

  @override
  String get newChat => 'নতুন চ্যাট';

  @override
  String get starred => 'স্টার করা';

  @override
  String get projects => 'প্রজেক্ট';

  @override
  String get recents => 'সাম্প্রতিক';

  @override
  String get settings => 'সেটিংস';

  @override
  String get drawerSubtitle => 'আরও দ্রুত শিখুন, অনুবাদ করুন এবং অনুসন্ধান করুন।';

  @override
  String get noStarredChats => 'এখনও কোনো স্টার করা চ্যাট নেই।';

  @override
  String get noProjectsYet => 'এখনও কোনো প্রজেক্ট নেই।';

  @override
  String get noRecentChats => 'এখনও কোনো সাম্প্রতিক চ্যাট নেই।';

  @override
  String get addProject => 'প্রজেক্ট যোগ করুন';

  @override
  String get projectName => 'প্রজেক্টের নাম';

  @override
  String get createProject => 'প্রজেক্ট তৈরি করুন';

  @override
  String get renameProject => 'প্রজেক্টের নাম বদলান';

  @override
  String get renameChat => 'চ্যাটের নাম বদলান';

  @override
  String get rename => 'নাম বদলান';

  @override
  String get delete => 'মুছুন';

  @override
  String get cancel => 'বাতিল';

  @override
  String get save => 'সংরক্ষণ করুন';

  @override
  String get searchHint => 'Echo AI-কে যেকোনো কিছু জিজ্ঞাসা করুন';

  @override
  String get imageAttached => 'ছবি যুক্ত হয়েছে';

  @override
  String get processingImage => 'ছবি প্রক্রিয়াকরণ হচ্ছে...';

  @override
  String get camera => 'ক্যামেরা';

  @override
  String get gallery => 'গ্যালারি';

  @override
  String get send => 'পাঠান';

  @override
  String get attachmentPermissionDenied => 'ছবি যুক্ত করতে অনুমতি দরকার।';

  @override
  String get thinking => 'Echo AI ভাবছে';

  @override
  String get chatNotFound => 'চ্যাট সেশন পাওয়া যায়নি।';

  @override
  String get copy => 'কপি';

  @override
  String get speak => 'শুনুন';

  @override
  String get copiedMessage => 'বার্তাটি কপি হয়েছে।';

  @override
  String get india => 'ভারত';

  @override
  String get technology => 'প্রযুক্তি';

  @override
  String get education => 'শিক্ষা';

  @override
  String get science => 'বিজ্ঞান';

  @override
  String get noNewsAvailable => 'এই মুহূর্তে কোনো সংবাদ নেই।';

  @override
  String get failedToOpenLink => 'নিবন্ধটি খোলা যায়নি।';

  @override
  String get appLanguage => 'অ্যাপের ভাষা';

  @override
  String get voiceLanguage => 'ভয়েস ভাষা';

  @override
  String get theme => 'থিম';

  @override
  String get light => 'লাইট';

  @override
  String get dark => 'ডার্ক';

  @override
  String get system => 'সিস্টেম';

  @override
  String get fontSize => 'ফন্টের আকার';

  @override
  String get volume => 'ভলিউম';

  @override
  String get pitch => 'পিচ';

  @override
  String get speechRate => 'বলার গতি';

  @override
  String get clearAllChats => 'সব চ্যাট মুছুন';

  @override
  String get clearAllChatsConfirm => 'এতে সব সংরক্ষিত চ্যাট সেশন স্থায়ীভাবে মুছে যাবে।';

  @override
  String get storagePath => 'স্টোরেজ পাথ';

  @override
  String get storageUnavailable => 'স্টোরেজ পাথ পাওয়া যায়নি।';

  @override
  String get appVersion => 'অ্যাপ সংস্করণ';

  @override
  String get english => 'ইংরেজি';

  @override
  String get hindi => 'হিন্দি';

  @override
  String get bengali => 'বাংলা';

  @override
  String get imageQuestionFallback => 'গুরুত্বপূর্ণ বিষয়গুলো ব্যাখ্যা করুন।';

  @override
  String get imageOnlyPrompt => 'এই ছবিটি বুঝতে আমাকে সাহায্য করুন।';

  @override
  String get justNow => 'এইমাত্র';

  @override
  String minutesAgo(int count) {
    return '$countমি আগে';
  }

  @override
  String hoursAgo(int count) {
    return '$countঘ আগে';
  }

  @override
  String daysAgo(int count) {
    return '$countদিন আগে';
  }

  @override
  String get retry => 'আবার চেষ্টা করুন';

  @override
  String get noDescriptionAvailable => 'কোনো বর্ণনা পাওয়া যায়নি।';

  @override
  String get startNewChat => 'নতুন চ্যাট শুরু করুন';

  @override
  String get assistantUnavailable => 'আমি এখন Echo AI-তে পৌঁছাতে পারছি না। দয়া করে আপনার Groq API key বা সংযোগ পরীক্ষা করে আবার চেষ্টা করুন।';
}
