import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/state_views.dart';
import '../auth/auth_service.dart';
import '../auth/login_screen.dart';
import 'events_list_screen.dart';
import 'models/organization_model.dart';
import 'org_service.dart';

class OrgSelectionScreen extends StatefulWidget {
  final List<OrganizationModel>? initialOrganizations;
  final String? initialUserName;

  const OrgSelectionScreen({
    super.key,
    this.initialOrganizations,
    this.initialUserName,
  });

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
    if (widget.initialOrganizations != null) {
      _organizations = widget.initialOrganizations;
      _userName = widget.initialUserName ?? 'Pengguna';
      _isLoading = false;
    } else {
      _loadInitialData();
    }
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

  String _userInitial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'P';
    return trimmed[0].toUpperCase();
  }

  String _orgInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'OR';
    if (parts.length == 1) {
      final word = parts.first.toUpperCase();
      return word.length >= 2 ? word.substring(0, 2) : word;
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cloud,
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
          color: AppColors.forest,
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

    final orgCount = _organizations!.length;
    final displayName = _userName.trim().isEmpty ? 'Pengguna' : _userName.trim();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      children: [
        // Kartu sapaan memakai border seragam #D1E8DF tanpa left-border dekoratif (keputusan R-37).
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Text(
                      _userInitial(displayName),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.forest,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat datang, $displayName',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.forest,
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
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Row(
                  children: [
                    Text(
                      '$orgCount',
                      style: AppTheme.moneyLargeStyle.copyWith(
                        fontSize: 22,
                        color: AppColors.forest,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'organisasi terdaftar',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.forest,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Daftar Organisasi Aktif',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.forest,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '$orgCount organisasi terdaftar',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),

        ..._organizations!.map((org) => _buildOrgCard(org)),
      ],
    );
  }

  Widget _buildOrgCard(OrganizationModel org) {
    final Color badgeBg;
    final Color badgeText;
    final Color badgeBorder;

    if (org.isBendahara) {
      badgeBg = AppColors.statusApprovedBg;
      badgeText = AppColors.statusApprovedText;
      badgeBorder = AppColors.statusApprovedBorder;
    } else if (org.isKetua) {
      badgeBg = AppColors.mint;
      badgeText = AppColors.forest;
      badgeBorder = AppColors.border;
    } else {
      badgeBg = AppColors.surfaceRaised;
      badgeText = AppColors.textSecondary;
      badgeBorder = AppColors.border;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _selectOrganization(org),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                height: 48,
                width: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.forest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _orgInitials(org.name),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimary,
                    letterSpacing: 0.4,
                  ),
                ),
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
                        color: AppColors.forest,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
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
              const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
