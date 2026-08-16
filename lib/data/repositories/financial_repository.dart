import '../../domain/models/financial_summary.dart';
import '../services/financial_service.dart';

/// Single source of truth for the monthly financial (kas) report.
///
/// Transforms the raw API payload from [FinancialService] into a typed
/// [FinancialSummary] domain model.
class FinancialRepository {
  FinancialRepository({FinancialService? service})
      : _service = service ?? FinancialService();

  final FinancialService _service;

  /// Returns the latest monthly financial summary, or `null` when the service
  /// returns no data.
  Future<FinancialSummary?> fetchMonthlySummary() async {
    final data = await _service.fetchSummary();
    if (data == null) return null;
    return FinancialSummary.fromJson(data);
  }
}
