import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../../models/claim_model.dart';
import '../../../theme/app_theme.dart';
import '../../../services/claim_service.dart';
import 'transport_chip.dart';

class SubmitClaimSheet extends StatefulWidget {
  final String userId;
  final String userGrade;
  final Future<void> Function(Map<String, dynamic> args) onSubmit;

  const SubmitClaimSheet({
    super.key,
    required this.userId,
    required this.userGrade,
    required this.onSubmit,
  });

  @override
  State<SubmitClaimSheet> createState() => _SubmitClaimSheetState();
}

class _SubmitClaimSheetState extends State<SubmitClaimSheet> {
  String? _claimType;

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime _claimDate = DateTime.now();

  final _distanceCtrl = TextEditingController();
  final _tollCtrl = TextEditingController();
  final _parkingCtrl = TextEditingController();
  String _transportMode = 'own_vehicle';

  final _amountCtrl = TextEditingController();

  String _destinationType = 'domestic';
  final _distOfficeCtrl = TextEditingController();

  final _nightsCtrl = TextEditingController();
  bool _hasReceipt = true;

  final _daysCtrl = TextEditingController();
  bool _isOvernightStay = true;
  DateTime? _returnDateTime;

  final _overseasTransportCtrl = TextEditingController();
  final _overseasPhoneCtrl = TextEditingController();
  final _overseasLaundryCtrl = TextEditingController();
  final _overseasOtherCtrl = TextEditingController();

  PlatformFile? _pickedFile;
  bool _isSubmitting = false;
  String? _submitError;

