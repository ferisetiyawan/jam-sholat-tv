import '../../domain/models/app_config.dart';
import '../services/config_remote_service.dart';

/// Single source of truth for the merged runtime [AppConfig].
///
/// Wraps [ConfigRemoteService] which handles remote fetching, event-image
/// asset syncing and the offline SharedPreferences cache fallback.
class ConfigRepository {
  ConfigRepository({ConfigRemoteService? service})
      : _service = service ?? ConfigRemoteService();

  final ConfigRemoteService _service;

  /// Returns the merged app config (remote over local defaults).
  Future<AppConfig> fetchConfig() => _service.fetchRemoteConfig();
}
