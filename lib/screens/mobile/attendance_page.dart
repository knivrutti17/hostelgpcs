import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gpcs_hostel_portal/services/attendance_validation_service.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});
  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final AttendanceValidationService _attendanceValidationService =
      AttendanceValidationService();
  bool _isLoading = false;
  String _loadingMessage = "";

  String _formatError(Object error) {
    if (error is LocalAuthException) {
      return error.code.name;
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
  }

  Future<bool> _authenticateWithBiometrics() async {
    final bool isDeviceSupported = await _localAuth.isDeviceSupported();
    final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;

    if (!isDeviceSupported || !canCheckBiometrics) {
      throw "Fingerprint authentication is not available on this device.";
    }

    final List<BiometricType> availableBiometrics = await _localAuth.getAvailableBiometrics();
    final bool hasFingerprintSupport =
        availableBiometrics.contains(BiometricType.fingerprint) ||
        availableBiometrics.contains(BiometricType.strong);

    if (!hasFingerprintSupport) {
      throw "No fingerprint biometric is enrolled on this device.";
    }

    try {
      final bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Scan fingerprint to mark attendance',
        biometricOnly: true,
      );
      return authenticated;
    } on LocalAuthException catch (error) {
      print("Biometric error: ${error.code}");
      return false;
    }
  }

  Future<void> _showSuccessDialog(String slot) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.verified, color: Color(0xFF00897B)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Attendance Marked',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          '$slot attendance has been marked Present and verified by biometric authentication.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFF00897B)),
            ),
          ),
        ],
      ),
    );
  }

  String _resolveStudentSessionBase(
    Map<String, dynamic> configData,
    Map<String, dynamic> activeSlotResult,
  ) {
    final activeSlot = (activeSlotResult['slot'] ?? '').toString();
    if (activeSlot == 'Morning' || activeSlot == 'Night') {
      return activeSlot;
    }

    final now = DateTime.now();
    final nightStart = _parseTimeForToday(
      configData['night_start']?.toString(),
      now,
    );

    if (nightStart != null && !now.isBefore(nightStart)) {
      return 'Night';
    }

    return 'Morning';
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

  Future<void> _markAttendance() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = "Preparing attendance check...";
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? rollNo = prefs.getString('user_roll');

      if (rollNo == null) throw "Session expired. Please log in again.";

      final config = await FirebaseFirestore.instance
          .collection('attendance_config')
          .doc('settings')
          .get();
      if (!config.exists) throw "Attendance configuration not found.";

      final configData = config.data() ?? <String, dynamic>{};
      final double hostelLatitude = (configData['latitude'] ?? 0.0).toDouble();
      final double hostelLongitude =
          (configData['longitude'] ?? 0.0).toDouble();
      final double radius = (config.data()?['radius'] ?? 100.0).toDouble();

      final activeSlotResult =
          await _attendanceValidationService.getActiveTimeSlot();
      final intendedSession =
          _resolveStudentSessionBase(configData, activeSlotResult);
      final validationResult =
          await _attendanceValidationService.validateMarking(
        studentUid: rollNo,
        intendedSession: intendedSession,
      );

      if (validationResult['isValid'] != true) {
        throw (validationResult['message'] ?? 'Unable to mark attendance')
            .toString();
      }

      setState(() {
        _loadingMessage = "Verifying your GPS location...";
      });

      final bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationServiceEnabled) {
        throw "Location services are turned off.";
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw "Location permissions are denied.";
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        hostelLatitude,
        hostelLongitude,
      );

      print("User Lat: ${position.latitude}");
      print("User Lng: ${position.longitude}");
      print("Hostel Lat: $hostelLatitude");
      print("Hostel Lng: $hostelLongitude");
      print("Distance: $distance");

      if (distance > radius) {
        throw "You must be within ${radius.toStringAsFixed(0)}m. Current distance: ${distance.toStringAsFixed(0)}m.";
      }

      setState(() {
        _loadingMessage = "Location verified. Confirm your fingerprint...";
      });

      final bool isAuthenticated = await _authenticateWithBiometrics();
      if (!isAuthenticated) {
        _showErrorSnackBar("Fingerprint verification failed or was cancelled.");
        return;
      }

      setState(() {
        _loadingMessage = "Saving your attendance...";
      });

      await FirebaseFirestore.instance.collection('daily_attendance').add({
        'studentUid': rollNo,
        'status': 'Present',
        'verifiedBy': 'Biometric',
        'slot': intendedSession,
        'timestamp': FieldValue.serverTimestamp(),
        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      });

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _loadingMessage = "";
      });

      await _showSuccessDialog(intendedSession);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorSnackBar(_formatError(e));
    } finally {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
          _loadingMessage = "";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("GPS Attendance", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00897B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, size: 100, color: Color(0xFF00897B)),
              const SizedBox(height: 30),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  _isLoading
                      ? _loadingMessage
                      : "Verify your location and fingerprint to mark attendance",
                  key: ValueKey(_loadingMessage.isEmpty ? 'idle' : _loadingMessage),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: _isLoading ? const Color(0xFF00897B) : Colors.grey,
                    fontWeight: _isLoading ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _markAttendance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    disabledBackgroundColor: const Color(0xFF00897B).withOpacity(0.7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 5,
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              "PROCESSING...",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          "MARK ATTENDANCE",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
