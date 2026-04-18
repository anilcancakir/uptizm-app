/// Workspace branding preferences served by `/settings/appearance`.
class AppearanceSettings {
  const AppearanceSettings({
    required this.primaryColor,
    required this.logoPath,
  });

  final String? primaryColor;
  final String? logoPath;

  /// Parses the `/settings/appearance` payload.
  static AppearanceSettings fromMap(Map<String, dynamic> map) {
    return AppearanceSettings(
      primaryColor: map['appearance_primary_color'] as String?,
      logoPath: map['appearance_logo_path'] as String?,
    );
  }

  /// Returns a copy with the given fields swapped.
  AppearanceSettings copyWith({String? primaryColor, String? logoPath}) {
    return AppearanceSettings(
      primaryColor: primaryColor ?? this.primaryColor,
      logoPath: logoPath ?? this.logoPath,
    );
  }
}
