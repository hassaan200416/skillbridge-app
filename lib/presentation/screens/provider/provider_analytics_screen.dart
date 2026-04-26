
// ---------------------------------------------------------------------------
// provider_analytics_screen.dart
//
// Purpose: Provider performance analytics — metrics, earnings line chart
// with time filter, bookings donut with hover, top services bar chart.
//
// ---------------------------------------------------------------------------

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/booking_model.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/booking_provider.dart';
import '../../../presentation/providers/review_provider.dart';
import '../../../presentation/providers/service_provider.dart';

class ProviderAnalyticsScreen extends ConsumerWidget {
  const ProviderAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final bookingsAsync = ref.watch(providerBookingsProvider(user.id));
    final reviewsAsync = ref.watch(providerReviewsProvider(user.id));
    final servicesAsync = ref.watch(providerServicesProvider(user.id));

    return bookingsAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (bookings) {
        final reviews = reviewsAsync.valueOrNull ?? [];
        final services = servicesAsync.valueOrNull ?? [];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Performance Analytics',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  )),
              const SizedBox(height: 4),
              Text('Review your business metrics and service growth.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.grey500,
                  )),
              const SizedBox(height: 24),
              _MetricCards(bookings: bookings, reviews: reviews),
              const SizedBox(height: 24),
              LayoutBuilder(builder: (context, c) {
                final wide = c.maxWidth > 900;
                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 65,
                        child: _EarningsChart(bookings: bookings),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 35,
                        child: _BookingsDonut(bookings: bookings),
                      ),
                    ],
                  );
                }
                return Column(
                  children: [
                    _EarningsChart(bookings: bookings),
                    const SizedBox(height: 20),
                    _BookingsDonut(bookings: bookings),
                  ],
                );
              }),
              const SizedBox(height: 24),
              _TopServicesChart(bookings: bookings, services: services),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}

// ── Metric Cards ──────────────────────────────────────────────────────────────

class _MetricCards extends StatelessWidget {
  const _MetricCards({required this.bookings, required this.reviews});
  final List<BookingModel> bookings;
  final List reviews;

  @override
  Widget build(BuildContext context) {
    final completed =
        bookings.where((b) => b.status == BookingStatus.completed).toList();
    final totalRevenue =
        completed.fold<double>(0, (sum, b) => sum + b.priceAtBooking);
    final completedCount = completed.length;

    double avgRating = 0;
    if (reviews.isNotEmpty) {
      final total = reviews.fold<int>(0, (sum, r) => sum + (r.rating as int));
      avgRating = total / reviews.length;
    }

    final completionRate =
        bookings.isNotEmpty ? (completedCount / bookings.length * 100) : 0.0;

    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        _Metric(
          icon: Icons.account_balance_wallet_outlined,
          iconBg: const Color(0xFFE0F2FE),
          iconColor: const Color(0xFF0369A1),
          label: 'Total Revenue',
          value: 'PKR ${NumberFormat('#,###').format(totalRevenue)}',
        ),
        _Metric(
          icon: Icons.check_circle_outline,
          iconBg: const Color(0xFFD1FAE5),
          iconColor: const Color(0xFF065F46),
          label: 'Completed Jobs',
          value: '$completedCount',
        ),
        _Metric(
          icon: Icons.star_outline,
          iconBg: const Color(0xFFFEF3C7),
          iconColor: const Color(0xFFD97706),
          label: 'Average Rating',
          value:
              reviews.isEmpty ? 'N/A' : '${avgRating.toStringAsFixed(1)}/5.0',
        ),
        _Metric(
          icon: Icons.trending_up,
          iconBg: AppColors.grey100,
          iconColor: AppColors.grey600,
          label: 'Completion Rate',
          value: '${completionRate.toStringAsFixed(0)}%',
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 280),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
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
            Text(label,
                style:
                    GoogleFonts.inter(fontSize: 12, color: AppColors.grey500)),
            const SizedBox(height: 4),
            Text(value,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                )),
          ],
        ),
      ),
    );
  }
}

// ── Earnings Line Chart with Time Filter ────────────────────────────────────

class _EarningsChart extends StatefulWidget {
  const _EarningsChart({required this.bookings});
  final List<BookingModel> bookings;

  @override
  State<_EarningsChart> createState() => _EarningsChartState();
}

class _EarningsChartState extends State<_EarningsChart> {
  int _months = 6; // default: 6 months

