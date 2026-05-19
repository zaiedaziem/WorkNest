import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/user_model.dart';
import '../../models/company_model.dart';
import '../../models/claim_model.dart';
import '../../viewmodels/claim_viewmodel.dart';
import '../../services/claim_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/haptic_refresh_indicator.dart';

class ClaimsScreen extends StatefulWidget {
  final UserModel user;
  final CompanyModel company;

  const ClaimsScreen({super.key, required this.user, required this.company});

  @override
  State<ClaimsScreen> createState() => _ClaimsScreenState();
}

class _ClaimsScreenState extends State<ClaimsScreen> {
  late ClaimViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ClaimViewModel(user: widget.user, company: widget.company);
    _viewModel.addListener(_onChanged);
    _viewModel.loadData();
  }

  void _onChanged() {
    if (!mounted) return;
    if (_viewModel.successMessage != null) {
      _snack(_viewModel.successMessage!, isError: false);
      _viewModel.clearMessages();
    } else if (_viewModel.errorMessage != null) {
      _snack(_viewModel.errorMessage!, isError: true);
      _viewModel.clearMessages();
    }
    setState(() {});
  }

  void _snack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.danger : AppTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onChanged);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSubmitSheet,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Submit Claim',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('My Claims',
              style: TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          Text(DateFormat('MMMM yyyy').format(DateTime.now()),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
          const SizedBox(height: 16),
          // Stats row
          Row(
            children: [
              _HeaderStat(
                  label: 'Pending', value: '${_viewModel.pendingCount}', color: Colors.amber),
              const SizedBox(width: 16),
              _HeaderStat(
                  label: 'Approved', value: '${_viewModel.approvedCount}', color: Colors.greenAccent),
              const SizedBox(width: 16),
              _HeaderStat(
                  label: 'Total (RM)',
                  value: _viewModel.totalApproved.toStringAsFixed(2),
                  color: Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (_viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (_viewModel.history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded,
                size: 64, color: AppTheme.textMuted.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text('No claims yet',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
            const SizedBox(height: 6),
            const Text('Tap "Submit Claim" to get started',
                style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
          ],
        ),
      );
    }

    return HapticRefreshIndicator(
      onRefresh: _viewModel.loadData,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        itemCount: _viewModel.history.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _ClaimCard(claim: _viewModel.history[i]),
      ),
    );
  }

  // ── Submit Sheet ───────────────────────────────────────────────────────────
  void _showSubmitSheet() {
    final nav = Navigator.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _SubmitClaimSheet(
        userId:    widget.user.id,
        userGrade: widget.user.grade,
        onSubmit: (args) async {
          final success = await _viewModel.submitClaim(
            claimType:    args['claimType'],
            title:        args['title'],
            description:  args['description'],
            claimDate:    args['claimDate'],
            amount:       args['amount'],
            suggestedAmount:     args['suggestedAmount'],
            receiptUrl:          args['receiptUrl'],
            transportMode:       args['transportMode'],
            distanceKm:          args['distanceKm'],
            tollAmount:          args['tollAmount'],
            parkingAmount:       args['parkingAmount'],
            destinationType:     args['destinationType'],
            distanceFromOfficeKm: args['distanceFromOfficeKm'],
            numberOfNights:          args['numberOfNights'],
            hasAccommodationReceipt: args['hasAccommodationReceipt'],
            numberOfDays:    args['numberOfDays'],
            isOvernightStay: args['isOvernightStay'],
            returnDateTime:  args['returnDateTime'],
            overseasTransportCost: args['overseasTransportCost'],
            overseasPhoneCost:     args['overseasPhoneCost'],
            overseasLaundryCost:   args['overseasLaundryCost'],
            overseasOtherCost:     args['overseasOtherCost'],
          );
          if (!success) {
            throw Exception(_viewModel.errorMessage ?? 'Failed to submit.');
          }
          nav.pop();
        },
      ),
    );
  }
}

// ── Header Stat ───────────────────────────────────────────────────────────────
class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _HeaderStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
        Text(label,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
      ],
    );
  }
}

