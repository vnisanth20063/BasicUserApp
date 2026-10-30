/// Model representing server-provided application version and release metadata.
class AppVersionModel {
  final String latestVersion;
  final int buildNumber;
  final String releaseUrl;
  final String releaseNotes;
  final bool forceUpdate;

  AppVersionModel({
    required this.latestVersion,
    required this.buildNumber,
    required this.releaseUrl,
    required this.releaseNotes,
    this.forceUpdate = false,
  });

  factory AppVersionModel.fromJson(Map<String, dynamic> json) {
    return AppVersionModel(
      latestVersion: json['latestVersion']?.toString() ?? '1.0.0',
      buildNumber: int.tryParse(json['buildNumber']?.toString() ?? '1') ?? 1,
      releaseUrl: json['releaseUrl']?.toString() ?? '',
      releaseNotes: json['releaseNotes']?.toString() ?? '',
      forceUpdate: json['forceUpdate'] == true,
    );
  }

  /// Determines if an update is available by comparing build numbers and semantic versions
  bool isUpdateAvailable(String currentVersion, int currentBuild) {
    if (buildNumber > currentBuild) return true;
    return _compareSemanticVersions(latestVersion, currentVersion) > 0;
  }

  static int _compareSemanticVersions(String v1, String v2) {
    final v1Parts = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final v2Parts = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (int i = 0; i < 3; i++) {
      final p1 = i < v1Parts.length ? v1Parts[i] : 0;
      final p2 = i < v2Parts.length ? v2Parts[i] : 0;
      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }
    return 0;
  }
}

