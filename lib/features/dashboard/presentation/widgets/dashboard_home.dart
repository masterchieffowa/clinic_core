import 'package:clinic_core/features/auth/presentation/providers/dashboard_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DashboardHome extends ConsumerWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardStatsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(dashboardStatsProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_rounded),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: dashboardStatsAsync.when(
        data: (stats) => _buildDashboardContent(context, stats),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(dashboardStatsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Add new patient
        },
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Patient'),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, DashboardStats stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(context),
          const SizedBox(height: 24),
          _buildStatsCards(context, stats),
          const SizedBox(height: 24),
          _buildChartsSection(context, stats),
          const SizedBox(height: 24),
          _buildBottomSection(context, stats),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(now);
    final timeStr = DateFormat('h:mm a').format(now);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome Back! 👋',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(dateStr, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                timeStr,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context, DashboardStats stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Total in Clinic',
                value: '${stats.totalPatientsInClinic}',
                subtitle: 'of ${stats.maxCapacity}',
                icon: Icons.people_rounded,
                color: Theme.of(context).colorScheme.primary,
                percentage: stats.capacityPercentage,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                title: 'Today\'s Income',
                value: '${stats.todayIncome.toStringAsFixed(0)}',
                subtitle: 'EGP',
                icon: Icons.payments_rounded,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                title: 'New Cases',
                value: '${stats.newCases}',
                subtitle: 'Today',
                icon: Icons.person_add_rounded,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                title: 'Completed',
                value:
                    '${stats.totalPatientsToday - stats.totalPatientsInClinic}',
                subtitle: 'Cases',
                icon: Icons.check_circle_rounded,
                color: Colors.orange,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChartsSection(BuildContext context, DashboardStats stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: constraints.maxWidth * 0.65,
              child: _buildIncomeChart(context, stats),
            ),
            const SizedBox(width: 24),
            SizedBox(
              width: constraints.maxWidth * 0.35 - 24,
              child: _buildCasesSummary(context, stats),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomSection(BuildContext context, DashboardStats stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: constraints.maxWidth * 0.5,
              child: _buildWaitingList(context, stats),
            ),
            const SizedBox(width: 24),
            SizedBox(
              width: constraints.maxWidth * 0.5 - 24,
              child: _buildNextShiftTimer(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIncomeChart(BuildContext context, DashboardStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Income Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text('Last 7 days', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 32),
            SizedBox(
              height: 200,
              child: stats.incomeLastWeek.isEmpty
                  ? Center(
                      child: Text(
                        'No income data yet',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData:
                            FlGridData(show: true, drawVerticalLine: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 50,
                              getTitlesWidget: (value, meta) {
                                return Text('${value.toInt()}',
                                    style: const TextStyle(fontSize: 12));
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const days = [
                                  'Mon',
                                  'Tue',
                                  'Wed',
                                  'Thu',
                                  'Fri',
                                  'Sat',
                                  'Sun'
                                ];
                                if (value.toInt() >= 0 &&
                                    value.toInt() < days.length) {
                                  return Text(days[value.toInt()],
                                      style: const TextStyle(fontSize: 12));
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(
                              stats.incomeLastWeek.length,
                              (index) => FlSpot(index.toDouble(),
                                  stats.incomeLastWeek[index]),
                            ),
                            isCurved: true,
                            color: Colors.teal,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.teal.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCasesSummary(BuildContext context, DashboardStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Cases Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCasesItem('${stats.newCases}', 'New', Colors.teal),
                _buildCasesItem('${stats.oldCases}', 'Old', Colors.grey[800]!),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child:
                  _buildCasesItem('${stats.totalDates}', 'Dates', Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCasesItem(String count, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              count,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildWaitingList(BuildContext context, DashboardStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Waiting List',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            stats.waitingPatients.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text('No waiting patients',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: stats.waitingPatients.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final patient = stats.waitingPatients[index];
                      final isInProgress = patient['status'] == 'in_progress';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor:
                              isInProgress ? Colors.teal : Colors.grey[300],
                          child: Icon(
                            Icons.person,
                            color:
                                isInProgress ? Colors.white : Colors.grey[600],
                          ),
                        ),
                        title: Text(patient['name'] as String),
                        subtitle: Text(patient['appointment_time'] as String),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isInProgress
                                ? Colors.teal.withOpacity(0.1)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isInProgress ? 'In Progress' : 'Waiting',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color:
                                  isInProgress ? Colors.teal : Colors.grey[700],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextShiftTimer(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Next Shift',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTimeUnit('03', 'h', Colors.teal),
                const Text(' : ', style: TextStyle(fontSize: 32)),
                _buildTimeUnit('14', 'm', Colors.blue),
                const Text(' : ', style: TextStyle(fontSize: 32)),
                _buildTimeUnit('23', 's', Colors.orange),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Shift'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeUnit(String value, String unit, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(unit, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double? percentage;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                if (percentage != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${percentage!.toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(title,
                style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(value,
                style:
                    const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            if (percentage != null) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: percentage! / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
