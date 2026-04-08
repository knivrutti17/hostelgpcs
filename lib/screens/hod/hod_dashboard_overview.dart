import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HODDashboardOverview extends StatelessWidget {
  const HODDashboardOverview({super.key});

  static const Color _primaryTeal = Color(0xFF438A7F);
  static const String _branch = 'Information technology';
  static const int _totalItManagedRooms = 50;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Student')
          .where('branch', isEqualTo: _branch)
          .snapshots(),
      builder: (context, studentSnapshot) {
        final studentDocs = studentSnapshot.data?.docs ?? [];
        final int totalStudents = studentDocs.length;
        final int occupiedRooms = studentDocs
            .map((doc) => (doc.data()['roomNo'] ?? '').toString().trim())
            .where((room) => room.isNotEmpty)
            .toSet()
            .length;
        final int vacantRooms =
            math.max(0, _totalItManagedRooms - occupiedRooms);

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('leaves')
              .where('status', isEqualTo: 'Pending')
              .where('branch', isEqualTo: _branch)
              .snapshots(),
          builder: (context, leaveSnapshot) {
            final int pendingLeaves = leaveSnapshot.data?.docs.length ?? 0;

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('complaints')
                  .where('status', isEqualTo: 'Pending')
                  .where('branch', isEqualTo: _branch)
                  .snapshots(),
              builder: (context, complaintSnapshot) {
                final int openComplaints =
                    complaintSnapshot.data?.docs.length ?? 0;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'HOD Dashboard - Academic Year 2025-26',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF233330),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Operational snapshot for Information technology hostelites.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF70807C),
                        ),
                      ),
                      const SizedBox(height: 24),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final bool compact = constraints.maxWidth < 1200;
                          final cards = [
                            _SummaryCardData(
                              title: 'Total IT Students',
                              value: totalStudents.toString(),
                              icon: Icons.groups_rounded,
                              accent: _primaryTeal,
                            ),
                            _SummaryCardData(
                              title: 'Vacant Rooms (IT)',
                              value: vacantRooms.toString(),
                              icon: Icons.meeting_room_rounded,
                              accent: const Color(0xFF2E7DFF),
                            ),
                            _SummaryCardData(
                              title: 'Pending Leaves',
                              value: pendingLeaves.toString(),
                              icon: Icons.event_note_rounded,
                              accent: const Color(0xFFF59E0B),
                            ),
                            _SummaryCardData(
                              title: 'Open Complaints',
                              value: openComplaints.toString(),
                              icon: Icons.campaign_rounded,
                              accent: const Color(0xFFE25B52),
                            ),
                          ];

                          if (compact) {
                            return Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: cards
                                  .map(
                                    (card) => SizedBox(
                                      width: (constraints.maxWidth - 16) / 2,
                                      child: _SummaryCard(data: card),
                                    ),
                                  )
                                  .toList(),
                            );
                          }

                          return Row(
                            children: cards
                                .map(
                                  (card) => Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        right: card == cards.last ? 0 : 16,
                                      ),
                                      child: _SummaryCard(data: card),
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final bool stacked = constraints.maxWidth < 1050;
                          final complaints = _dummyComplaintPreview;
                          final leaves = _dummyLeavePreview;

                          if (stacked) {
                            return Column(
                              children: [
                                _PreviewPanel(
                                  title: 'Preview of Pending Complaints',
                                  items: complaints,
                                ),
                                const SizedBox(height: 16),
                                _PreviewPanel(
                                  title: 'Preview of Pending Leaves',
                                  items: leaves,
                                ),
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _PreviewPanel(
                                  title: 'Preview of Pending Complaints',
                                  items: complaints,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _PreviewPanel(
                                  title: 'Preview of Pending Leaves',
                                  items: leaves,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _SummaryCardData {
  final String title;
  final String value;
  final IconData icon;
  final Color accent;

  const _SummaryCardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
  });
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});

  final _SummaryCardData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: data.accent.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: data.accent.withOpacity(0.12),
              child: Icon(data.icon, color: data.accent),
            ),
            const SizedBox(height: 18),
            Text(
              data.value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF21312E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              data.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF73827E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({
    required this.title,
    required this.items,
  });

  final String title;
  final List<_PreviewItemData> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF233330),
              ),
            ),
            const SizedBox(height: 18),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _PreviewRow(item: item),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.item});

  final _PreviewItemData item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: item.pillColor.withOpacity(0.16),
          child: Text(
            item.name.isNotEmpty ? item.name.substring(0, 1).toUpperCase() : '?',
            style: TextStyle(
              color: item.pillColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF22312D),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF73827E),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: item.pillColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            item.tag,
            style: TextStyle(
              color: item.pillColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewItemData {
  final String name;
  final String subtitle;
  final String tag;
  final Color pillColor;

  const _PreviewItemData({
    required this.name,
    required this.subtitle,
    required this.tag,
    required this.pillColor,
  });
}

const List<_PreviewItemData> _dummyComplaintPreview = [
  _PreviewItemData(
    name: 'Ajay Mehta',
    subtitle: 'Room B-102',
    tag: 'Critical',
    pillColor: Color(0xFFE25B52),
  ),
  _PreviewItemData(
    name: 'Neha Sharma',
    subtitle: 'Room A-104',
    tag: 'Water Leakage',
    pillColor: Color(0xFFF59E0B),
  ),
  _PreviewItemData(
    name: 'Rahul Mishra',
    subtitle: 'Room A-105',
    tag: 'Medium',
    pillColor: Color(0xFF2E9E6F),
  ),
];

const List<_PreviewItemData> _dummyLeavePreview = [
  _PreviewItemData(
    name: 'Viraj Janardhan Gadhe',
    subtitle: 'Room 311',
    tag: 'Medical Leave',
    pillColor: Color(0xFFF59E0B),
  ),
  _PreviewItemData(
    name: 'Krushna Ghuge',
    subtitle: 'Room 214',
    tag: 'Family Function',
    pillColor: Color(0xFF438A7F),
  ),
  _PreviewItemData(
    name: 'Sneha Jadhav',
    subtitle: 'Room 118',
    tag: 'Going Home',
    pillColor: Color(0xFF2E7DFF),
  ),
];
