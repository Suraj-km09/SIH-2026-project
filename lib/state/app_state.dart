import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/env_config.dart';
import '../network/api_client.dart';
import '../services/file_service.dart';
import '../services/secure_storage_service.dart';

/// Generic View State for UI widgets.
enum ViewStatus { initial, loading, success, error }

class ViewState<T> {
  final ViewStatus status;
  final T? data;
  final String? errorMessage;

  const ViewState({
    this.status = ViewStatus.initial,
    this.data,
    this.errorMessage,
  });

  bool get isLoading => status == ViewStatus.loading;
  bool get isSuccess => status == ViewStatus.success;
  bool get isError => status == ViewStatus.error;

  ViewState<T> toLoading() => ViewState(status: ViewStatus.loading, data: data);
  ViewState<T> toSuccess(T result) => ViewState(status: ViewStatus.success, data: result);
  ViewState<T> toError(String message) =>
      ViewState(status: ViewStatus.error, data: data, errorMessage: message);
}

// Core Infrastructure Providers
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final fileServiceProvider = Provider<FileService>((ref) {
  return FileService();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// Reactive Environment & API Configuration Provider
final envConfigProvider = NotifierProvider<EnvConfigNotifier, String>(EnvConfigNotifier.new);

class EnvConfigNotifier extends Notifier<String> {
  @override
  String build() => EnvConfig.baseUrl;

  void updateBaseUrl(String url) {
    EnvConfig.setCustomUrl(url);
    ApiClient().updateBaseUrl(url);
    state = url;
  }

  void toggleMockMode(bool enabled) {
    EnvConfig.useMockData = enabled;
  }

  void resetToProduction() {
    EnvConfig.resetToProduction();
    ApiClient().resetToProduction();
    state = EnvConfig.productionBaseUrl;
  }
}