// ── Claim Card ────────────────────────────────────────────────────────────────
class _ClaimCard extends StatelessWidget {
  final ClaimModel claim;
  const _ClaimCard({required this.claim});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (claim.status) {
      'approved' => AppTheme.success,
      'rejected' => AppTheme.danger,
      _          => AppTheme.warning,
    };
    final typeColor = switch (claim.claimType) {
      'travel'        => const Color(0xFF0891B2),
      'accommodation' => const Color(0xFF4361EE),
      'subsistence'   => const Color(0xFFF97316),
      _               => AppTheme.textMuted,
    };
    final typeIcon = switch (claim.claimType) {
      'travel'        => Icons.directions_car_rounded,
      'accommodation' => Icons.hotel_rounded,
      'subsistence'   => Icons.restaurant_rounded,
      _               => Icons.receipt_rounded,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(typeIcon, color: typeColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(claim.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppTheme.textDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(claim.typeLabel,
                        style: TextStyle(fontSize: 11, color: typeColor,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3))),
                child: Text(
                  claim.status[0].toUpperCase() + claim.status.substring(1),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 12, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Text(DateFormat('d MMM yyyy').format(claim.claimDate),
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              const Spacer(),
              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (claim.status == 'approved' && claim.approvedAmount != null)
                    Text('RM ${claim.approvedAmount!.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.success)),
                  Text(
                    claim.status == 'approved' && claim.approvedAmount != null
                        ? 'Claimed: RM ${claim.amount.toStringAsFixed(2)}'
                        : 'RM ${claim.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: claim.status == 'approved' && claim.approvedAmount != null
                            ? 11
                            : 15,
                        fontWeight: claim.status == 'approved' && claim.approvedAmount != null
                            ? FontWeight.normal
                            : FontWeight.w800,
                        color: claim.status == 'approved' && claim.approvedAmount != null
                            ? AppTheme.textMuted
                            : (claim.exceedsPolicy ? AppTheme.warning : AppTheme.textDark))),
                  if (claim.suggestedAmount != null && claim.status != 'approved')
                    Text('Policy: RM ${claim.suggestedAmount!.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                ],
              ),
            ],
          ),
          if (claim.exceedsPolicy) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 12, color: AppTheme.warning),
                const SizedBox(width: 4),
                const Text('Amount exceeds policy rate — pending HR review',
                    style: TextStyle(fontSize: 11, color: AppTheme.warning)),
              ],
            ),
          ],
          if (claim.receiptUrl != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.attach_file_rounded, size: 12, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                const Text('Receipt attached',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ],
          if (claim.rejectionReason != null && claim.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.comment_rounded, size: 12, color: AppTheme.danger),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('HR: ${claim.rejectionReason}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.danger,
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Submit Claim Sheet ────────────────────────────────────────────────────────
class _SubmitClaimSheet extends StatefulWidget {
  final String userId;
  final String userGrade;
  final Future<void> Function(Map<String, dynamic> args) onSubmit;

  const _SubmitClaimSheet({
    required this.userId,
    required this.userGrade,
    required this.onSubmit,
  });

  @override
  State<_SubmitClaimSheet> createState() => _SubmitClaimSheetState();
}

class _SubmitClaimSheetState extends State<_SubmitClaimSheet> {
  // Step 1 — choose type
  String? _claimType;

  // Common
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  DateTime _claimDate = DateTime.now();

  // Travel — own vehicle
  final _distanceCtrl = TextEditingController();
  final _tollCtrl     = TextEditingController();
  final _parkingCtrl  = TextEditingController();
  String _transportMode = 'own_vehicle';

  // Travel (flight/public) / Other — manual amount
  final _amountCtrl = TextEditingController();

  // Accommodation & Subsistence shared
  String _destinationType = 'domestic';
  final _distOfficeCtrl = TextEditingController();

  // Accommodation
  final _nightsCtrl = TextEditingController();
  bool _hasReceipt = true;

  // Subsistence
  final _daysCtrl = TextEditingController();
  bool _isOvernightStay = true;
  DateTime? _returnDateTime;

  // Overseas — 13.5
  final _overseasTransportCtrl = TextEditingController();
  final _overseasPhoneCtrl     = TextEditingController();
  final _overseasLaundryCtrl   = TextEditingController();
  final _overseasOtherCtrl     = TextEditingController();

  // Receipt upload (optional)
  PlatformFile? _pickedFile;

  bool _isSubmitting = false;
  String? _submitError;

  @override
  void dispose() {
    for (final c in [_titleCtrl, _descCtrl, _distanceCtrl, _tollCtrl,
        _parkingCtrl, _amountCtrl, _distOfficeCtrl, _nightsCtrl, _daysCtrl,
        _overseasTransportCtrl, _overseasPhoneCtrl,
        _overseasLaundryCtrl, _overseasOtherCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Auto-calculate suggested amount ────────────────────────────────────────
  double? get _suggested {
    if (_claimType == 'travel' && _transportMode == 'own_vehicle') {
      final km = double.tryParse(_distanceCtrl.text) ?? 0;
      if (km <= 0) return null;
      final mileage = ClaimPolicyRates.calculateMileage(km);
      final toll    = double.tryParse(_tollCtrl.text)    ?? 0;
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
      // Sum all overseas components
      return (double.tryParse(_overseasTransportCtrl.text) ?? 0) +
             (double.tryParse(_overseasPhoneCtrl.text)     ?? 0) +
             (double.tryParse(_overseasLaundryCtrl.text)   ?? 0) +
             (double.tryParse(_overseasOtherCtrl.text)     ?? 0);
    }
    return double.tryParse(_amountCtrl.text) ?? 0;
  }

  Future<void> _submit() async {
    // Basic validation
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
        setState(() => _submitError = 'Distance from office must be at least 70 km to qualify.');
        return;
      }
    } else if (_claimType == 'subsistence') {
      if ((int.tryParse(_daysCtrl.text) ?? 0) <= 0) {
        setState(() => _submitError = 'Please enter number of days.');
        return;
      }
      if ((double.tryParse(_distOfficeCtrl.text) ?? 0) < 70) {
        setState(() => _submitError = 'Distance from office must be at least 70 km to qualify.');
        return;
      }
    } else if (_claimType == 'overseas') {
      if (_claimedAmount <= 0) {
        setState(() => _submitError = 'Please enter at least one overseas expense amount.');
        return;
      }
    } else {
      if ((double.tryParse(_amountCtrl.text) ?? 0) <= 0) {
        setState(() => _submitError = 'Please enter the claimed amount.');
        return;
      }
    }

    setState(() { _isSubmitting = true; _submitError = null; });

    String? receiptUrl;
    if (_pickedFile != null && _pickedFile!.bytes != null) {
      try {
        receiptUrl = await ClaimService().uploadReceipt(
          employeeId: widget.userId,
          bytes:      _pickedFile!.bytes!,
          fileName:   _pickedFile!.name,
        );
      } catch (e) {
        if (mounted) {
          setState(() {
            _submitError = 'Receipt upload failed: ${e.toString().replaceFirst("Exception: ", "")}';
            _isSubmitting = false;
          });
        }
        return;
      }
    }

    try {
      await widget.onSubmit({
        'claimType':   _claimType,
        'title':       _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'claimDate':   _claimDate,
        'amount':      _claimedAmount,
        'suggestedAmount': _suggested,
        'receiptUrl':      receiptUrl,
        // Travel
        'transportMode': _claimType == 'travel' ? _transportMode : null,
        'distanceKm':    _claimType == 'travel' && _transportMode == 'own_vehicle'
            ? double.tryParse(_distanceCtrl.text) : null,
        'tollAmount':    _claimType == 'travel' && _transportMode == 'own_vehicle'
            ? double.tryParse(_tollCtrl.text) : null,
        'parkingAmount': _claimType == 'travel' && _transportMode == 'own_vehicle'
            ? double.tryParse(_parkingCtrl.text) : null,
        // Shared
        'destinationType': (_claimType == 'accommodation' || _claimType == 'subsistence')
            ? _destinationType : null,
        'distanceFromOfficeKm': (_claimType == 'accommodation' || _claimType == 'subsistence')
            ? double.tryParse(_distOfficeCtrl.text) : null,
        // Accommodation
        'numberOfNights':          _claimType == 'accommodation' ? int.tryParse(_nightsCtrl.text) : null,
        'hasAccommodationReceipt': _claimType == 'accommodation' ? _hasReceipt : null,
        // Subsistence
        'numberOfDays':    _claimType == 'subsistence' ? int.tryParse(_daysCtrl.text) : null,
        'isOvernightStay': _claimType == 'subsistence' ? _isOvernightStay : null,
        'returnDateTime':  _claimType == 'subsistence' ? _returnDateTime : null,
        // Overseas
        'overseasTransportCost': _claimType == 'overseas' ? double.tryParse(_overseasTransportCtrl.text) : null,
        'overseasPhoneCost':     _claimType == 'overseas' ? double.tryParse(_overseasPhoneCtrl.text)     : null,
        'overseasLaundryCost':   _claimType == 'overseas' ? double.tryParse(_overseasLaundryCtrl.text)   : null,
        'overseasOtherCost':     _claimType == 'overseas' ? double.tryParse(_overseasOtherCtrl.text)     : null,
      });
    } catch (e) {
      if (mounted) setState(() => _submitError = e.toString().replaceFirst('Exception: ', ''));
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  // ── Claim type selection chips ─────────────────────────────────────────────
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
          onTap: () => setState(() { _claimType = t.$1; _submitError = null; }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppTheme.primary : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: selected ? AppTheme.primary : const Color(0xFFE5E7EB)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(t.$2, size: 16,
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

  // ── Dynamic fields ─────────────────────────────────────────────────────────
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
          _TransportChip(label: 'Own Vehicle', value: 'own_vehicle',
              selected: _transportMode == 'own_vehicle',
              onTap: () => setState(() => _transportMode = 'own_vehicle')),
          const SizedBox(width: 8),
          _TransportChip(label: 'Flight', value: 'flight',
              selected: _transportMode == 'flight',
              onTap: () => setState(() => _transportMode = 'flight')),
          const SizedBox(width: 8),
          _TransportChip(label: 'Public', value: 'public_transport',
              selected: _transportMode == 'public_transport',
              onTap: () => setState(() => _transportMode = 'public_transport')),
        ],
      ),
      const SizedBox(height: 14),
      if (_transportMode == 'own_vehicle') ...[
        _sectionLabel('Distance (km)'),
        _numField(_distanceCtrl, 'e.g. 150', onChanged: (_) => setState(() {})),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel('Toll (RM)'),
                _numField(_tollCtrl, '0.00', onChanged: (_) => setState(() {})),
              ],
            )),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel('Parking (RM)'),
                _numField(_parkingCtrl, '0.00', onChanged: (_) => setState(() {})),
              ],
            )),
          ],
        ),
        if (_suggested != null) ...[
          const SizedBox(height: 10),
          _policyHint('Mileage + Toll + Parking = RM ${_suggested!.toStringAsFixed(2)}'),
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
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Number of Nights'),
            _numField(_nightsCtrl, 'e.g. 2', isDecimal: false,
                onChanged: (_) => setState(() {})),
          ],
        )),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Has Receipt?'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _hasReceipt = !_hasReceipt),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white),
                child: Row(
                  children: [
                    Icon(_hasReceipt ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                        color: AppTheme.primary, size: 20),
                    const SizedBox(width: 6),
                    Text(_hasReceipt ? 'Yes' : 'No',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textDark)),
                  ],
                ),
              ),
            ),
          ],
        )),
      ]),
      if (_suggested != null && _suggested! > 0) ...[
        const SizedBox(height: 10),
        _policyHint('Policy rate: RM ${_suggested!.toStringAsFixed(2)} '
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
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Number of Days'),
            _numField(_daysCtrl, 'e.g. 3', isDecimal: false,
                onChanged: (_) => setState(() {})),
          ],
        )),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Stayed Overnight?'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _isOvernightStay = !_isOvernightStay),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white),
                child: Row(
                  children: [
                    Icon(_isOvernightStay ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                        color: AppTheme.primary, size: 20),
                    const SizedBox(width: 6),
                    Text(_isOvernightStay ? 'Yes' : 'No (½ rate)',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textDark)),
                  ],
                ),
              ),
            ),
          ],
        )),
      ]),
      const SizedBox(height: 12),
      _sectionLabel('Return Date & Time'),
      GestureDetector(
        onTap: _pickReturnDateTime,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(10),
              color: Colors.white),
          child: Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 18, color: AppTheme.textMuted),
              const SizedBox(width: 8),
              Text(
                _returnDateTime != null
                    ? DateFormat('d MMM yyyy, h:mm a').format(_returnDateTime!)
                    : 'Select return date & time',
                style: TextStyle(
                    fontSize: 13,
                    color: _returnDateTime != null ? AppTheme.textDark : AppTheme.textMuted),
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
                color: _returnDateTime!.hour >= 17 ? AppTheme.success : AppTheme.warning),
          ),
        ),
      if (_suggested != null && _suggested! > 0) ...[
        const SizedBox(height: 10),
        _policyHint('Policy rate: RM ${_suggested!.toStringAsFixed(2)} '
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
          border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.2)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF7C3AED)),
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
      _numField(_overseasTransportCtrl, '0.00', onChanged: (_) => setState(() {})),
      const SizedBox(height: 4),
      const Text('To/from destination — flight, taxi, etc.',
          style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      const SizedBox(height: 12),
      _sectionLabel('Official Phone Calls (RM)'),
      _numField(_overseasPhoneCtrl, '0.00', onChanged: (_) => setState(() {})),
      const SizedBox(height: 12),
      _sectionLabel('Laundry (RM)'),
      _numField(_overseasLaundryCtrl, '0.00', onChanged: (_) => setState(() {})),
      const SizedBox(height: 12),
      _sectionLabel('Other Personal Necessities (RM)'),
      _numField(_overseasOtherCtrl, '0.00', onChanged: (_) => setState(() {})),
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
        return Expanded(child: GestureDetector(
          onTap: () => setState(() { _destinationType = o.$1; }),
          child: Container(
            margin: EdgeInsets.only(right: o.$1 != 'other_foreign' ? 6 : 0),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: sel ? AppTheme.primary : Colors.white,
              border: Border.all(color: sel ? AppTheme.primary : const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(o.$2,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : AppTheme.textMuted),
                  textAlign: TextAlign.center),
            ),
          ),
        ));
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
      initialTime: TimeOfDay.fromDateTime(_returnDateTime ?? DateTime.now()),
    );
    if (time == null || !mounted) return;
    setState(() {
      _returnDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
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

      // On some Android devices the bytes can be null even with withData:true
      // (e.g. when the picker returns a file:// URI it can't read directly).
      // Fall back to reading via the path if available.
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
        } catch (_) {
          // ignore fallback failure — show error below
        }
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
        _submitError = null; // clear any previous error
      });
    } catch (e) {
      if (mounted) {
        setState(() => _submitError =
            'Could not open file picker: ${e.toString().replaceFirst("Exception: ", "")}');
      }
    }
  }

  /// Read raw bytes from a local file path (fallback for file:// URIs on Android).
  Future<Uint8List> _readFileBytes(String path) async {
    final file = await File(path).readAsBytes();
    return file;
  }

  Widget _sectionLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark)));

  Widget _numField(TextEditingController ctrl, String hint,
      {bool isDecimal = true, void Function(String)? onChanged}) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
      inputFormatters: [FilteringTextInputFormatter.allow(isDecimal ? RegExp(r'[\d.]') : RegExp(r'\d'))],
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.primary)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _policyHint(String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: AppTheme.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        const Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.success),
        const SizedBox(width: 8),
        Expanded(child: Text(text,
            style: const TextStyle(fontSize: 12, color: AppTheme.success,
                fontWeight: FontWeight.w600))),
      ]));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Text('Submit Claim',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                      color: AppTheme.textDark)),
              const SizedBox(height: 20),

              // Claim type
              _sectionLabel('Claim Type'),
              _buildTypeSelector(),
              const SizedBox(height: 16),

              if (_claimType != null) ...[
                // Title
                _sectionLabel('Title'),
                TextField(
                  controller: _titleCtrl,
                  decoration: InputDecoration(
                    hintText: switch (_claimType) {
                      'travel'        => 'e.g. Trip to KL office',
                      'accommodation' => 'e.g. Hotel in Johor Bahru',
                      'subsistence'   => 'e.g. Outstation Allowance — Penang',
                      _               => 'e.g. Conference registration fee',
                    },
                    hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppTheme.primary)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),

                // Claim date
                _sectionLabel('Claim Date'),
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _claimDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setState(() => _claimDate = d);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.textMuted),
                      const SizedBox(width: 8),
                      Text(DateFormat('d MMM yyyy').format(_claimDate),
                          style: const TextStyle(fontSize: 13, color: AppTheme.textDark)),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),

                // Type-specific fields
                ..._buildTypeFields(),
                const SizedBox(height: 12),

                // Description (optional)
                _sectionLabel('Description (optional)'),
                TextField(
                  controller: _descCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Additional notes...',
                    hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppTheme.primary)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),

                // Receipt upload (optional)
                _sectionLabel('Receipt (optional)'),
                GestureDetector(
                  onTap: _pickReceipt,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
                          color: _pickedFile != null ? AppTheme.success : AppTheme.textMuted,
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
                            onTap: () => setState(() => _pickedFile = null),
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

              // Error
              if (_submitError != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                      color: AppTheme.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3))),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_submitError!,
                          style: const TextStyle(fontSize: 12, color: AppTheme.danger,
                              fontWeight: FontWeight.w500))),
                    ],
                  ),
                ),
              ],

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting || _claimType == null ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.4),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Submit Claim',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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

// ── Transport Chip ────────────────────────────────────────────────────────────
class _TransportChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;
  const _TransportChip(
      {required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.white,
          border: Border.all(color: selected ? AppTheme.primary : const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppTheme.textMuted)),
      ),
    );
  }
}
