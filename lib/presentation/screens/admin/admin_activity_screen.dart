// ---------------------------------------------------------------------------
// admin_activity_screen.dart
//
// Purpose: Admin analytics dashboard with real charts. User breakdown
//   pie chart, booking status distribution, category bar chart,
//   monthly booking trend line chart. All from existing providers.
//
// Route: /admin/activity  (inside AdminShell)
//
// ---------------------------------------------------------------------------

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../data/models/booking_model.dart';
import '../../../data/models/service_model.dart';
import '../../../data/models/user_model.dart';
import '../../providers/booking_provider.dart';
import '../../providers/user_provider.dart';
import 'admin_services_screen.dart' show allServicesAdminProvider;

const _kPrimary = Color(0xFF2D9B6F);
const _kBg = Color(0xFFF5F7FA);
const _kBorder = Color(0xFFE2E8F0);
const _kMuted = Color(0xFF64748B);
const _kInk = Color(0xFF0F172A);

const _kBlueFg = Color(0xFF1E40AF);
const _kGreenFg = Color(0xFF065F46);
const _kAmberFg = Color(0xFFD97706);
const _kRedFg = Color(0xFF991B1B);
const _kSlateFg = Color(0xFF334155);

class AdminActivityScreen extends ConsumerWidget {
  const AdminActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);
    final bookingsAsync = ref.watch(getAllBookingsProvider);
    final servicesAsync = ref.watch(allServicesAdminProvider);

    return Container(
      color: _kBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analytics',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: _kInk,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Platform performance and data insights',
              style: GoogleFonts.inter(fontSize: 13.5, color: _kMuted),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _MetricCard(
                  icon: Icons.people_outline,
                  iconBg: const Color(0xFFE0F2FE),
                  iconColor: const Color(0xFF0369A1),
                  label: 'Total Users',
                  valueAsync: usersAsync.whenData((u) => '${u.length}'),
                ),
                _MetricCard(
                  icon: Icons.handyman_outlined,
                  iconBg: const Color(0xFFD1FAE5),
                  iconColor: const Color(0xFF065F46),
                  label: 'Total Services',
                  valueAsync: servicesAsync.whenData((s) => '${s.length}'),
                ),
                _MetricCard(
                  icon: Icons.event_available_outlined,
                  iconBg: const Color(0xFFFEF3C7),
                  iconColor: const Color(0xFFD97706),
                  label: 'Total Bookings',
                  valueAsync: bookingsAsync.whenData((b) => '${b.length}'),
                ),
                _MetricCard(
                  icon: Icons.account_balance_wallet_outlined,
                  iconBg: const Color(0xFFF3E8FF),
                  iconColor: const Color(0xFF7C3AED),
                  label: 'Total Revenue',
                  valueAsync: bookingsAsync.whenData((bookings) {
                    final rev = bookings
                        .where((b) => b.status == BookingStatus.completed)
                        .fold<double>(0, (sum, b) => sum + b.priceAtBooking);
                    return 'PKR ${NumberFormat('#,###').format(rev)}';
                  }),
                ),
              ],
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (ctx, cons) {
                final twoCol = cons.maxWidth >= 900;
                final userChart = _UserPieChart(usersAsync: usersAsync);
                final bookingChart =
                    _BookingPieChart(bookingsAsync: bookingsAsync);
                if (twoCol) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: userChart),
                      const SizedBox(width: 20),
                      Expanded(child: bookingChart),
                    ],
                  );
                }
                return Column(
                  children: [
                    userChart,
                    const SizedBox(height: 20),
                    bookingChart,
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (ctx, cons) {
                final twoCol = cons.maxWidth >= 900;
                final catChart =
                    _CategoryBarChart(servicesAsync: servicesAsync);
                final trendChart =
                    _MonthlyTrendChart(bookingsAsync: bookingsAsync);
                if (twoCol) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: catChart),
                      const SizedBox(width: 20),
                      Expanded(child: trendChart),
                    ],
                  );
                }
                return Column(
                  children: [
                    catChart,
                    const SizedBox(height: 20),
                    trendChart,
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            _TopProvidersCard(
                bookingsAsync: bookingsAsync, usersAsync: usersAsync),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.height = 280,
  });

  final String title;
  final Widget child;
  final String? subtitle;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _kInk,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: GoogleFonts.inter(fontSize: 12, color: _kMuted),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(height: height, child: child),
        ],
      ),
    );
  }
}

