import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../models/leave_policy_model.dart';
import '../../../models/leave_balance_model.dart';
import '../../../theme/app_theme.dart';
import '../../../services/leave_service.dart';
import 'inline_error.dart';
import 'half_day_chip.dart';
import 'date_summary_row.dart';
import 'range_date_picker.dart';

class ApplyLeaveSheet extends StatefulWidget {
  final List<LeavePolicyModel> policies;
  final List<LeaveBalanceModel> balances;
  final String userId;
  final String userGender;
  final Future<void> Function({
    required String leavePolicyId,
    required DateTime startDate,
    required DateTime endDate,
    required bool isHalfDay,
    String? halfDayPeriod,
    String? reason,
    String? attachmentUrl,
  }) onSubmit;

  const ApplyLeaveSheet({
    super.key,
    required this.policies,
    required this.balances,
    required this.userId,
    required this.userGender,
    required this.onSubmit,
  });

  bool isEligible(LeavePolicyModel policy) {
    if (policy.genderRestriction == 'all') return true;
    return policy.genderRestriction == userGender;
  }

  @override
  State<ApplyLeaveSheet> createState() => _ApplyLeaveSheetState();
}

class _ApplyLeaveSheetState extends State<ApplyLeaveSheet> {
  LeavePolicyModel? _selectedPolicy;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isHalfDay = false;
  String _halfDayPeriod = 'morning';
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;
  PlatformFile? _pickedFile;

  String? _policyError;
  String? _dateError;
  String? _documentError;
  String? _submitError;

  double get _calculatedDays {
    if (_startDate == null) return 0;
    final end = _endDate ?? _startDate!;
    return LeaveService.calculateDays(_startDate!, end, _isHalfDay);
  }

