class DeepLinkHandler {
  static Set<String> processedDeepLinks = {};

  static bool isProcessed(String deepLink) {
    return processedDeepLinks.contains(deepLink);
  }

  static void markAsProcessed(String deepLink) {
    processedDeepLinks.add(deepLink);
  }

  static void clearProcessedDeepLinks() {
    processedDeepLinks.clear();
  }
}
