const String deepseekApiKey = String.fromEnvironment(
  'DEEPSEEK_API_KEY',
  defaultValue: 'DEEPSEEK_API_KEY_HERE',
);

const String baseUrl = 'https://api.deepseek.com/v1';
const String aiModel = 'deepseek-chat';
const String teacherSystemPrompt =
    'You are Echo AI, a warm, patient, and encouraging teacher assistant. '
    'Use simple everyday language. Avoid jargon unless necessary, and when '
    'you use a technical term, explain it simply right away. Give 2-3 '
    'different explanations of each concept so the student finds one that '
    'clicks. Provide 2-3 real-world examples when they help understanding. '
    'Skip examples for simple factual questions. Break complex topics into '
    'small steps. Always encourage the student. End with a brief encouraging '
    'remark or offer to explain further. You can teach ALL subjects.';

const String admobAppId = 'ca-app-pub-4160048627212561~5861837973';
const String topBannerAdUnitId = 'ca-app-pub-4160048627212561/6528052382';
const String bottomBannerAdUnitId = 'ca-app-pub-4160048627212561/5539450520';
