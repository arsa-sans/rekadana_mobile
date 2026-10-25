import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_badge.dart';
import '../organization/models/event_model.dart';
import '../organization/models/organization_model.dart';
import 'expense_create_screen.dart';
import 'expense_detail_screen.dart';
import 'expense_service.dart';
import 'models/expense_request_model.dart';

class ExpenseListScreen extends StatefulWidget {
  final OrganizationModel organization;
  final EventModel event;

  const ExpenseListScreen({
    super.key,
    required this.organization,
    required this.event,
  });

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  final ExpenseService _expenseService = ExpenseService();

  List<ExpenseRequestModel> _allExpenses = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'all'; // 'all', 'submitted', 'approved', 'rejected', 'paid'

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  Future<void> _fetchExpenses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _expenseService.listExpenseRequests(widget.event.id);
      if (!mounted) return;
      setState(() {
        _allExpenses = list;
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

  List<ExpenseRequestModel> get _filteredExpenses {
    if (_selectedFilter == 'all') return _allExpenses;
    return _allExpenses.where((e) => e.status.toLowerCase() == _selectedFilter).toList();
  }

  void _navigateToCreate() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExpenseCreateScreen(
          organization: widget.organization,
          event: widget.event,
        ),
      ),
    );
    if (result == true) {
      _fetchExpenses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      appBar: AppBar(
        title: const Text('Daftar Pengeluaran'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary700),
            tooltip: 'Ajukan Pengeluaran',
            onPressed: _navigateToCreate,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Baris Horizontal
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('all', 'Semua'),
                    const SizedBox(width: 8),
                    _buildFilterChip('submitted', 'Diajukan'),
                    const SizedBox(width: 8),
                    _buildFilterChip('approved', 'Disetujui'),
                    const SizedBox(width: 8),
                    _buildFilterChip('rejected', 'Ditolak'),
                    const SizedBox(width: 8),
                    _buildFilterChip('paid', 'Lunas'),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchExpenses,
                color: AppColors.primary700,
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary700,
        foregroundColor: AppColors.textInverse,
        icon: const Icon(Icons.add),
        label: const Text('Ajukan Kebutuhan'),
        onPressed: _navigateToCreate,
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() {
            _selectedFilter = filterKey;
          });
        }
      },
      selectedColor: AppColors.primary100,
      backgroundColor: AppColors.surfaceRaised,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        color: isSelected ? AppColors.primary700 : AppColors.textSecondary,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary500 : AppColors.border,
        width: 1,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingView(message: 'Memuat daftar pengeluaran...');
    }

    if (_errorMessage != null) {
      return ErrorStateView(
        message: _errorMessage!,
        onRetry: _fetchExpenses,
      );
    }

    final displayList = _filteredExpenses;

    if (displayList.isEmpty) {
      return EmptyStateView(
        icon: Icons.receipt_long_outlined,
        title: 'Belum Ada Pengeluaran',
        description: _selectedFilter == 'all'
            ? 'Belum ada pengajuan kebutuhan lapangan yang dibuat untuk kegiatan ini.'
            : 'Tidak ada pengeluaran dengan status terpilih.',
        actionLabel: 'Ajukan Kebutuhan Pertama',
        onAction: _navigateToCreate,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 80.0),
      itemCount: displayList.length,
      itemBuilder: (ctx, index) {
        final item = displayList[index];
        return _buildExpenseCard(item);
      },
    );
  }

  Widget _buildExpenseCard(ExpenseRequestModel item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ExpenseDetailScreen(
                expense: item,
                organization: widget.organization,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StatusBadge(status: item.status),
                  Text(
                    DateFormatter.formatDate(item.createdAt),
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (item.description != null && item.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  item.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Nominal Pengajuan:',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    CurrencyFormatter.format(item.requestedAmount),
                    style: AppTheme.moneyStyle,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
