// lib/screens/live_monitoring_screen.dart
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/dummy_data.dart';
import '../widgets/common_widgets.dart';

class LiveMonitoringScreen extends StatelessWidget {
  const LiveMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vitals = DummyData.liveVitals;
    final trend = DummyData.heartRateTrend;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(gradient: AppTheme.headerGradientRed),
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 28),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back,
                            size: 18, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Real-Time Monitoring',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Live health tracking',
                          style: TextStyle(
                              fontSize: 13, color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
                // Live badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Live',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Vitals Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    children: [
                      VitalCard(
                        icon: Icons.favorite_outline,
                        iconColor: AppTheme.highRisk,
                        bgColor: const Color(0xFFFFF1F2),
                        value: '${vitals.heartRate}',
                        label: 'Heart Rate (bpm)',
                      ),
                      VitalCard(
                        icon: Icons.monitor_heart_outlined,
                        iconColor: AppTheme.primaryBlue,
                        bgColor: const Color(0xFFEFF6FF),
                        value: vitals.bloodPressure,
                        label: 'Blood Pressure (mmHg)',
                      ),
                      VitalCard(
                        icon: Icons.local_fire_department_outlined,
                        iconColor: AppTheme.mediumRisk,
                        bgColor: const Color(0xFFFFFBEB),
                        value: '${vitals.temperature}',
                        label: 'Temperature (°F)',
                      ),
                      VitalCard(
                        icon: Icons.air_outlined,
                        iconColor: AppTheme.primaryGreen,
                        bgColor: const Color(0xFFECFDF5),
                        value: '${vitals.oxygenLevel}',
                        label: 'Oxygen Level (%)',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // All Vitals Normal
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.info_outline_rounded,
                            color: AppTheme.primaryGreen,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'All Vitals Normal',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                            Text(
                              'Your health metrics are within healthy ranges',
                              style: TextStyle(
                                  fontSize: 12, color: AppTheme.primaryGreen),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Heart Rate Trend Chart
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.favorite_outline,
                                    color: AppTheme.highRisk, size: 18),
                                const SizedBox(width: 6),
                                const Text(
                                  'Heart Rate Trend',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                              ],
                            ),
                            const Text(
                              'Last 30 minutes',
                              style: TextStyle(
                                  fontSize: 11, color: AppTheme.textGrey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Simple bar chart
                        SizedBox(
                          height: 100,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: trend.map((point) {
                              final value = point['value'] as int;
                              final normalized = (value - 60) / 40;
                              return Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        '$value',
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: AppTheme.textGrey,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        height: 80 * normalized,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFEF4444),
                                              Color(0xFFFCA5A5),
                                            ],
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                          ),
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(4),
                                            topRight: Radius.circular(4),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: trend
                              .map((p) => Text(
                                    p['time'],
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: AppTheme.textGrey,
                                    ),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _trendStat('Average', '74 bpm'),
                            _trendStat('Min', '71 bpm'),
                            _trendStat('Max', '76 bpm'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _trendStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textGrey),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }
}
