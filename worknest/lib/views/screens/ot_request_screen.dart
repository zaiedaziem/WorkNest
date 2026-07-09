import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/company_model.dart';
import '../../viewmodels/ot_request_viewmodel.dart';
import '../../theme/app_theme.dart';
import '../widgets/ot/ot_tile.dart';
import '../widgets/ot/submit_ot_sheet.dart';

class OtRequestScreen extends StatefulWidget {
  final UserModel user;
  final CompanyModel company;

  const OtRequestScreen({super.key, required this.user, required this.company});

  @override
  State<OtRequestScreen> createState() => _OtRequestScreenState();
}

class _OtRequestScreenState extends State<OtRequestScreen> {
  late OtRequestViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = OtRequestViewModel(
      userId: widget.user.id,
      companyId: widget.company.id,
    );
    _vm.addListener(_onChanged);
  }

  @override
  void dispose() {
    _vm.removeListener(_onChanged);
    _vm.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'OT Requests',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSubmitSheet,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Request OT',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: _vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _vm.load,
              child: _vm.error != null
                  ? _buildError(_vm.error!)
                  : _vm.requests.isEmpty
                      ? _buildEmpty()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: _vm.requests.length,
                          itemBuilder: (_, i) => OtTile(request: _vm.requests[i]),
                        ),
            ),
    );
  }

  Widget _buildError(String message) {
    return LayoutBuilder(
      builder: (_, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.wifi_off_rounded,
                      size: 40,
                      color: AppTheme.danger,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Couldn\'t load OT requests',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _vm.load,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            ),
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
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.access_time_rounded,
              size: 40,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No OT requests yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap the button below to submit one.',
            style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  void _showSubmitSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SubmitOtSheet(vm: _vm),
    );
  }
}
