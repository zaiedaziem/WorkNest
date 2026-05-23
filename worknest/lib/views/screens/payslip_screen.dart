import 'package:flutter/material.dart';
import '../../models/payslip_model.dart';
import '../../viewmodels/payslip_viewmodel.dart';
import '../../theme/app_theme.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PayslipScreen extends StatefulWidget {
  final PayslipViewModel viewModel;
  const PayslipScreen({super.key, required this.viewModel});

  @override
  State<PayslipScreen> createState() => _PayslipScreenState();
}

class _PayslipScreenState extends State<PayslipScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Payslips',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.error != null
              ? _buildError(vm)
              : vm.payslips.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: vm.load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: vm.payslips.length,
                        itemBuilder: (_, i) => _PayslipCard(
                          payslip: vm.payslips[i],
                          onTap: () => _openDetail(vm.payslips[i]),
                        ),
                      ),
                    ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_rounded,
                size: 40, color: AppTheme.primary),
          ),
          const SizedBox(height: 16),
          const Text('No payslips yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                  color: AppTheme.textDark)),
          const SizedBox(height: 6),
          const Text('Finalized payslips will appear here.',
              style: TextStyle(fontSize: 14, color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  Widget _buildError(PayslipViewModel vm) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 48, color: AppTheme.danger),
          const SizedBox(height: 12),
          Text(vm.error ?? 'Something went wrong',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: vm.load, child: const Text('Retry')),
        ],
      ),
    );
  }

  void _openDetail(PayslipModel p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PayslipDetailSheet(payslip: p),
    );
  }
}

// ── Payslip List Card ─────────────────────────────────────────────────────────
class _PayslipCard extends StatelessWidget {
  final PayslipModel payslip;
  final VoidCallback onTap;

