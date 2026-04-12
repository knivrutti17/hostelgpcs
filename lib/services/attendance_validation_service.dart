import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AttendanceValidationService {
  AttendanceValidationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<Map<String, dynamic>> getActiveTimeSlot() async {
    final config = await _firestore
        .collection('attendance_config')
        .doc('settings')
        .get();

    if (!config.exists) {
      return {
        'isValid': false,
        'message': 'Attendance configuration not found',
      };
    }

    final data = config.data() ?? <String, dynamic>{};
    final allowAnytime = data['allowAnytime'] == true;

    if (allowAnytime) {
      return {
        'isValid': true,
        'slot': 'Any',
      };
    }

    final now = DateTime.now();
    final morningStart = _parseTimeForToday(data['morning_start']?.toString(), now);
    final morningEnd = _parseTimeForToday(data['morning_end']?.toString(), now);
    final nightStart = _parseTimeForToday(data['night_start']?.toString(), now);
    final nightEnd = _parseTimeForToday(data['night_end']?.toString(), now);

    if (_isWithinBounds(now, morningStart, morningEnd)) {
      return {
        'isValid': true,
        'slot': 'Morning',
      };
    }

    if (_isWithinBounds(now, nightStart, nightEnd)) {
      return {
        'isValid': true,
        'slot': 'Night',
      };
    }

    return {
      'isValid': false,
      'message': 'Attendance slot closed',
    };
  }

  Future<bool> hasAlreadyMarked(
    String uid,
    String date,
    String sessionBase,
  ) async {
    final slotAliases = sessionBase == 'Night'
        ? const ['Night', 'Night Session', 'Manual Night']
        : const ['Morning', 'Morning Session', 'Manual Morning'];

    final snapshot = await _firestore
        .collection('daily_attendance')
        .where('studentUid', isEqualTo: uid)
        .where('date', isEqualTo: date)
        .where('slot', whereIn: slotAliases)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<Map<String, dynamic>> validateMarking({
    required String studentUid,
    required String intendedSession,
  }) async {
    final activeSlotResult = await getActiveTimeSlot();
    if (activeSlotResult['isValid'] != true) {
      return {
        'isValid': false,
        'message': activeSlotResult['message'] ?? 'Attendance slot closed',
      };
    }

    final activeSlot = (activeSlotResult['slot'] ?? '').toString();
    if (activeSlot != 'Any' && activeSlot != intendedSession) {
      return {
        'isValid': false,
        'message': 'Not allowed to mark attendance for this session right now',
      };
    }

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final alreadyMarked =
        await hasAlreadyMarked(studentUid, today, intendedSession);

    if (alreadyMarked) {
      return {
        'isValid': false,
        'message': 'Attendance already marked',
      };
    }

    return {
      'isValid': true,
    };
  }

  DateTime? _parseTimeForToday(String? time, DateTime now) {
    if (time == null || time.trim().isEmpty) return null;

    try {
      final parsed = DateFormat('H:m').parseStrict(time.trim());
      return DateTime(
        now.year,
        now.month,
        now.day,
        parsed.hour,
        parsed.minute,
      );
    } catch (_) {
      return null;
    }
  }

  bool _isWithinBounds(DateTime now, DateTime? start, DateTime? end) {
    if (start == null || end == null) return false;
    return !now.isBefore(start) && !now.isAfter(end);
  }
}
