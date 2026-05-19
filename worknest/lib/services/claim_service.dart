import 'dart:math';
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
      'Id':           _uuid(),
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
      // Give a friendlier message for the most common setup mistake
      final msg = (e.statusCode == '404' ||
              (e.message.toLowerCase().contains('not found') ||
               e.message.toLowerCase().contains('bucket')))
          ? 'Storage bucket "claim-receipts" not found. '
            'Please create it in your Supabase project → Storage.'
          : e.message;
      throw Exception('Upload failed: $msg');
    }

    debugPrint('[ClaimService] Upload done — getting public URL');

    return _db.storage
        .from('claim-receipts')
        .getPublicUrl(storagePath);
  }

  /// Generate a v4 UUID without an external package.
  String _uuid() {
    final rng = Random.secure();
    final b = List.generate(16, (_) => rng.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40; // version 4
    b[8] = (b[8] & 0x3f) | 0x80; // variant 1
    String hex(List<int> bytes) =>
        bytes.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
    return '${hex(b.sublist(0, 4))}-${hex(b.sublist(4, 6))}-'
        '${hex(b.sublist(6, 8))}-${hex(b.sublist(8, 10))}-'
        '${hex(b.sublist(10, 16))}';
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