  LeaveBalanceModel? get _selectedBalance {
    if (_selectedPolicy == null) return null;
    try {
      return widget.balances.firstWhere(
        (b) => b.leavePolicyId == _selectedPolicy!.id,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: false,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.size > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('File too large. Maximum size is 5 MB.')),
          );
        }
        return;
      }
      setState(() => _pickedFile = file);
    }
  }

  Future<void> _submit() async {
    setState(() {
      _policyError =
          _selectedPolicy == null ? 'Please select a leave type' : null;
      _dateError = _startDate == null ? 'Please select a date' : null;
      _documentError =
          (_selectedPolicy?.requiresDocument == true && _pickedFile == null)
              ? 'A supporting document is required for this leave type'
              : null;
      _submitError = null;
    });

    if (_policyError != null || _dateError != null || _documentError != null) {
      return;
    }

    setState(() => _isSubmitting = true);

    String? attachmentUrl;
    if (_pickedFile != null && _pickedFile!.bytes != null) {
      try {
        attachmentUrl = await LeaveService().uploadAttachment(
          employeeId: widget.userId,
          bytes: _pickedFile!.bytes!,
          fileName: _pickedFile!.name,
        );
      } catch (e) {
        setState(() => _isSubmitting = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Upload failed: ${e.toString().replaceFirst('Exception: ', '')}'),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
        return;
      }
    }

    try {
      await widget.onSubmit(
        leavePolicyId: _selectedPolicy!.id,
        startDate: _startDate!,
        endDate: _endDate ?? _startDate!,
        isHalfDay: _isHalfDay,
        halfDayPeriod: _isHalfDay ? _halfDayPeriod : null,
        reason: _reasonController.text.trim().isEmpty
            ? null
            : _reasonController.text.trim(),
        attachmentUrl: attachmentUrl,
      );
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      debugPrint('[Submit] caught error: $msg');
      if (mounted) setState(() => _submitError = msg);
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Apply Leave',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded,
                        color: AppTheme.textMuted, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Leave type
              const Text(
                'Leave Type',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<LeavePolicyModel>(
                    value: _selectedPolicy,
                    isExpanded: true,
                    hint: const Text(
                      'Select leave type',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                    items: widget.policies.map((p) {
                      final eligible = widget.isEligible(p);
                      final balance = widget.balances
                          .where((b) => b.leavePolicyId == p.id)
                          .firstOrNull;
                      final genderLabel = p.genderRestriction == 'female'
                          ? '♀ Female only'
                          : p.genderRestriction == 'male'
                              ? '♂ Male only'
                              : null;
                      return DropdownMenuItem(
                        value: p,
                        enabled: eligible,
                        child: Opacity(
                          opacity: eligible ? 1.0 : 0.4,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      p.name,
                                      style: TextStyle(
                                        color: eligible
                                            ? AppTheme.textDark
                                            : AppTheme.textMuted,
                                      ),
                                    ),
                                    if (!eligible && genderLabel != null)
                                      Text(
                                        genderLabel,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.danger,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (eligible && balance != null)
                                Text(
                                  '${balance.remainingDays % 1 == 0 ? balance.remainingDays.toInt() : balance.remainingDays} days left',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() {
                      _selectedPolicy = val;
                      _policyError = null;
                      if (val != null && !val.allowHalfDay) {
                        _isHalfDay = false;
                      }
                    }),
                  ),
                ),
              ),

              if (_policyError != null) ...[
                const SizedBox(height: 6),
                InlineError(message: _policyError!),
              ],

              if (_selectedBalance != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Remaining: ${_selectedBalance!.remainingDays % 1 == 0 ? _selectedBalance!.remainingDays.toInt() : _selectedBalance!.remainingDays} / ${_selectedBalance!.totalDays} days',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              if (_selectedPolicy != null) ...[
                Opacity(
                  opacity: _selectedPolicy!.allowHalfDay ? 1.0 : 0.4,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Half Day',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                          if (!_selectedPolicy!.allowHalfDay)
                            const Text(
                              'Not available for this leave type',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                        ],
                      ),
                      Switch(
                        value: _isHalfDay,
                        activeColor: AppTheme.primary,
                        onChanged: _selectedPolicy!.allowHalfDay
                            ? (val) => setState(() {
                                  _isHalfDay = val;
                                  if (val && _startDate != null) {
                                    _endDate = _startDate;
                                  }
                                  if (!val) _endDate = null;
                                })
                            : null,
                      ),
                    ],
                  ),
                ),
                if (_isHalfDay) ...[
                  Row(
                    children: [
                      HalfDayChip(
                        label: 'Morning',
                        isSelected: _halfDayPeriod == 'morning',
                        onTap: () => setState(() => _halfDayPeriod = 'morning'),
                      ),
                      const SizedBox(width: 10),
                      HalfDayChip(
                        label: 'Afternoon',
                        isSelected: _halfDayPeriod == 'afternoon',
                        onTap: () =>
                            setState(() => _halfDayPeriod = 'afternoon'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ],

              const SizedBox(height: 4),

              const Text(
                'Select Date(s)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 4),

              DateSummaryRow(
                startDate: _startDate,
                endDate: _endDate,
                isHalfDay: _isHalfDay,
                onClear: () => setState(() {
                  _startDate = null;
                  _endDate = null;
                }),
              ),
              const SizedBox(height: 8),

              RangeDatePicker(
                startDate: _startDate,
                endDate: _endDate,
                isHalfDay: _isHalfDay,
                onChanged: (start, end) => setState(() {
                  _startDate = start;
                  _endDate = end;
                  _dateError = null;
                }),
              ),

              if (_dateError != null) ...[
                const SizedBox(height: 6),
                InlineError(message: _dateError!),
              ],

              if (_startDate != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: AppTheme.success,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Total: $_calculatedDays working day(s)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Document Upload
              Row(
                children: [
                  const Text(
                    'Supporting Document',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (_selectedPolicy?.requiresDocument == true)
                    const Text(
                      '(required)',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    const Text(
                      '(optional)',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickFile,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _pickedFile != null
                          ? AppTheme.primary
                          : const Color(0xFFE5E7EB),
                    ),
                    borderRadius: BorderRadius.circular(10),
                    color: _pickedFile != null
                        ? AppTheme.primary.withValues(alpha: 0.04)
                        : Colors.white,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _pickedFile != null
                              ? Icons.insert_drive_file_rounded
                              : Icons.upload_file_rounded,
                          color: AppTheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _pickedFile != null
                                  ? _pickedFile!.name
                                  : 'Tap to upload',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _pickedFile != null
                                    ? AppTheme.textDark
                                    : AppTheme.textMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _pickedFile != null
                                  ? '${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB'
                                  : 'PDF, JPG or PNG • max 5 MB',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_pickedFile != null)
                        GestureDetector(
                          onTap: () => setState(() {
                            _pickedFile = null;
                            _documentError = null;
                          }),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppTheme.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              if (_documentError != null) ...[
                const SizedBox(height: 6),
                InlineError(message: _documentError!),
              ],

              const SizedBox(height: 16),

              const Text(
                'Reason (optional)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter reason for leave...',
                  hintStyle: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.primary),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              if (_submitError != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppTheme.danger, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _submitError!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.danger,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Submit Request',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
