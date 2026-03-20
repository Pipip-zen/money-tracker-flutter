import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_theme.dart';
import '../../providers/dashboard_providers.dart';
import '../../providers/budget_providers.dart';
import '../../providers/category_providers.dart';
import '../../../domain/entities/budget_entity.dart';
import '../../../domain/entities/category_entity.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, now),
              const SizedBox(height: 24),
              _buildBalanceCard(context, ref, now),
              const SizedBox(height: 24),
              _buildBudgetSection(context, ref, now),
              const SizedBox(height: 24),
              _buildRecentTransactions(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DateTime now) {
    final monthFormat = DateFormat('MMMM yyyy', 'id_ID'); // Will fallback if locale not initialized
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              monthFormat.format(now),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
        CircleAvatar(
          backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
          child: const Icon(Icons.person, color: AppTheme.primaryGreen),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(BuildContext context, WidgetRef ref, DateTime now) {
    final balanceAsync = ref.watch(currentBalanceProvider);
    final monthlyAsync = ref.watch(combinedMonthlyTotalProvider((month: now.month, year: now.year)));
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.lightGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Saldo',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          balanceAsync.when(
            data: (balance) => Text(
              currencyFormat.format(balance),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            loading: () => _buildShimmerText(width: 150, height: 32),
            error: (e, st) => const Text('Error', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Income
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.arrow_downward, color: Colors.white70, size: 16),
                        SizedBox(width: 4),
                        Text('Pemasukan', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    monthlyAsync.when(
                      data: (totals) => Text(
                        currencyFormat.format(totals.income),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                      loading: () => _buildShimmerText(width: 80, height: 16),
                      error: (e, st) => const Text('Error', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
              // Expense
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.arrow_upward, color: Colors.white70, size: 16),
                        SizedBox(width: 4),
                        Text('Pengeluaran', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    monthlyAsync.when(
                      data: (totals) => Text(
                        currencyFormat.format(totals.expense),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                      loading: () => _buildShimmerText(width: 80, height: 16),
                      error: (e, st) => const Text('Error', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetSection(BuildContext context, WidgetRef ref, DateTime now) {
    final budgetsAsync = ref.watch(budgetsProvider((month: now.month, year: now.year)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Anggaran Bulan Ini', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () {},
              child: const Text('Lihat Semua')
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 140,
          child: budgetsAsync.when(
            data: (budgets) {
              if (budgets.isEmpty) {
                return Center(
                  child: Text(
                    'Belum ada anggaran.',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: budgets.length,
                itemBuilder: (context, index) {
                  return _BudgetCard(budget: budgets[index]);
                },
              );
            },
            loading: () => ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (context, index) => const _BudgetCardShimmer(),
            ),
            error: (e, st) => const Center(child: Text('Gagal memuat anggaran.')),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(BuildContext context, WidgetRef ref) {
    final recentAsync = ref.watch(recentTransactionsProvider);
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Transaksi Terakhir', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () {},
              child: const Text('Lihat Semua')
            ),
          ],
        ),
        const SizedBox(height: 8),
        recentAsync.when(
          data: (transactions) {
            if (transactions.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Belum ada transaksi.',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final tx = transactions[index];
                final isIncome = tx.type == 'income';
                final color = _parseColor(tx.categoryColor);

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.2),
                    child: Text(tx.categoryIcon, style: const TextStyle(fontSize: 20)),
                  ),
                  title: Text(tx.categoryName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    tx.note != null && tx.note!.isNotEmpty ? tx.note! : dateFormat.format(tx.date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    '${isIncome ? '+' : '-'}${currencyFormat.format(tx.amount)}',
                    style: TextStyle(
                      color: isIncome ? AppTheme.accentGreen : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                );
              },
            );
          },
          loading: () => ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: const CircleAvatar(radius: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildShimmerText(width: 100, height: 14, baseColor: Colors.grey[300]!),
                        const SizedBox(height: 8),
                        _buildShimmerText(width: 150, height: 12, baseColor: Colors.grey[300]!),
                      ],
                    ),
                  ),
                  _buildShimmerText(width: 80, height: 14, baseColor: Colors.grey[300]!),
                ],
              ),
            ),
          ),
          error: (e, st) => const Center(child: Text('Gagal memuat transaksi.')),
        ),
      ],
    );
  }

  Widget _buildShimmerText({required double width, required double height, Color? baseColor}) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? AppTheme.lightGreen,
      highlightColor: baseColor != null ? Colors.grey[100]! : AppTheme.accentGreen,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}

class _BudgetCard extends ConsumerWidget {
  final BudgetEntity budget;

  const _BudgetCard({required this.budget});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final spent = budget.spentAmount ?? 0.0;
    final percent = budget.limitAmount > 0 ? (spent / budget.limitAmount).clamp(0.0, 1.0) : 0.0;
    final isWarning = percent > 0.8;

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isWarning ? Colors.red.withValues(alpha: 0.3) : Colors.transparent,
        ),
      ),
      child: categoriesAsync.when(
        data: (categories) {
          final category = categories.firstWhere(
            (c) => c.id == budget.categoryId,
            orElse: () => const CategoryEntity(id: 0, name: 'Unknown', icon: '❓', color: '#000000', type: 'expense'),
          );
          Color catColor = _parseColor(category.color);
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: catColor.withValues(alpha: 0.2),
                    child: Text(category.icon, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      category.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                currencyFormat.format(spent),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isWarning ? Colors.red : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'dari ${currencyFormat.format(budget.limitAmount)}',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: percent,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  isWarning ? Colors.red : AppTheme.primaryGreen,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Text('Error'),
      ),
    );
  }

  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}

class _BudgetCardShimmer extends StatelessWidget {
  const _BudgetCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(radius: 16),
                const SizedBox(width: 8),
                Container(width: 60, height: 12, color: Colors.white),
              ],
            ),
            const Spacer(),
            Container(width: 80, height: 14, color: Colors.white),
            const SizedBox(height: 4),
            Container(width: 100, height: 10, color: Colors.white),
            const SizedBox(height: 8),
            Container(width: double.infinity, height: 4, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
