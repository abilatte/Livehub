class VersionUtils {
  static String buildDisplayVersion(String version) {
    if (version.isEmpty) {
      return "";
    }
    if (version.startsWith('v')) {
      return version;
    }
    return "v$version";
  }

  static String buildDetailedVersion(String version, String buildNumber) {
    if (buildNumber.isEmpty) {
      return version;
    }
    return "$version+$buildNumber";
  }
}
