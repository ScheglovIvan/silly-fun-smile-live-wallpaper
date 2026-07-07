import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'catalog_endpoints.dart';
import 'models/catalog_manifest.dart';

/// Fetches and parses the remote CDN wallpaper manifest.
///
/// This is the network boundary of the catalog data layer: it performs the
/// versioned manifest GET against
/// `cdn.leansoft-ai.com/il07-smilley-ios/data_live_v29_test.json`, decodes the
/// JSON and hands back a [CatalogManifest]. All failure modes (offline, non-200,
/// CORS in the web preview, malformed body, timeout) surface as a thrown
/// [CatalogFetchException] so the repository can fall back to the bundled seed.
class CatalogService {
  CatalogService({http.Client? client, this.timeout = const Duration(seconds: 8)})
      : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  /// GET + parse the remote manifest. Throws [CatalogFetchException] on any
  /// error so callers can fall back to the seed catalog.
  Future<CatalogManifest> fetchManifest() async {
    final url = CatalogEndpoints.manifestUrl();
    late final http.Response res;
    try {
      res = await _client.get(url).timeout(timeout);
    } on TimeoutException {
      throw CatalogFetchException('Manifest request timed out', url: url);
    } catch (e) {
      throw CatalogFetchException('Manifest request failed: $e', url: url);
    }

    if (res.statusCode != 200) {
      throw CatalogFetchException(
        'Manifest returned HTTP ${res.statusCode}',
        url: url,
        statusCode: res.statusCode,
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(res.body);
    } catch (e) {
      throw CatalogFetchException('Manifest was not valid JSON: $e', url: url);
    }

    if (decoded is! Map) {
      throw CatalogFetchException('Manifest JSON was not an object', url: url);
    }

    final manifest = CatalogManifest.fromJson(decoded.cast<String, dynamic>());
    if (manifest.isEmpty) {
      throw CatalogFetchException('Manifest contained no catalog data',
          url: url);
    }
    return manifest;
  }

  void dispose() => _client.close();
}

/// Raised when the remote catalog manifest cannot be fetched or parsed.
class CatalogFetchException implements Exception {
  CatalogFetchException(this.message, {this.url, this.statusCode});

  final String message;
  final Uri? url;
  final int? statusCode;

  @override
  String toString() => 'CatalogFetchException($message'
      '${url != null ? ', url: $url' : ''}'
      '${statusCode != null ? ', status: $statusCode' : ''})';
}
