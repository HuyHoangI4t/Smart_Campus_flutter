class PlatformServerDiscovery {
  static Future<List<String>> getLocalSubnets() async {
    return [];
  }

  static Future<bool> pingTcp(String ip, int port, {int timeoutMs = 450}) async {
    return false;
  }
}

