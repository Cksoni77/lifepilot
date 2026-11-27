class UserPreferences {
  const UserPreferences({
    this.theme = 'system',
    this.notificationsEnabled = true,
    this.reminderEnabled = true,
  });

  final String theme;
  final bool notificationsEnabled;
  final bool reminderEnabled;
}