  const _PayslipCard({required this.payslip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF3F4F6)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Month icon
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long_rounded,
                    color: AppTheme.primary, size: 24),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(payslip.monthName,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700,
                            color: AppTheme.textDark)),
                    const SizedBox(height: 4),
                    Text('Gross: RM ${payslip.grossPay.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.textMuted)),
                  ],
                ),
              ),
              // Net Pay
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('RM ${payslip.netPay.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800,
                          color: AppTheme.success)),
                  const SizedBox(height: 4),
                  const Text('Net Pay',
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Payslip Detail Bottom Sheet ───────────────────────────────────────────────
class _PayslipDetailSheet extends StatelessWidget {
  final PayslipModel payslip;
  const _PayslipDetailSheet({required this.payslip});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PAYSLIP',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700,
                                color: AppTheme.primary, letterSpacing: 1.5)),
                        Text(payslip.monthName,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w800,
                                color: AppTheme.textDark)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _downloadPdf(context),
                    icon: const Icon(Icons.download_rounded),
                    color: AppTheme.primary,
                    tooltip: 'Download PDF',
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    color: AppTheme.textMuted,
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            // Scrollable content
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  // ── Earnings ──────────────────────────────────────────────
                  _sectionTitle('EARNINGS'),
                  _row('Basic Salary', payslip.basicSalary),
                  if (payslip.transportAllowance > 0)
                    _row('Transport Allowance', payslip.transportAllowance),
                  if (payslip.mealAllowance > 0)
                    _row('Meal Allowance', payslip.mealAllowance),
                  if (payslip.housingAllowance > 0)
                    _row('Housing Allowance', payslip.housingAllowance),
                  if (payslip.otherAllowance > 0)
                    _row('Other Allowance', payslip.otherAllowance),
                  if (payslip.otPay > 0)
                    _row('OT Pay', payslip.otPay, color: AppTheme.success),
                  _divider(),
                  _row('Gross Pay', payslip.grossPay,
                      bold: true, color: AppTheme.primary),
                  const SizedBox(height: 16),

                  // ── Deductions ────────────────────────────────────────────
                  _sectionTitle('DEDUCTIONS'),
                  _row('EPF (11% of Basic)', payslip.epfEmployee,
                      isDeduction: true),
                  _row('SOCSO (0.5%)', payslip.socsoEmployee,
                      isDeduction: true),
                  _row('EIS (0.2%)', payslip.eisEmployee,
                      isDeduction: true),
                  if (payslip.attendanceDeduction > 0)
                    _row('Attendance Deduction', payslip.attendanceDeduction,
                        isDeduction: true),
                  _divider(),
                  _row('Total Deductions', payslip.totalDeductions,
                      bold: true, isDeduction: true),
                  const SizedBox(height: 16),

                  // ── Claims ────────────────────────────────────────────────
                  if (payslip.claimsTotal > 0) ...[
                    _sectionTitle('REIMBURSEMENTS'),
                    _row('Claims Reimbursement', payslip.claimsTotal,
                        color: AppTheme.success),
                    const SizedBox(height: 16),
                  ],

                  // ── Remarks ───────────────────────────────────────────────
                  if (payslip.hrRemarks != null &&
                      payslip.hrRemarks!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 16, color: AppTheme.textMuted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(payslip.hrRemarks!,
                                style: const TextStyle(
                                    fontSize: 13, color: AppTheme.textMuted)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Net Pay ───────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('NET PAY',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700,
                                color: AppTheme.success, letterSpacing: 0.5)),
                        Text('RM ${payslip.netPay.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w800,
                                color: AppTheme.success)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'This is a computer-generated payslip.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: AppTheme.textMuted, letterSpacing: 1.2)),
      );

  Widget _row(String label, double amount,
      {bool bold = false, bool isDeduction = false, Color? color}) {
    final textColor = color ??
        (isDeduction ? AppTheme.danger : AppTheme.textDark);
    final prefix = isDeduction ? '− ' : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                  color: bold ? AppTheme.textDark : AppTheme.textMuted)),
          Text('$prefix RM ${amount.toStringAsFixed(2)}',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                  color: textColor)),
        ],
      ),
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Divider(color: Color(0xFFE5E7EB)),
      );

  Future<void> _downloadPdf(BuildContext context) async {
    final doc = pw.Document();

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (pw.Context ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('PAYSLIP',
                      style: pw.TextStyle(
                          fontSize: 20, fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF4f46e5))),
                  pw.Text(payslip.monthName,
                      style: const pw.TextStyle(fontSize: 13)),
                ],
              ),
              pw.Text(
                'Generated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
          pw.Divider(),

          // Earnings
          pw.SizedBox(height: 8),
          pw.Text('EARNINGS',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold,
                  color: const PdfColor.fromInt(0xFF6b7280))),
          pw.SizedBox(height: 6),
          _pdfRow('Basic Salary', payslip.basicSalary),
          if (payslip.transportAllowance > 0)
            _pdfRow('Transport Allowance', payslip.transportAllowance),
          if (payslip.mealAllowance > 0)
            _pdfRow('Meal Allowance', payslip.mealAllowance),
          if (payslip.housingAllowance > 0)
            _pdfRow('Housing Allowance', payslip.housingAllowance),
          if (payslip.otherAllowance > 0)
            _pdfRow('Other Allowance', payslip.otherAllowance),
          if (payslip.otPay > 0) _pdfRow('OT Pay', payslip.otPay),
          pw.Divider(),
          _pdfRow('GROSS PAY', payslip.grossPay, bold: true),

          // Deductions
          pw.SizedBox(height: 12),
          pw.Text('DEDUCTIONS',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold,
                  color: const PdfColor.fromInt(0xFF6b7280))),
          pw.SizedBox(height: 6),
          _pdfRow('EPF - 11% of Basic (KWSP)', payslip.epfEmployee, isDeduction: true),
          _pdfRow('SOCSO - 0.5% of Gross',     payslip.socsoEmployee, isDeduction: true),
          _pdfRow('EIS - 0.2% of Gross',       payslip.eisEmployee,   isDeduction: true),
          if (payslip.attendanceDeduction > 0)
            _pdfRow('Attendance Deduction', payslip.attendanceDeduction, isDeduction: true),
          pw.Divider(),
          _pdfRow('TOTAL DEDUCTIONS', payslip.totalDeductions, bold: true, isDeduction: true),

          // Claims
          if (payslip.claimsTotal > 0) ...[
            pw.SizedBox(height: 12),
            pw.Text('REIMBURSEMENTS',
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold,
                    color: const PdfColor.fromInt(0xFF6b7280))),
            pw.SizedBox(height: 6),
            _pdfRow('Claims Reimbursement', payslip.claimsTotal),
          ],

          // Remarks
          if (payslip.hrRemarks != null && payslip.hrRemarks!.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text('Remarks: ${payslip.hrRemarks}',
                style: const pw.TextStyle(fontSize: 10)),
          ],

          // Net Pay
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFf0fdf4),
              border: pw.Border.all(color: const PdfColor.fromInt(0xFF16a34a)),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('NET PAY',
                    style: pw.TextStyle(
                        fontSize: 14, fontWeight: pw.FontWeight.bold,
                        color: const PdfColor.fromInt(0xFF16a34a))),
                pw.Text('RM ${payslip.netPay.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold,
                        color: const PdfColor.fromInt(0xFF16a34a))),
              ],
            ),
          ),

          pw.Spacer(),
          pw.Divider(),
          pw.Text(
            'This is a computer-generated payslip and does not require a signature.',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    ));

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'Payslip_${payslip.monthName.replaceAll(' ', '_')}.pdf',
    );
  }

  pw.Widget _pdfRow(String label, double amount,
      {bool bold = false, bool isDeduction = false}) {
    final prefix = isDeduction ? '- RM ' : 'RM ';
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text('$prefix${amount.toStringAsFixed(2)}',
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: isDeduction
                      ? const PdfColor.fromInt(0xFFef4444)
                      : PdfColors.black)),
        ],
      ),
    );
  }
}
