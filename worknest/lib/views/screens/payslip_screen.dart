import 'package:flutter/material.dart';
import '../../models/payslip_model.dart';
import '../../viewmodels/payslip_viewmodel.dart';
import '../../theme/app_theme.dart';
import '../widgets/payslip/payslip_card.dart';
import '../widgets/payslip/payslip_detail_sheet.dart';

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
                        itemBuilder: (_, i) {
                          final p = vm.payslips[i];
                          return PayslipCard(
                            payslip: p,
                            onTap: () {
                              if (p.status == 'finalized') {
                                _openDetail(p);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Payslip not released yet. Please check back later.'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                          );
                        },
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
      builder: (_) => PayslipDetailSheet(payslip: p),
    );
  }
}

