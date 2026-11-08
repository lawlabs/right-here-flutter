class PackageInfo {
  PackageInfo({required this.appName});

  final String appName;

  static Future<PackageInfo> fromPlatform() async {
    return PackageInfo(appName: 'right_here');
  }
}