class _UserPieChart extends StatefulWidget {
  const _UserPieChart({required this.usersAsync});

  final AsyncValue<List<UserModel>> usersAsync;

  @override
  State<_UserPieChart> createState() => _UserPieChartState();
}

class _UserPieChartState extends State<_UserPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return _ChartCard(
      title: 'User Breakdown',
      subtitle: 'Customers, providers, and admins across the platform',
      child: widget.usersAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _kPrimary)),
        error: (_, __) => Center(
            child: Text('Error loading',
                style: GoogleFonts.inter(color: _kMuted))),
        data: (users) {
          final customers =
              users.where((u) => u.role == UserRole.customer).length;
          final providers =
              users.where((u) => u.role == UserRole.provider).length;
          final admins = users.where((u) => u.role == UserRole.admin).length;
          final total = users.length;

          if (total == 0) {
            return Center(
                child:
                    Text('No users', style: GoogleFonts.inter(color: _kMuted)));
          }

          return Row(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              response == null ||
                              response.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex =
                              response.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    sectionsSpace: 3,
                    centerSpaceRadius: 40,
                    sections: List.generate(3, (i) {
                      final entries = [
                        ('Customers', customers, _kBlueFg),
                        ('Providers', providers, _kPrimary),
                        ('Admins', admins, _kSlateFg),
                      ];
                      final data = entries[i];
                      final isTouched = i == _touchedIndex;
                      final value = data.$2;
                      return PieChartSectionData(
                        value: value.toDouble(),
                        color: isTouched
                            ? data.$3
                            : data.$3.withValues(alpha: 0.85),
                        radius: isTouched ? 54 : 50,
                        title: isTouched ? '$value' : '',
                        titleStyle: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Legend(
                      color: _kBlueFg, label: 'Customers', value: customers),
                  const SizedBox(height: 10),
                  _Legend(
                      color: _kPrimary, label: 'Providers', value: providers),
                  const SizedBox(height: 10),
                  _Legend(color: _kSlateFg, label: 'Admins', value: admins),
                  const SizedBox(height: 14),
                  Text(
                    'Total: $total',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kInk),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BookingPieChart extends StatefulWidget {
  const _BookingPieChart({required this.bookingsAsync});

  final AsyncValue<List<BookingModel>> bookingsAsync;

  @override
  State<_BookingPieChart> createState() => _BookingPieChartState();
}

class _BookingPieChartState extends State<_BookingPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return _ChartCard(
      title: 'Booking Distribution',
      subtitle: 'Live booking mix by current status',
      child: widget.bookingsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _kPrimary)),
        error: (_, __) => Center(
            child: Text('Error loading',
                style: GoogleFonts.inter(color: _kMuted))),
        data: (bookings) {
          final pending =
              bookings.where((b) => b.status == BookingStatus.pending).length;
          final confirmed =
              bookings.where((b) => b.status == BookingStatus.confirmed).length;
          final completed =
              bookings.where((b) => b.status == BookingStatus.completed).length;
          final cancelled =
              bookings.where((b) => b.status == BookingStatus.cancelled).length;
          final total = bookings.length;

          if (total == 0) {
            return Center(
                child: Text('No bookings',
                    style: GoogleFonts.inter(color: _kMuted)));
          }

          return Row(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              response == null ||
                              response.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex =
                              response.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    sectionsSpace: 3,
                    centerSpaceRadius: 40,
                    sections: [
                      if (pending > 0)
                        PieChartSectionData(
                          value: pending.toDouble(),
                          color: _touchedIndex == 0
                              ? _kAmberFg
                              : _kAmberFg.withValues(alpha: 0.85),
                          radius: _touchedIndex == 0 ? 54 : 50,
                          title: _touchedIndex == 0 ? '$pending' : '',
                          titleStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      if (confirmed > 0)
                        PieChartSectionData(
                          value: confirmed.toDouble(),
                          color: _touchedIndex == 1
                              ? _kGreenFg
                              : _kGreenFg.withValues(alpha: 0.85),
                          radius: _touchedIndex == 1 ? 54 : 50,
                          title: _touchedIndex == 1 ? '$confirmed' : '',
                          titleStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      if (completed > 0)
                        PieChartSectionData(
                          value: completed.toDouble(),
                          color: _touchedIndex == 2
                              ? _kBlueFg
                              : _kBlueFg.withValues(alpha: 0.85),
                          radius: _touchedIndex == 2 ? 54 : 50,
                          title: _touchedIndex == 2 ? '$completed' : '',
                          titleStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      if (cancelled > 0)
                        PieChartSectionData(
                          value: cancelled.toDouble(),
                          color: _touchedIndex == 3
                              ? _kRedFg
                              : _kRedFg.withValues(alpha: 0.85),
                          radius: _touchedIndex == 3 ? 54 : 50,
                          title: _touchedIndex == 3 ? '$cancelled' : '',
                          titleStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Legend(color: _kAmberFg, label: 'Pending', value: pending),
                  const SizedBox(height: 10),
                  _Legend(
                      color: _kGreenFg, label: 'Confirmed', value: confirmed),
                  const SizedBox(height: 10),
                  _Legend(
                      color: _kBlueFg, label: 'Completed', value: completed),
                  const SizedBox(height: 10),
                  _Legend(color: _kRedFg, label: 'Cancelled', value: cancelled),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryBarChart extends StatelessWidget {
  const _CategoryBarChart({required this.servicesAsync});

  final AsyncValue<List<ServiceModel>> servicesAsync;

  @override
  Widget build(BuildContext context) {
    return _ChartCard(
      title: 'Services by Category',
      subtitle: 'How the catalog is distributed across categories',
      height: 300,
      child: servicesAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _kPrimary)),
        error: (_, __) => Center(
            child: Text('Error loading',
                style: GoogleFonts.inter(color: _kMuted))),
        data: (services) {
          final counts = <String, int>{};
          for (final service in services) {
            final label = service.category.value.replaceAll('_', ' ');
            counts[label] = (counts[label] ?? 0) + 1;
          }

          if (counts.isEmpty) {
            return Center(
                child: Text('No services',
                    style: GoogleFonts.inter(color: _kMuted)));
          }

          final sorted = counts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final maxVal = sorted.first.value.toDouble();
          final interval = maxVal < 4 ? 1.0 : (maxVal / 4).ceilToDouble();
          final barColors = [
            const Color(0xFF2D9B6F),
            const Color(0xFF0EA5E9),
            const Color(0xFFD97706),
            const Color(0xFF7C3AED),
            const Color(0xFFDC2626),
            const Color(0xFF334155),
          ];

          return BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVal * 1.2,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${sorted[group.x.toInt()].key}\n${rod.toY.toInt()}',
                      GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx >= sorted.length) {
                        return const SizedBox.shrink();
                      }
                      final label = sorted[idx].key;
                      final short = label.length > 6
                          ? '${label.substring(0, 6)}.'
                          : label;
                      return Text(
                        short,
                        style: GoogleFonts.inter(fontSize: 10, color: _kMuted),
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}',
                      style: GoogleFonts.inter(fontSize: 10, color: _kMuted),
                    ),
                  ),
                ),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: interval,
                getDrawingHorizontalLine: (v) =>
                    const FlLine(color: _kBorder, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              barGroups: [
                for (int i = 0; i < sorted.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: sorted[i].value.toDouble(),
                        color: barColors[i % barColors.length],
                        width: 22,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MonthlyTrendChart extends StatelessWidget {
  const _MonthlyTrendChart({required this.bookingsAsync});

  final AsyncValue<List<BookingModel>> bookingsAsync;

  @override
  Widget build(BuildContext context) {
    return _ChartCard(
      title: 'Booking Trend (Monthly)',
      subtitle: 'Bookings created over time',
      height: 300,
      child: bookingsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _kPrimary)),
        error: (_, __) => Center(
            child: Text('Error loading',
                style: GoogleFonts.inter(color: _kMuted))),
        data: (bookings) {
          if (bookings.isEmpty) {
            return Center(
                child: Text('No bookings yet',
                    style: GoogleFonts.inter(color: _kMuted)));
          }

          final monthly = <String, int>{};
          for (final booking in bookings) {
            final key = DateFormat('yyyy-MM').format(booking.createdAt);
            monthly[key] = (monthly[key] ?? 0) + 1;
          }

          final sorted = monthly.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key));
          final display =
              sorted.length > 12 ? sorted.sublist(sorted.length - 12) : sorted;
          final maxY = display
              .map((e) => e.value)
              .reduce((a, b) => a > b ? a : b)
              .toDouble();
          final yInterval = maxY < 4 ? 1.0 : maxY / 4;

          return LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY * 1.2,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots.map((spot) {
                    final entry = display[spot.x.toInt()];
                    return LineTooltipItem(
                      '${entry.key}\n${entry.value} bookings',
                      GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    );
                  }).toList(),
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= display.length) {
                        return const SizedBox.shrink();
                      }
                      final parts = display[idx].key.split('-');
                      final month = DateFormat('MMM').format(
                          DateTime(int.parse(parts[0]), int.parse(parts[1])));
                      return Text(month,
                          style:
                              GoogleFonts.inter(fontSize: 10, color: _kMuted));
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: yInterval,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}',
                      style: GoogleFonts.inter(fontSize: 10, color: _kMuted),
                    ),
                  ),
                ),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: yInterval,
                getDrawingHorizontalLine: (v) =>
                    const FlLine(color: _kBorder, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (int i = 0; i < display.length; i++)
                      FlSpot(i.toDouble(), display[i].value.toDouble()),
                  ],
                  isCurved: true,
                  color: _kPrimary,
                  barWidth: 3,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (s, _, __, ___) => FlDotCirclePainter(
                      radius: 4,
                      color: _kPrimary,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: _kPrimary.withValues(alpha: 0.08),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TopProvidersCard extends StatelessWidget {
  const _TopProvidersCard(
      {required this.bookingsAsync, required this.usersAsync});

  final AsyncValue<List<BookingModel>> bookingsAsync;
  final AsyncValue<List<UserModel>> usersAsync;

  @override
  Widget build(BuildContext context) {
    return _ChartCard(
      title: 'Top Providers by Bookings',
      subtitle: 'Providers with the highest booking volume',
      height: 200,
      child: bookingsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _kPrimary)),
        error: (_, __) => Center(
            child: Text('Error', style: GoogleFonts.inter(color: _kMuted))),
        data: (bookings) {
          final counts = <String, int>{};
          for (final booking in bookings) {
            counts[booking.providerId] = (counts[booking.providerId] ?? 0) + 1;
          }

          if (counts.isEmpty) {
            return Center(
                child: Text('No bookings yet',
                    style: GoogleFonts.inter(color: _kMuted)));
          }

          final sorted = counts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final top5 = sorted.take(5).toList();
          final users =
              usersAsync.maybeWhen(data: (u) => u, orElse: () => <UserModel>[]);
          final nameMap = {for (final user in users) user.id: user.name};
          final maxVal = top5.first.value.toDouble();

          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final entry in top5)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          nameMap[entry.key] ?? 'Provider',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _kInk),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: entry.value / maxVal,
                            minHeight: 18,
                            backgroundColor: _kBg,
                            color: _kPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 30,
                        child: Text(
                          '${entry.value}',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _kInk),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.valueAsync,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final AsyncValue<String> valueAsync;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 280),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(height: 14),
            Text(label, style: GoogleFonts.inter(fontSize: 12, color: _kMuted)),
            const SizedBox(height: 4),
            valueAsync.when(
              loading: () => const SizedBox(
                height: 28,
                width: 28,
                child:
                    CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
              ),
              error: (_, __) => Text('—',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _kInk,
                  )),
              data: (value) => Text(value,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _kInk,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(
      {required this.color, required this.label, required this.value});

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 8),
        Text('$label: ',
            style: GoogleFonts.inter(fontSize: 12, color: _kMuted)),
        Text('$value',
            style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w700, color: _kInk)),
      ],
    );
  }
}