  @override
  Widget build(BuildContext context) {
    final completed = widget.bookings
        .where((b) => b.status == BookingStatus.completed)
        .toList();

    final now = DateTime.now();

    // For 1M: show daily data for last 30 days
    // For 6M/12M: show monthly data
    final bool isDaily = _months == 1;

    List<FlSpot> spots;
    List<DateTime> sortedKeys;

    if (isDaily) {
      // Daily grouping for last 30 days
      final dailyData = <DateTime, double>{};
      for (int i = 29; i >= 0; i--) {
        final day = DateTime(now.year, now.month, now.day - i);
        dailyData[day] = 0;
      }
      for (final b in completed) {
        final key = DateTime(
            b.bookingDate.year, b.bookingDate.month, b.bookingDate.day);
        if (dailyData.containsKey(key)) {
          dailyData[key] = dailyData[key]! + b.priceAtBooking;
        }
      }
      sortedKeys = dailyData.keys.toList()..sort();
      spots = [];
      for (int i = 0; i < sortedKeys.length; i++) {
        spots.add(FlSpot(i.toDouble(), dailyData[sortedKeys[i]]!));
      }
    } else {
      // Monthly grouping
      final cutoff = DateTime(now.year, now.month - _months + 1, 1);
      final monthlyData = <DateTime, double>{};
      for (int i = 0; i < _months; i++) {
        final month = DateTime(now.year, now.month - (_months - 1 - i), 1);
        monthlyData[month] = 0;
      }
      for (final b in completed) {
        if (b.bookingDate.isAfter(cutoff) ||
            b.bookingDate.isAtSameMomentAs(cutoff)) {
          final key = DateTime(b.bookingDate.year, b.bookingDate.month, 1);
          monthlyData[key] = (monthlyData[key] ?? 0) + b.priceAtBooking;
        }
      }
      sortedKeys = monthlyData.keys.toList()..sort();
      spots = [];
      for (int i = 0; i < sortedKeys.length; i++) {
        spots.add(FlSpot(i.toDouble(), monthlyData[sortedKeys[i]]!));
      }
    }

    final maxY = spots.isEmpty
        ? 10000.0
        : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.2;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Earnings Over Time',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        )),
                    const SizedBox(height: 2),
                    Text(
                        isDaily
                            ? 'Daily earnings (PKR) — last 30 days'
                            : 'Monthly earnings (PKR)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.grey500,
                        )),
                  ],
                ),
              ),
              // Time filter chips
              _FilterChip(
                  label: '1M',
                  selected: _months == 1,
                  onTap: () => setState(() => _months = 1)),
              const SizedBox(width: 6),
              _FilterChip(
                  label: '6M',
                  selected: _months == 6,
                  onTap: () => setState(() => _months = 6)),
              const SizedBox(width: 6),
              _FilterChip(
                  label: '12M',
                  selected: _months == 12,
                  onTap: () => setState(() => _months = 12)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: spots.isEmpty || spots.every((s) => s.y == 0)
                ? Center(
                    child: Text('No earnings data for this period',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.grey400)))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY > 0 ? maxY / 4 : 2500,
                        getDrawingHorizontalLine: (v) => FlLine(
                          color: AppColors.divider,
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (v, _) => Text(
                              '${(v / 1000).toStringAsFixed(0)}k',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: AppColors.grey400,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (v, _) {
                              final i = v.toInt();
                              if (i < 0 || i >= sortedKeys.length) {
                                return const SizedBox.shrink();
                              }
                              if (isDaily) {
                                // Show every 5th day label to avoid crowding
                                if (i % 5 != 0 && i != sortedKeys.length - 1) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    DateFormat('d MMM').format(sortedKeys[i]),
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      color: AppColors.grey400,
                                    ),
                                  ),
                                );
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  DateFormat('MMM').format(sortedKeys[i]),
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: AppColors.grey400,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (sortedKeys.length - 1).toDouble().clamp(0, 100),
                      minY: 0,
                      maxY: maxY.clamp(1, double.infinity),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.2,
                          preventCurveOverShooting: true,
                          color: AppColors.primary,
                          barWidth: isDaily ? 2 : 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show:
                                !isDaily, // hide dots on daily view (too many)
                            getDotPainter: (s, _, __, ___) =>
                                FlDotCirclePainter(
                              radius: 4,
                              color: AppColors.primary,
                              strokeWidth: 2,
                              strokeColor: AppColors.white,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.primary.withValues(alpha: 0.08),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (spots) => spots.map((s) {
                            final idx = s.x.toInt();
                            final dateLabel = idx < sortedKeys.length
                                ? (isDaily
                                    ? DateFormat('d MMM yyyy')
                                        .format(sortedKeys[idx])
                                    : DateFormat('MMM yyyy')
                                        .format(sortedKeys[idx]))
                                : '';
                            return LineTooltipItem(
                              '$dateLabel\nPKR ${NumberFormat('#,###').format(s.y)}',
                              GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.grey50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.grey600,
          ),
        ),
      ),
    );
  }
}

