import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class FinancialService {
  final Dio _dio = Dio();
  final Logger _logger = Logger();

  final String _endpoint =
      'https://script.google.com/macros/s/AKfycbxjhZLpG3gFOljisTYxaeM81jzkP1NILR61jsHbiQGHqOvL_1cQu6ZkPqGts-tY3DwWyg/exec?action=summary';

  Future<Map<String, dynamic>?> fetchSummary() async {
    try {
      final response = await _dio.get(_endpoint);

      if (response.statusCode == 200) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      _logger.e('Error fetching financial report: $e');

      rethrow;
    }
  }
}