  @override
  void dispose() {
    for (final c in [
      _titleCtrl,
      _descCtrl,
      _distanceCtrl,
      _tollCtrl,
      _parkingCtrl,
      _amountCtrl,
      _distOfficeCtrl,
      _nightsCtrl,
      _daysCtrl,
      _overseasTransportCtrl,
      _overseasPhoneCtrl,
      _overseasLaundryCtrl,
      _overseasOtherCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double? get _suggested {
    if (_claimType == 'travel' && _transportMode == 'own_vehicle') {
      final km = double.tryParse(_distanceCtrl.text) ?? 0;
      if (km <= 0) return null;
      final mileage = ClaimPolicyRates.calculateMileage(km);
      final toll = double.tryParse(_tollCtrl.text) ?? 0;
      final parking = double.tryParse(_parkingCtrl.text) ?? 0;
      return mileage + toll + parking;
    }
    if (_claimType == 'accommodation') {
      final nights = int.tryParse(_nightsCtrl.text) ?? 0;
      if (nights <= 0) return null;
      return ClaimPolicyRates.calculateAccommodation(
        grade: widget.userGrade,
        hasReceipt: _hasReceipt,
        nights: nights,
        destination: _destinationType,
      );
    }
    if (_claimType == 'subsistence') {
      final days = int.tryParse(_daysCtrl.text) ?? 0;
      if (days <= 0) return null;
      return ClaimPolicyRates.calculateSubsistence(
        grade: widget.userGrade,
        destination: _destinationType,
        fullDays: days,
        isOvernightStay: _isOvernightStay,
      );
    }
    return null;
  }

  double get _claimedAmount {
    if (_claimType == 'travel' && _transportMode == 'own_vehicle') {
      return _suggested ?? 0;
    }
    if (_claimType == 'accommodation' || _claimType == 'subsistence') {
      return _suggested ?? (double.tryParse(_amountCtrl.text) ?? 0);
    }
    if (_claimType == 'overseas') {
      return (double.tryParse(_overseasTransportCtrl.text) ?? 0) +
          (double.tryParse(_overseasPhoneCtrl.text) ?? 0) +
          (double.tryParse(_overseasLaundryCtrl.text) ?? 0) +
          (double.tryParse(_overseasOtherCtrl.text) ?? 0);
    }
    return double.tryParse(_amountCtrl.text) ?? 0;
  }

  Future<void> _submit() async {
    if (_claimType == null) {
      setState(() => _submitError = 'Please select a claim type.');
      return;
    }
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _submitError = 'Please enter a title.');
      return;
    }
    if (_claimType == 'travel' && _transportMode == 'own_vehicle') {
      if ((double.tryParse(_distanceCtrl.text) ?? 0) <= 0) {
        setState(() => _submitError = 'Please enter a valid distance.');
        return;
      }
    } else if (_claimType == 'accommodation') {
      if ((int.tryParse(_nightsCtrl.text) ?? 0) <= 0) {
        setState(() => _submitError = 'Please enter number of nights.');
        return;
      }
      if ((double.tryParse(_distOfficeCtrl.text) ?? 0) < 70) {
        setState(() => _submitError =
            'Distance from office must be at least 70 km to qualify.');
        return;
      }
    } else if (_claimType == 'subsistence') {
      if ((int.tryParse(_daysCtrl.text) ?? 0) <= 0) {
        setState(() => _submitError = 'Please enter number of days.');
        return;
      }
      if ((double.tryParse(_distOfficeCtrl.text) ?? 0) < 70) {
        setState(() => _submitError =
            'Distance from office must be at least 70 km to qualify.');
        return;
      }
    } else if (_claimType == 'overseas') {
      if (_claimedAmount <= 0) {
        setState(() => _submitError =
            'Please enter at least one overseas expense amount.');
        return;
      }
    } else {
      if ((double.tryParse(_amountCtrl.text) ?? 0) <= 0) {
        setState(() => _submitError = 'Please enter the claimed amount.');
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    String? receiptUrl;
    if (_pickedFile != null && _pickedFile!.bytes != null) {
      try {
        receiptUrl = await ClaimService().uploadReceipt(
          employeeId: widget.userId,
          bytes: _pickedFile!.bytes!,
          fileName: _pickedFile!.name,
        );
      } catch (e) {
        if (mounted) {
          setState(() {
            _submitError =
                'Receipt upload failed: ${e.toString().replaceFirst("Exception: ", "")}';
            _isSubmitting = false;
          });
        }
        return;
      }
    }

    try {
      await widget.onSubmit({
        'claimType': _claimType,
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        'claimDate': _claimDate,
        'amount': _claimedAmount,
        'suggestedAmount': _suggested,
        'receiptUrl': receiptUrl,
        'transportMode': _claimType == 'travel' ? _transportMode : null,
        'distanceKm': _claimType == 'travel' && _transportMode == 'own_vehicle'
            ? double.tryParse(_distanceCtrl.text)
            : null,
        'tollAmount': _claimType == 'travel' && _transportMode == 'own_vehicle'
            ? double.tryParse(_tollCtrl.text)
            : null,
        'parkingAmount':
            _claimType == 'travel' && _transportMode == 'own_vehicle'
                ? double.tryParse(_parkingCtrl.text)
                : null,
        'destinationType':
            (_claimType == 'accommodation' || _claimType == 'subsistence')
                ? _destinationType
                : null,
        'distanceFromOfficeKm':
            (_claimType == 'accommodation' || _claimType == 'subsistence')
                ? double.tryParse(_distOfficeCtrl.text)
                : null,
        'numberOfNights':
            _claimType == 'accommodation' ? int.tryParse(_nightsCtrl.text) : null,
        'hasAccommodationReceipt':
            _claimType == 'accommodation' ? _hasReceipt : null,
        'numberOfDays':
            _claimType == 'subsistence' ? int.tryParse(_daysCtrl.text) : null,
        'isOvernightStay': _claimType == 'subsistence' ? _isOvernightStay : null,
        'returnDateTime': _claimType == 'subsistence' ? _returnDateTime : null,
        'overseasTransportCost': _claimType == 'overseas'
            ? double.tryParse(_overseasTransportCtrl.text)
            : null,
        'overseasPhoneCost': _claimType == 'overseas'
            ? double.tryParse(_overseasPhoneCtrl.text)
            : null,
        'overseasLaundryCost': _claimType == 'overseas'
            ? double.tryParse(_overseasLaundryCtrl.text)
            : null,
        'overseasOtherCost': _claimType == 'overseas'
            ? double.tryParse(_overseasOtherCtrl.text)
            : null,
      });
    } catch (e) {
      if (mounted) {
        setState(() => _submitError =
            e.toString().replaceFirst('Exception: ', ''));
      }
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  Widget _buildTypeSelector() {
    final types = [
      ('travel', Icons.directions_car_rounded, 'Travel'),
      ('accommodation', Icons.hotel_rounded, 'Accommodation'),
      ('subsistence', Icons.restaurant_rounded, 'Subsistence'),
      ('overseas', Icons.flight_rounded, 'Overseas'),
      ('other', Icons.receipt_rounded, 'Other'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((t) {
        final selected = _claimType == t.$1;
        return GestureDetector(
          onTap: () => setState(() {
            _claimType = t.$1;
            _submitError = null;
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppTheme.primary : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: selected
                      ? AppTheme.primary
                      : const Color(0xFFE5E7EB)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(t.$2,
                    size: 16,
                    color: selected ? Colors.white : AppTheme.textMuted),
                const SizedBox(width: 6),
                Text(t.$3,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : AppTheme.textDark)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  List<Widget> _buildTypeFields() {
    if (_claimType == null) return [];
    switch (_claimType) {
      case 'travel':
        return _buildTravelFields();
      case 'accommodation':
        return _buildAccommodationFields();
      case 'subsistence':
        return _buildSubsistenceFields();
      case 'overseas':
        return _buildOverseasFields();
      default:
        return _buildOtherFields();
    }
  }

  List<Widget> _buildTravelFields() {
    return [
      _sectionLabel('Transport Mode'),
      Row(
        children: [
          TransportChip(
              label: 'Own Vehicle',
              value: 'own_vehicle',
              selected: _transportMode == 'own_vehicle',
              onTap: () => setState(() => _transportMode = 'own_vehicle')),
          const SizedBox(width: 8),
          TransportChip(
              label: 'Flight',
              value: 'flight',
              selected: _transportMode == 'flight',
              onTap: () => setState(() => _transportMode = 'flight')),
          const SizedBox(width: 8),
          TransportChip(
              label: 'Public',
              value: 'public_transport',
              selected: _transportMode == 'public_transport',
              onTap: () =>
                  setState(() => _transportMode = 'public_transport')),
        ],
      ),
      const SizedBox(height: 14),
      if (_transportMode == 'own_vehicle') ...[
        _sectionLabel('Distance (km)'),
        _numField(_distanceCtrl, 'e.g. 150',
            onChanged: (_) => setState(() {})),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('Toll (RM)'),
                  _numField(_tollCtrl, '0.00',
                      onChanged: (_) => setState(() {})),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('Parking (RM)'),
                  _numField(_parkingCtrl, '0.00',
                      onChanged: (_) => setState(() {})),
                ],
              ),
            ),
          ],
        ),
        if (_suggested != null) ...[
          const SizedBox(height: 10),
          _policyHint(
              'Mileage + Toll + Parking = RM ${_suggested!.toStringAsFixed(2)}'),
        ],
      ] else ...[
        _sectionLabel('Amount (RM)'),
        _numField(_amountCtrl, '0.00'),
        const SizedBox(height: 6),
        if (_transportMode == 'flight')
          const Text('Economy class only. Receipt required.',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted))
        else
          const Text('Actual cost. Receipt required.',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      ],
    ];
  }

  List<Widget> _buildAccommodationFields() {
    return [
      _sectionLabel('Destination'),
      _buildDestinationSelector(),
      const SizedBox(height: 12),
      _sectionLabel('Distance from Office (km)'),
      _numField(_distOfficeCtrl, 'Must be ≥ 70 km'),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Number of Nights'),
              _numField(_nightsCtrl, 'e.g. 2',
                  isDecimal: false, onChanged: (_) => setState(() {})),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Has Receipt?'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => setState(() => _hasReceipt = !_hasReceipt),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 13),
                  decoration: BoxDecoration(
                      border:
                          Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white),
                  child: Row(
                    children: [
                      Icon(
                          _hasReceipt
                              ? Icons.check_box_rounded
                              : Icons.check_box_outline_blank_rounded,
                          color: AppTheme.primary,
                          size: 20),
                      const SizedBox(width: 6),
                      Text(_hasReceipt ? 'Yes' : 'No',
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.textDark)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ]),
      if (_suggested != null && _suggested! > 0) ...[
        const SizedBox(height: 10),
        _policyHint(
            'Policy rate: RM ${_suggested!.toStringAsFixed(2)} '
            '(${widget.userGrade == "management" ? "Management" : "Executive"} × '
            '${_nightsCtrl.text} night(s))'),
      ] else if (_destinationType != 'domestic') ...[
        const SizedBox(height: 6),
        const Text('Overseas: standard room, actual cost with receipt.',
            style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        const SizedBox(height: 8),
        _sectionLabel('Actual Amount (RM)'),
        _numField(_amountCtrl, '0.00'),
      ],
    ];
  }

  List<Widget> _buildSubsistenceFields() {
    return [
      _sectionLabel('Destination'),
      _buildDestinationSelector(),
      const SizedBox(height: 12),
      _sectionLabel('Distance from Office (km)'),
      _numField(_distOfficeCtrl, 'Must be ≥ 70 km'),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Number of Days'),
              _numField(_daysCtrl, 'e.g. 3',
                  isDecimal: false, onChanged: (_) => setState(() {})),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Stayed Overnight?'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () =>
                    setState(() => _isOvernightStay = !_isOvernightStay),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 13),
                  decoration: BoxDecoration(
                      border:
                          Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white),
                  child: Row(
                    children: [
                      Icon(
                          _isOvernightStay
                              ? Icons.check_box_rounded
                              : Icons.check_box_outline_blank_rounded,
                          color: AppTheme.primary,
                          size: 20),
                      const SizedBox(width: 6),
                      Text(_isOvernightStay ? 'Yes' : 'No (½ rate)',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textDark)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ]),
      const SizedBox(height: 12),
      _sectionLabel('Return Date & Time'),
      GestureDetector(
        onTap: _pickReturnDateTime,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(10),
              color: Colors.white),
          child: Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  size: 18, color: AppTheme.textMuted),
              const SizedBox(width: 8),
              Text(
                _returnDateTime != null
                    ? DateFormat('d MMM yyyy, h:mm a')
                        .format(_returnDateTime!)
                    : 'Select return date & time',
                style: TextStyle(
                    fontSize: 13,
                    color: _returnDateTime != null
                        ? AppTheme.textDark
                        : AppTheme.textMuted),
              ),
            ],
          ),
        ),
      ),
      if (_returnDateTime != null)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            _returnDateTime!.hour >= 17
                ? '✓ After 5 PM — full day allowance applies'
                : '⚠ Before 5 PM — no allowance for this day (policy 13.4.4)',
            style: TextStyle(
                fontSize: 11,
                color: _returnDateTime!.hour >= 17
                    ? AppTheme.success
                    : AppTheme.warning),
          ),
        ),
      if (_suggested != null && _suggested! > 0) ...[
        const SizedBox(height: 10),
        _policyHint(
            'Policy rate: RM ${_suggested!.toStringAsFixed(2)} '
            '(${_isOvernightStay ? "full" : "half"} rate × ${_daysCtrl.text} day(s))'),
      ],
    ];
  }

  List<Widget> _buildOverseasFields() {
    return [
      Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F0FF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.2)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded,
                size: 14, color: Color(0xFF7C3AED)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'All overseas expenses require original receipts/bills. '
                'Enter only the items that apply.',
                style: TextStyle(fontSize: 11, color: Color(0xFF7C3AED)),
              ),
            ),
          ],
        ),
      ),
      _sectionLabel('Transport Costs (RM)'),
      _numField(_overseasTransportCtrl, '0.00',
          onChanged: (_) => setState(() {})),
      const SizedBox(height: 4),
      const Text('To/from destination — flight, taxi, etc.',
          style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      const SizedBox(height: 12),
      _sectionLabel('Official Phone Calls (RM)'),
      _numField(_overseasPhoneCtrl, '0.00',
          onChanged: (_) => setState(() {})),
      const SizedBox(height: 12),
      _sectionLabel('Laundry (RM)'),
      _numField(_overseasLaundryCtrl, '0.00',
          onChanged: (_) => setState(() {})),
      const SizedBox(height: 12),
      _sectionLabel('Other Personal Necessities (RM)'),
      _numField(_overseasOtherCtrl, '0.00',
          onChanged: (_) => setState(() {})),
      if (_claimedAmount > 0) ...[
        const SizedBox(height: 10),
        _policyHint('Total: RM ${_claimedAmount.toStringAsFixed(2)}'),
      ],
    ];
  }

  List<Widget> _buildOtherFields() {
    return [
      _sectionLabel('Amount (RM)'),
      _numField(_amountCtrl, '0.00'),
    ];
  }

  Widget _buildDestinationSelector() {
    final opts = [
      ('domestic', 'Domestic'),
      ('southeast_asia', 'Southeast Asia'),
      ('other_foreign', 'Other Foreign'),
    ];
    return Row(
      children: opts.map((o) {
        final sel = _destinationType == o.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _destinationType = o.$1;
            }),
            child: Container(
              margin:
                  EdgeInsets.only(right: o.$1 != 'other_foreign' ? 6 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: sel ? AppTheme.primary : Colors.white,
                border: Border.all(
                    color: sel
                        ? AppTheme.primary
                        : const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(o.$2,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: sel
                            ? Colors.white
                            : AppTheme.textMuted),
                    textAlign: TextAlign.center),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _pickReturnDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _returnDateTime ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay.fromDateTime(_returnDateTime ?? DateTime.now()),
    );
    if (time == null || !mounted) return;
    setState(() {
      _returnDateTime = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pickReceipt() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;

      if (file.bytes == null && file.path != null) {
        try {
          final bytes = await _readFileBytes(file.path!);
          setState(() => _pickedFile = PlatformFile(
                name: file.name,
                size: bytes.length,
                bytes: bytes,
                path: file.path,
              ));
          return;
        } catch (_) {}
      }

      if (file.bytes == null) {
        if (mounted) {
          setState(() => _submitError =
              'Could not read the selected file. Please try a different file.');
        }
        return;
      }

      setState(() {
        _pickedFile = file;
        _submitError = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _submitError =
            'Could not open file picker: ${e.toString().replaceFirst("Exception: ", "")}');
      }
    }
  }

  Future<Uint8List> _readFileBytes(String path) async {
    final file = await File(path).readAsBytes();
    return file;
  }

  Widget _sectionLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark)));

  Widget _numField(TextEditingController ctrl, String hint,
      {bool isDecimal = true, void Function(String)? onChanged}) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
            isDecimal ? RegExp(r'[\d.]') : RegExp(r'\d'))
      ],
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: AppTheme.textMuted, fontSize: 13),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.primary)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _policyHint(String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: AppTheme.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        const Icon(Icons.check_circle_rounded,
            size: 14, color: AppTheme.success),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.success,
                    fontWeight: FontWeight.w600))),
      ]));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 20),
              const Text('Submit Claim',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark)),
              const SizedBox(height: 20),

              _sectionLabel('Claim Type'),
              _buildTypeSelector(),
              const SizedBox(height: 16),

              if (_claimType != null) ...[
                _sectionLabel('Title'),
                TextField(
                  controller: _titleCtrl,
                  decoration: InputDecoration(
                    hintText: switch (_claimType) {
                      'travel' => 'e.g. Trip to KL office',
                      'accommodation' => 'e.g. Hotel in Johor Bahru',
                      'subsistence' =>
                        'e.g. Outstation Allowance — Penang',
                      _ => 'e.g. Conference registration fee',
                    },
                    hintStyle: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 13),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Color(0xFFE5E7EB))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Color(0xFFE5E7EB))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppTheme.primary)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),

                _sectionLabel('Claim Date'),
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _claimDate,
                      firstDate: DateTime.now()
                          .subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setState(() => _claimDate = d);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                        border: Border.all(
                            color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 16, color: AppTheme.textMuted),
                      const SizedBox(width: 8),
                      Text(DateFormat('d MMM yyyy').format(_claimDate),
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.textDark)),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),

                ..._buildTypeFields(),
                const SizedBox(height: 12),

                _sectionLabel('Description (optional)'),
                TextField(
                  controller: _descCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Additional notes...',
                    hintStyle: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 13),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Color(0xFFE5E7EB))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Color(0xFFE5E7EB))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppTheme.primary)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),

                _sectionLabel('Receipt (optional)'),
                GestureDetector(
                  onTap: _pickReceipt,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: _pickedFile != null
                          ? AppTheme.success.withValues(alpha: 0.06)
                          : Colors.white,
                      border: Border.all(
                        color: _pickedFile != null
                            ? AppTheme.success.withValues(alpha: 0.4)
                            : const Color(0xFFE5E7EB),
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _pickedFile != null
                              ? Icons.check_circle_rounded
                              : Icons.upload_file_rounded,
                          color: _pickedFile != null
                              ? AppTheme.success
                              : AppTheme.textMuted,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _pickedFile != null
                                ? _pickedFile!.name
                                : 'Tap to attach receipt (PDF, JPG, PNG)',
                            style: TextStyle(
                              fontSize: 13,
                              color: _pickedFile != null
                                  ? AppTheme.success
                                  : AppTheme.textMuted,
                              fontWeight: _pickedFile != null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_pickedFile != null)
                          GestureDetector(
                            onTap: () =>
                                setState(() => _pickedFile = null),
                            child: const Icon(Icons.close_rounded,
                                size: 16, color: AppTheme.textMuted),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Please keep the original receipt(s) safe — HR may request them for verification.',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 20),
              ],

              if (_submitError != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                      color: AppTheme.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppTheme.danger.withValues(alpha: 0.3))),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppTheme.danger, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(_submitError!,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.danger,
                                  fontWeight: FontWeight.w500))),
                    ],
                  ),
                ),
              ],

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting || _claimType == null
                      ? null
                      : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    disabledBackgroundColor:
                        AppTheme.primary.withValues(alpha: 0.4),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Submit Claim',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
