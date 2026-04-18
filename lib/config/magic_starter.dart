/// Magic Starter Configuration.
///
/// Auto-generated baseline by the `magic_starter` installer, hand-edited to
/// disable features that conflict with the Uptizm product surface (social
/// login, phone OTP). Feature flags flip Starter-shipped screens on/off;
/// route prefixes control where Starter mounts its auth, team, profile, and
/// notification views inside our app shell.
Map<String, dynamic> get magicStarterConfig => {
  'magic_starter': {
    'features': {
      'teams': true,
      'registration': true,
      'extended_profile': true,
      'profile_photos': true,
      'social_login': false,
      'two_factor': true,
      'sessions': true,
      'phone_otp': false,
      'newsletter': true,
      'notifications': true,
      'email_verification': true,
      'guest_auth': false,
      'timezones': true,
    },
    'auth': {'email': true, 'phone': false},
    'defaults': {'locale': 'en', 'timezone': 'UTC'},
    'supported_locales': ['en', 'tr'],
    'routes': {
      'home': '/',
      'login': '/auth/login',
      'auth_prefix': '/auth',
      'teams_prefix': '/teams',
      'profile_prefix': '/settings',
      'notifications_prefix': '/notifications',
    },
    'legal': {'terms_url': null, 'privacy_url': null},
  },
};
