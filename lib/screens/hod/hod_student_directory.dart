import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HODStudentDirectory extends StatefulWidget {
  const HODStudentDirectory({super.key});

  @override
  State<HODStudentDirectory> createState() => _HODStudentDirectoryState();
}

class _HODStudentDirectoryState extends State<HODStudentDirectory> {
  static const Color _primaryTeal = Color(0xFF438A7F);
  static const String _branch = 'Information technology';

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = (snapshot.data?.docs ?? []).where((doc) {
          final data = doc.data();
          final role = (data['role'] ?? '').toString().toLowerCase();
          final branch =
              (data['branch'] ?? data['brach'] ?? '').toString().trim();
          return role == 'student' && branch == _branch;
        }).toList();
        final filteredDocs = docs.where((doc) {
          final data = doc.data();
          final query = _searchQuery.toLowerCase().trim();
          if (query.isEmpty) {
            return true;
          }

          final name = (data['name'] ?? '').toString().toLowerCase();
          final rollNo = (data['rollNo'] ?? '').toString().toLowerCase();
          final roomNo = (data['roomNo'] ?? '').toString().toLowerCase();
          return name.contains(query) ||
              rollNo.contains(query) ||
              roomNo.contains(query);
        }).toList();

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'IT Hostelite Directory',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF22312D),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Search and inspect all hostel student records for Information technology.',
                style: TextStyle(
                  color: Color(0xFF73827E),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by name, roll number, or room',
                            prefixIcon: const Icon(Icons.search_rounded),
                            filled: true,
                            fillColor: const Color(0xFFF6F9F8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (value) =>
                              setState(() => _searchQuery = value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: _primaryTeal.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          '${filteredDocs.length} students',
                          style: const TextStyle(
                            color: _primaryTeal,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 900) {
                      return _buildMobileList(filteredDocs);
                    }
                    return _buildDesktopTable(filteredDocs);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              _primaryTeal.withOpacity(0.08),
            ),
            columns: const [
              DataColumn(label: Text('Roll No')),
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Room No')),
              DataColumn(label: Text('Status')),
            ],
            rows: docs.map((doc) {
              final data = doc.data();
              return DataRow(
                onSelectChanged: (_) => _showStudentDetails(context, data),
                cells: [
                  DataCell(Text((data['rollNo'] ?? '--').toString())),
                  DataCell(Text((data['name'] ?? 'Unknown').toString())),
                  DataCell(Text((data['roomNo'] ?? '--').toString())),
                  DataCell(
                    _statusChip((data['status'] ?? 'Active').toString()),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return ListView.builder(
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data();
        final imageProvider = _decodePhoto(data['photoUrl']?.toString());

        return Card(
          color: Colors.white,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: const EdgeInsets.all(16),
            onTap: () => _showStudentDetails(context, data),
            leading: CircleAvatar(
              radius: 26,
              backgroundColor: _primaryTeal.withOpacity(0.12),
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? const Icon(Icons.person_rounded, color: _primaryTeal)
                  : null,
            ),
            title: Text(
              (data['name'] ?? 'Unknown').toString(),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              'Roll ${data['rollNo'] ?? '--'} • Room ${data['roomNo'] ?? '--'}',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
        );
      },
    );
  }

  Widget _statusChip(String value) {
    final isActive = value.toLowerCase() == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (isActive ? _primaryTeal : Colors.orange).withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: isActive ? _primaryTeal : Colors.orange.shade800,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _showStudentDetails(BuildContext context, Map<String, dynamic> data) {
    final imageProvider = _decodePhoto(data['photoUrl']?.toString());

    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: _primaryTeal.withOpacity(0.12),
                          backgroundImage: imageProvider,
                          child: imageProvider == null
                              ? const Icon(
                                  Icons.person_rounded,
                                  color: _primaryTeal,
                                  size: 34,
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (data['name'] ?? 'Unknown').toString(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF22312D),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Roll No: ${data['rollNo'] ?? '--'}',
                                style: const TextStyle(
                                  color: Color(0xFF73827E),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _DetailTile(
                          label: 'Branch',
                          value:
                              (data['branch'] ?? data['brach'] ?? _branch)
                                  .toString(),
                        ),
                        _DetailTile(
                          label: 'Room Allocation',
                          value: 'Room ${data['roomNo'] ?? '--'}',
                        ),
                        _DetailTile(
                          label: 'Hostel',
                          value: (data['hostel'] ?? 'Not assigned').toString(),
                        ),
                        _DetailTile(
                          label: 'Year',
                          value: (data['year'] ?? 'Not available').toString(),
                        ),
                        _DetailTile(
                          label: 'Phone',
                          value:
                              (data['mobile'] ?? data['phone'] ?? '--').toString(),
                        ),
                        _DetailTile(
                          label: 'Parent Contact',
                          value: (data['parentMobile'] ?? '--').toString(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Submitted Documents',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF22312D),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Expanded(
                          child: _DocumentPlaceholder(
                            title: 'ID Proof',
                            subtitle: 'Preview placeholder',
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _DocumentPlaceholder(
                            title: 'Admission Receipt',
                            subtitle: 'Preview placeholder',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  ImageProvider<Object>? _decodePhoto(String? photoData) {
    if (photoData == null || photoData.isEmpty) {
      return null;
    }

    if (photoData.startsWith('http')) {
      return NetworkImage(photoData);
    }

    try {
      final String cleanBase64 =
          photoData.contains(',') ? photoData.split(',').last : photoData;
      final Uint8List bytes = base64Decode(cleanBase64);
      return MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7B8A87),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF233330),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentPlaceholder extends StatelessWidget {
  const _DocumentPlaceholder({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3ECE9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.description_outlined, color: Color(0xFF438A7F)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF22312D),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF73827E),
            ),
          ),
        ],
      ),
    );
  }
}