// ── Bookings Donut Chart with Touch ─────────────────────────────────────────

class _BookingsDonut extends StatefulWidget {
  const _BookingsDonut({required this.bookings});
  final List<BookingModel> bookings;

  @override
  State<_BookingsDonut> createState() => _BookingsDonutState();
}

class _BookingsDonutState extends State<_BookingsDonut> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final total = widget.bookings.length;
    final completed = widget.bookings
        .where((b) => b.status == BookingStatus.completed)
        .length;
    final pending =
        widget.bookings.where((b) => b.status == BookingStatus.pending).length;
    final confirmed = widget.bookings
        .where((b) => b.status == BookingStatus.confirmed)
        .length;
    final cancelled = widget.bookings
        .where((b) => b.status == BookingStatus.cancelled)
        .length;

    double pct(int v) => total > 0 ? v / total * 100 : 0;

    final sections = [
      _DonutData('Completed', completed, const Color(0xFF065F46)),
      _DonutData('Confirmed', confirmed, AppColors.primary),
      _DonutData('Pending', pending, const Color(0xFFD97706)),
      _DonutData('Cancelled', cancelled, const Color(0xFF991B1B)),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bookings Status',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              )),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
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
                    sectionsSpace: 2,
                    centerSpaceRadius: 50,
                    sections: List.generate(sections.length, (i) {
                      final isTouched = i == _touchedIndex;
                      final data = sections[i];
                      return PieChartSectionData(
                        value: data.count == 0 ? 0.1 : data.count.toDouble(),
                        color: isTouched
                            ? data.color
                            : data.color.withValues(alpha: 0.85),
                        radius: isTouched ? 30 : 20,
                        showTitle: isTouched,
                        title: isTouched
                            ? '${data.count}\n${pct(data.count).toStringAsFixed(0)}%'
                            : '',
                        titleStyle: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        titlePositionPercentageOffset: 0.55,
                        badgeWidget: isTouched
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: data.color,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '${data.label}: ${pct(data.count).toStringAsFixed(0)}%',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : null,
                        badgePositionPercentageOffset: 1.3,
                      );
                    }),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$total',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        )),
                    Text('TOTAL',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.grey500,
                          letterSpacing: 0.8,
                        )),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...sections.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration:
                          BoxDecoration(color: s.color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(s.label,
                          style: GoogleFonts.inter(
                              fontSize: 13, color: AppColors.grey600)),
                    ),
                    Text('${s.count}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary,
                        )),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 36,
                      child: Text('${pct(s.count).toStringAsFixed(0)}%',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary,
                          )),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _DonutData {
  const _DonutData(this.label, this.count, this.color);
  final String label;
  final int count;
  final Color color;
}

// ── Top Services Chart ──────────────────────────────────────────────────────

class _TopServicesChart extends StatelessWidget {
  const _TopServicesChart({required this.bookings, required this.services});
  final List<BookingModel> bookings;
  final List services;

  @override
  Widget build(BuildContext context) {
    final completed =
        bookings.where((b) => b.status == BookingStatus.completed);
    final byService = <String, double>{};
    final serviceNames = <String, String>{};
    for (final b in completed) {
      byService[b.serviceId] = (byService[b.serviceId] ?? 0) + b.priceAtBooking;
      serviceNames[b.serviceId] = b.serviceName ?? 'Service';
    }

    final sorted = byService.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();

    if (top.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Center(
          child: Text('No completed bookings yet',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.grey500)),
        ),
      );
    }

    final maxEarnings = top.first.value;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Performing Services',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              )),
          const SizedBox(height: 4),
          Text('Ranked by revenue',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.grey500)),
          const SizedBox(height: 20),
          ...List.generate(top.length, (i) {
            final entry = top[i];
            final name = serviceNames[entry.key] ?? 'Service';
            final pct = maxEarnings > 0 ? entry.value / maxEarnings : 0.0;
            final colors = [
              AppColors.primary,
              const Color(0xFF0369A1),
              const Color(0xFFD97706),
              const Color(0xFF7C3AED),
              const Color(0xFFDB2777),
            ];

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  // Rank number
                  SizedBox(
                    width: 28,
                    child: Text(
                      '#${i + 1}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: i == 0 ? AppColors.primary : AppColors.grey400,
                      ),
                    ),
                  ),
                  // Bar + labels
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(name,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.secondary,
                                  ),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            Text(
                                'PKR ${NumberFormat('#,###').format(entry.value)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: colors[i % colors.length],
                                )),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 8,
                            backgroundColor: AppColors.grey100,
                            valueColor: AlwaysStoppedAnimation(
                                colors[i % colors.length]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
