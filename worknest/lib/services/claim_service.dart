import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/claim_model.dart';

class ClaimService {
  final _db = Supabase.instance.client;

  static const _table = 'ClaimRequests'; // EF Core used PascalCase

  // ── Fetch claim history for an employee ───────────────────────────────────
  Future<List<ClaimModel>> getHistory(String employeeId) async {
    final data = await _db
        .from(_table)
        .select()
        .eq('EmployeeId', employeeId)
        .order('CreatedAt', ascending: false)
        .timeout(const Duration(seconds: 15));

    return (data as List).map((e) => ClaimModel.fromMap(e)).toList();
  }

  // ── Submit a new claim ────────────────────────────────────────────────────
  Future<void> submitClaim({
    required String employeeId,
    required String companyId,
    required String claimType,
    required String title,
    String? description,
    required DateTime claimDate,
    required double amount,
    double? suggestedAmount,
    String? receiptUrl,
    // Travel
    String? transportMode,
    double? distanceKm,
    double? tollAmount,
    double? parkingAmount,
    // Accommodation & Subsistence
    String? destinationType,
    double? distanceFromOfficeKm,
    // Accommodation
    int? numberOfNights,
    bool? hasAccommodationReceipt,
    // Subsistence
    int? numberOfDays,
    bool? isOvernightStay,
    DateTime? returnDateTime,
    // Overseas
    double? overseasTransportCost,
    double? overseasPhoneCost,
    double? overseasLaundryCost,
    double? overseasOtherCost,
  }) async {
    await _db.from(_table).insert({
      'EmployeeId':   employeeId,
      'CompanyId':    companyId,
      'ClaimType':    claimType,
      'Title':        title,
      'Description':  description,
      'ClaimDate':    claimDate.toIso8601String().substring(0, 10),
      'Amount':       amount,
      'SuggestedAmount': suggestedAmount,
      'Status':       'pending',
      'ReceiptUrl':   receiptUrl,
      // Travel
      'TransportMode':  transportMode,
      'DistanceKm':     distanceKm,
      'TollAmount':     tollAmount,
      'ParkingAmount':  parkingAmount,
      // Shared
      'DestinationType':      destinationType,
      'DistanceFromOfficeKm': distanceFromOfficeKm,
      // Accommodation
      'NumberOfNights':          numberOfNights,
      'HasAccommodationReceipt': hasAccommodationReceipt,
      // Subsistence
      'NumberOfDays':    numberOfDays,
      'IsOvernightStay': isOvernightStay,
      'ReturnDateTime':  returnDateTime?.toUtc().toIso8601String(),
      // Overseas
      'OverseasTransportCost': overseasTransportCost,
      'OverseasPhoneCost':     overseasPhoneCost,
      'OverseasLaundryCost':   overseasLaundryCost,
      'OverseasOtherCost':     overseasOtherCost,
    }).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception('Request timed out. Check your connection.'),
    );
  }

  // ── Upload receipt to Supabase Storage ────────────────────────────────────
  Future<String> uploadReceipt({
    required String employeeId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'bin';
    final storagePath =
        '$employeeId/${DateTime.now().millisecondsSinceEpoch}.$ext';

    debugPrint('[ClaimService] Uploading receipt: $storagePath (${bytes.length} bytes)');

    try {
      await _db.storage
          .from('claim-receipts')
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(contentType: _mimeType(ext)),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception(
                'Upload timed out. Check your internet connection.'),
          );
    } on StorageException catch (e) {
      debugPrint('[ClaimService] Storage error: ${e.message} (status: ${e.statusCode})');
      throw Exception('Upload failed: ${e.message}');
    }

    debugPrint('[ClaimService] Upload done — getting public URL');

    return _db.storage
        .from('claim-receipts')
        .getPublicUrl(storagePath);
  }

  String _mimeType(String ext) {
    switch (ext) {
      case 'pdf':  return 'application/pdf';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'png':  return 'image/png';
      default:     return 'application/octet-stream';
    }
  }
}
