import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../models/payslip_model.dart';
import '../../../theme/app_theme.dart';

class PayslipDetailSheet extends StatelessWidget {
  final PayslipModel payslip;
  const PayslipDetailSheet({super.key, required this.payslip});

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
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
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
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                                letterSpacing: 1.5)),
                        Text(payslip.monthName,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
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
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  _sectionTitle('EMPLOYEE INFO'),
                  _infoRow('IC / Passport', payslip.icNumber),
                  _infoRow('Bank', payslip.bankName),
                  _infoRow('Bank Account No.', payslip.bankAccount),
                  const SizedBox(height: 16),

                  _sectionTitle('EARNINGS'),
                  _row('Basic Salary', payslip.basicSalary),
                  _row('OT Pay', payslip.otPay),
                  if (payslip.transportAllowance > 0)
                    _row('Transport Allowance', payslip.transportAllowance),
                  if (payslip.mealAllowance > 0)
                    _row('Meal Allowance', payslip.mealAllowance),
                  if (payslip.housingAllowance > 0)
                    _row('Housing Allowance', payslip.housingAllowance),
                  if (payslip.otherAllowance > 0)
                    _row('Other Allowance', payslip.otherAllowance),
                  if (payslip.claimsTotal > 0)
                    _row('Claims Reimbursement', payslip.claimsTotal,
                        color: AppTheme.success),
                  _divider(),
                  _row('Total Earnings', payslip.totalEarnings,
                      bold: true, color: AppTheme.primary),
                  const SizedBox(height: 16),

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

                  if (payslip.hrRemarks != null &&
                      payslip.hrRemarks!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: const Color(0xFFE5E7EB)),
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
                                    fontSize: 13,
                                    color: AppTheme.textMuted)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('NETT PAY',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.success,
                                letterSpacing: 0.5)),
                        Text(
                            'RM ${payslip.netPay.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.success)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'This is a computer-generated payslip.',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 11, color: AppTheme.textMuted),
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
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
                letterSpacing: 1.2)),
      );

  Widget _row(String label, double amount,
      {bool bold = false, bool isDeduction = false, Color? color}) {
    final textColor =
        color ?? (isDeduction ? AppTheme.danger : AppTheme.textDark);
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

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 140,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textMuted)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark)),
            ),
          ],
        ),
      );

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Divider(color: Color(0xFFE5E7EB)),
      );

  Future<void> _downloadPdf(BuildContext context) async {
    final doc = pw.Document();
    final p = payslip;
    final now = DateTime.now();
    final paymentDate =
        '${now.day.toString().padLeft(2, '0')}-${_monthAbbr(now.month)}-${now.year}';

    const border = pw.BorderSide(color: PdfColors.black, width: 0.75);
    const thinBorder = pw.BorderSide(color: PdfColors.black, width: 0.5);

    pw.Widget cell(String text,
        {bool bold = false,
        bool rightAlign = false,
        pw.EdgeInsets? padding,
        double fontSize = 9}) {
      return pw.Container(
        padding: padding ??
            const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        alignment:
            rightAlign ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: pw.Text(text,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight:
                  bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            )),
      );
    }

    pw.Widget infoPair(String label, String value, double labelWidth) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
        child: pw.Row(children: [
          pw.SizedBox(
              width: labelWidth,
              child: pw.Text(label,
                  style: const pw.TextStyle(fontSize: 8.5))),
          pw.Text(':  ', style: const pw.TextStyle(fontSize: 8.5)),
          pw.Expanded(
              child: pw.Text(value,
                  style: const pw.TextStyle(fontSize: 8.5))),
        ]),
      );
    }

    final List<pw.TableRow> tableRows = [];

    tableRows.add(pw.TableRow(
      decoration:
          const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF0F0F0)),
      children: [
        cell('DESCRIPTION',
            bold: true,
            padding: const pw.EdgeInsets.symmetric(
                horizontal: 6, vertical: 5)),
        cell('EARNINGS',
            bold: true,
            rightAlign: true,
            padding: const pw.EdgeInsets.symmetric(
                horizontal: 6, vertical: 5)),
        cell('DEDUCTIONS',
            bold: true,
            rightAlign: true,
            padding: const pw.EdgeInsets.symmetric(
                horizontal: 6, vertical: 5)),
      ],
    ));

    pw.TableRow dataRow(String desc, double? earning, double? deduction) {
      return pw.TableRow(children: [
        cell(desc),
        cell(earning != null ? earning.toStringAsFixed(2) : '',
            rightAlign: true),
        cell(deduction != null ? deduction.toStringAsFixed(2) : '',
            rightAlign: true),
      ]);
    }

    tableRows.add(dataRow('BASIC SALARY', p.basicSalary, null));
    tableRows.add(dataRow('OT', p.otPay, null));
    if (p.transportAllowance > 0)
      tableRows
          .add(dataRow('TRANSPORT ALLOWANCE', p.transportAllowance, null));
    if (p.mealAllowance > 0)
      tableRows.add(dataRow('MEAL ALLOWANCE', p.mealAllowance, null));
    if (p.housingAllowance > 0)
      tableRows
          .add(dataRow('HOUSING ALLOWANCE', p.housingAllowance, null));
    if (p.otherAllowance > 0)
      tableRows.add(dataRow('OTHER ALLOWANCE', p.otherAllowance, null));
    if (p.claimsTotal > 0)
      tableRows
          .add(dataRow('CLAIMS REIMBURSEMENT', p.claimsTotal, null));

    tableRows.add(dataRow('', null, null));

    tableRows.add(dataRow('EPF', null, p.epfEmployee));
    tableRows.add(dataRow('SOCSO', null, p.socsoEmployee));
    tableRows.add(dataRow('EIS', null, p.eisEmployee));
    if (p.attendanceDeduction > 0)
      tableRows.add(
          dataRow('ATTENDANCE DEDUCTION', null, p.attendanceDeduction));

    if (p.hrRemarks != null && p.hrRemarks!.isNotEmpty) {
      tableRows.add(pw.TableRow(children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(
              horizontal: 6, vertical: 4),
          child: pw.Text('Remarks : ${p.hrRemarks}',
              style: pw.TextStyle(
                  fontSize: 8,
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey600)),
        ),
        pw.Container(),
        pw.Container(),
      ]));
    }

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 35, vertical: 30),
      build: (pw.Context ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.RichText(
                      text: pw.TextSpan(children: [
                        pw.TextSpan(
                          text: p.companyName.isNotEmpty
                              ? p.companyName
                              : 'Company',
                          style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold),
                        ),
                      ]),
                    ),
                    if (p.companyAddress.isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(p.companyAddress,
                          style: const pw.TextStyle(fontSize: 8)),
                    ],
                    if (p.companyPhone.isNotEmpty ||
                        p.companyEmail.isNotEmpty) ...[
                      pw.Text(
                        [
                          if (p.companyPhone.isNotEmpty)
                            'Tel : ${p.companyPhone}',
                          if (p.companyEmail.isNotEmpty)
                            'Email : ${p.companyEmail}',
                        ].join(' / '),
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ],
                  ],
                ),
              ),
              pw.RichText(
                text: pw.TextSpan(children: [
                  const pw.TextSpan(
                      text: 'Payslip For   ',
                      style: pw.TextStyle(fontSize: 9)),
                  pw.TextSpan(
                      text: p.monthShort,
                      style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold)),
                ]),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Divider(thickness: 0.75, color: PdfColors.black),
          pw.SizedBox(height: 6),

          pw.Table(
            border:
                pw.TableBorder.all(color: PdfColors.black, width: 0.75),
            columnWidths: const {
              0: pw.FlexColumnWidth(5),
              1: pw.FlexColumnWidth(3),
              2: pw.FlexColumnWidth(4),
            },
            children: [
              pw.TableRow(children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(7),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      infoPair('NAME',
                          p.empName.isNotEmpty ? p.empName : '-', 78),
                      infoPair('IC / PASSPORT', p.icNumber, 78),
                      infoPair('BANK A/C NO.', p.bankAccount, 78),
                    ],
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(7),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      infoPair('EMP ID', p.empIdStr, 50),
                      infoPair('DEPT', p.department, 50),
                      infoPair('BANK', p.bankName, 50),
                    ],
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(7),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      infoPair('PAYMENT DATE', paymentDate, 88),
                      infoPair('PAY BY', '-', 88),
                    ],
                  ),
                ),
              ]),
            ],
          ),
          pw.SizedBox(height: 12),

          pw.Table(
            border: pw.TableBorder(
              top: border,
              bottom: thinBorder,
              left: border,
              right: border,
              horizontalInside: thinBorder,
              verticalInside: border,
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(5),
              1: pw.FlexColumnWidth(3),
              2: pw.FlexColumnWidth(3),
            },
            children: tableRows,
          ),

          pw.Container(
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                left: border,
                right: border,
                bottom: border,
              ),
            ),
            child: pw.Column(children: [
              pw.Container(height: 0.75, color: PdfColors.black),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 6, vertical: 5),
                child: pw.Row(children: [
                  pw.Expanded(
                    child: pw.RichText(
                      text: pw.TextSpan(children: [
                        pw.TextSpan(
                            text: 'TOTAL EARNINGS',
                            style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold)),
                        pw.TextSpan(
                            text:
                                '          ${p.totalEarnings.toStringAsFixed(2)}',
                            style: const pw.TextStyle(fontSize: 9)),
                      ]),
                    ),
                  ),
                  pw.RichText(
                    text: pw.TextSpan(children: [
                      pw.TextSpan(
                          text: 'TOTAL DEDUCTIONS',
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold)),
                      pw.TextSpan(
                          text:
                              '          ${p.totalDeductions.toStringAsFixed(2)}',
                          style: const pw.TextStyle(fontSize: 9)),
                    ]),
                  ),
                ]),
              ),
              pw.Container(height: 0.5, color: PdfColors.grey400),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 6, vertical: 6),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.RichText(
                      text: pw.TextSpan(children: [
                        pw.TextSpan(
                            text: 'NETT PAY',
                            style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold)),
                        pw.TextSpan(
                            text:
                                '          RM ${p.netPay.toStringAsFixed(2)}',
                            style: pw.TextStyle(
                                fontSize: 13,
                                fontWeight: pw.FontWeight.bold)),
                      ]),
                    ),
                  ],
                ),
              ),
            ]),
          ),

          pw.Spacer(),

          pw.Divider(thickness: 0.5, color: PdfColors.grey400),
          pw.SizedBox(height: 4),
          pw.Text(
            'This is a computer-generated payslip and does not require a signature.',
            style: const pw.TextStyle(
                fontSize: 7.5, color: PdfColors.grey600),
          ),
        ],
      ),
    ));

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename:
          'Payslip_${p.monthName.replaceAll(' ', '_')}.pdf',
    );
  }

  String _monthAbbr(int m) {
    const abbr = [
      '',
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return abbr[m];
  }
}
