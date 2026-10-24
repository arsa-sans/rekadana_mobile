import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/state_views.dart';
import '../auth/auth_service.dart';
import '../auth/login_screen.dart';
import 'events_list_screen.dart';
import 'models/organization_model.dart';
import 'org_service.dart';

class OrgSelectionScreen extends StatefulWidget {
  const OrgSelectionScreen({super.key});

  @override
  State<OrgSelectionScreen> createState() => _OrgSelectionScreenState();
}

class _OrgSelectionScreenState extends State<OrgSelectionScreen> {
  final OrgService _orgService = OrgService();
  final AuthService _authService = AuthService();
  final SecureStorageService _storage = SecureStorageService();

  List<OrganizationModel>? _organizations;
  bool _isLoading = true;
  String? _errorMessage;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final user = await _storage.getUser();
    if (mounted && user != null) {
      setState(() {
        _userName = user['name'] as String? ?? 'Pengguna';
      });
    }
    _fetchOrganizations();
  }

  Future<void> _fetchOrganizations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _orgService.getOrganizations();
      if (!mounted) return;
      setState(() {
        _organizations = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Keluar dari Akun',
      message: 'Apakah Anda yakin ingin keluar dari aplikasi RekaDana?',
      confirmLabel: 'Keluar',
      isDestructive: true,
    );

    if (confirmed == true) {
      await _authService.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _selectOrganization(OrganizationModel org) async {
    await _storage.saveContextIds(orgId: org.id);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventsListScreen(organization: org),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      appBar: AppBar(
        title: const Text('Pilih Organisasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textSecondary),
            tooltip: 'Keluar',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchOrganizations,
          color: AppColors.primary700,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingView(message: 'Memuat daftar organisasi Anda...');
    }

    if (_errorMessage != null) {
      return ErrorStateView(
        message: _errorMessage!,
        onRetry: _fetchOrganizations,
      );
    }

    if (_organizations == null || _organizations!.isEmpty) {
      return const EmptyStateView(
        icon: Icons.corporate_fare_outlined,
        title: 'Belum Ada Organisasi',
        description: 'Akun Anda belum terdaftar sebagai anggota di organisasi manapun.',
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      children: [
        // Salam sapaan pengguna
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary200, width: 1),
                ),
                child: const Icon(Icons.person_outline, color: AppColors.primary700, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat datang, $_userName',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Pilih organisasi untuk mengelola anggaran kegiatan',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Padding(
          padding: EdgeInsets.only(left: 4.0, bottom: 10.0),
          child: Text(
            'Daftar Organisasi Aktif',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),

        ..._organizations!.map((org) => _buildOrgCard(org)),
      ],
    );
  }

  Widget _buildOrgCard(OrganizationModel org) {
    Color badgeBg;
    Color badgeText;
    Color badgeBorder;

    if (org.isBendahara) {
      badgeBg = AppColors.statusApprovedBg;
      badgeText = AppColors.statusApprovedText;
      badgeBorder = AppColors.statusApprovedBorder;
    } else if (org.isKetua) {
      badgeBg = AppColors.primary50;
      badgeText = AppColors.primary700;
      badgeBorder = AppColors.primary200;
    } else {
      badgeBg = AppColors.statusDraftBg;
      badgeText = AppColors.statusDraftText;
      badgeBorder = AppColors.statusDraftBorder;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _selectOrganization(org),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: const Icon(Icons.apartment_outlined, color: AppColors.primary700, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      org.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: badgeBorder, width: 1),
                      ),
                      child: Text(
                        org.roleDisplayTitle,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: badgeText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
