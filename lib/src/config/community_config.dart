/// Settings a host app passes to `CommunityPackage.init`.
class CommunityConfig {
  const CommunityConfig({required this.backendUrl, required this.appId});

  /// Base URL of the community Worker, without the `/v1` prefix.
  /// For example `https://community-dev.qureshicreatives.workers.dev`.
  final String backendUrl;

  /// The app's ID on the backend: `inventory`, `spacetime` or `money`.
  final String appId;
}
