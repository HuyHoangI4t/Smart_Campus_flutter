class PlatformServerDiscovery {
  static Future<List<String>> getLocalSubnets() async {
    return [];
  }

  static Future<bool> pingTcp(String ip, int port, {int timeoutMs = 450}) async {
    return false;
  }

  static Future<String?> probeUdpBroadcast({
    List<int> ports = const [5055, 5056, 5057, 5088],
    int timeoutMs = 800,
  }) async {
    return null;
  }
}
