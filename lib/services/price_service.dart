import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/price_data.dart';

class PriceService {
  // Base URL for Government Agmarknet API
  static const String _baseUrl =
      'https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070';

  // TODO: Replace with your actual API key from https://data.gov.in
  // After login, go to "Profile" -> "Generate API Key"
  static const String _apiKey = 'YOUR_API_KEY_HERE';

  // Cache to avoid repeated API calls
  static Map<String, List<PriceData>> _cache = {};
  static DateTime? _lastCacheTime;
  static const Duration _cacheDuration = Duration(hours: 1);

  /// Fetch crop price trends from Government Agmarknet API
  ///
  /// [cropName] - Name of the crop (e.g., "Rice", "Wheat", "Tomato")
  /// Returns list of PriceData sorted by date ascending
  Future<List<PriceData>> fetchCropPrices(String cropName) async {
    try {
      // Check cache first
      if (_isCacheValid() && _cache.containsKey(cropName)) {
        print('✅ Returning cached price data for: $cropName');
        return _cache[cropName]!;
      }

      print('📊 Fetching price data for: $cropName');

      // Build API URL with parameters
      final Uri url = Uri.parse(_baseUrl).replace(
        queryParameters: {
          'api-key': _apiKey,
          'format': 'json',
          'limit': '50', // Fetch last 50 records
          'filters[commodity]': cropName,
        },
      );

      print('🌐 API URL: $url');

      // Make HTTP GET request
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        // Extract "records" array from API response
        if (jsonData.containsKey('records') && jsonData['records'] is List) {
          List<dynamic> records = jsonData['records'];
          print('✅ Fetched ${records.length} records');

          // Convert each record to PriceData object
          List<PriceData> priceList = records
              .map(
                (record) => PriceData.fromApi(record as Map<String, dynamic>),
              )
              .where(
                (priceData) => priceData.price > 0,
              ) // Filter out invalid prices
              .toList();

          // Sort by date ascending (oldest to newest)
          priceList.sort((a, b) => a.date.compareTo(b.date));

          // Update cache
          _cache[cropName] = priceList;
          _lastCacheTime = DateTime.now();

          print('✅ Processed ${priceList.length} valid price records');
          return priceList;
        } else {
          print('⚠️ No records found in API response');
          return [];
        }
      } else {
        print('❌ API request failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching crop prices: $e');
      // Return empty list safely on error
      return [];
    }
  }

  /// Check if cache is still valid
  bool _isCacheValid() {
    if (_lastCacheTime == null) return false;
    return DateTime.now().difference(_lastCacheTime!) < _cacheDuration;
  }

  /// Clear cache manually (useful for testing or refresh functionality)
  void clearCache() {
    _cache.clear();
    _lastCacheTime = null;
    print('🗑️ Price cache cleared');
  }

  /// Get cache status for debugging
  String getCacheStatus() {
    if (_lastCacheTime == null) {
      return 'Cache empty';
    }
    final age = DateTime.now().difference(_lastCacheTime!);
    return 'Cache age: ${age.inMinutes} minutes, Items: ${_cache.length}';
  }
}
