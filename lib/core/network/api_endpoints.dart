abstract final class ApiEndpoints {
  static const authRegister = '/api/auth/register';
  static const authLogin = '/api/auth/login';
  static const authRefresh = '/api/auth/refresh';
  static const authLogout = '/api/auth/logout';
  static const authForgotPassword = '/api/auth/forgot-password';
  static const authResetPassword = '/api/auth/reset-password';
  static const authVerifyEmail = '/api/auth/verify-email';

  static const currentUser = '/api/users/me';
  static const tasks = '/api/tasks';
  static const habits = '/api/habits';
  static const goals = '/api/goals';
  static const calendarEvents = '/api/calendar/events';
  static const aiChat = '/api/ai/chat';
  static const aiConversations = '/api/ai/conversations';
  static const preferences = '/api/preferences';

  static String task(String id) => '$tasks/$id';
  static String taskComplete(String id) => '$tasks/$id/complete';
  static String habit(String id) => '$habits/$id';
  static String habitComplete(String id) => '$habits/$id/complete';
  static String habitCompletion(String id) => '$habits/$id/completions';
  static String goal(String id) => '$goals/$id';
  static String calendarEvent(String id) => '$calendarEvents/$id';
  static String aiConversationMessages(String id) =>
      '$aiConversations/$id/messages';
}
