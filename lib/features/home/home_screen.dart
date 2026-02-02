import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../../../constants/colors.dart';
import '../../../helpers/storage_service.dart';
import '../../../helpers/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final notificationService = NotificationService();
  final StorageService _storageService = StorageService();

  String _selectedLocation = 'Fetching location...';
  bool _hasLocation = false;
  bool _isLoadingLocation = true;

  List<AlarmModel> _alarms = [];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await notificationService.initialize();

    // Request permissions
    bool granted = await notificationService.requestAllPermissions();
    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Allow notifications & "Set alarms & reminders" in settings for alarms to work reliably',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'Open Settings',
            textColor: Colors.white,
            onPressed: () async {
              await openAppSettings();
            },
          ),
        ),
      );
    }

    await _loadAlarms();
    await _getCurrentLocation();

    // Debug: check pending notifications
    await notificationService.printPending();
  }

  Future<void> _loadAlarms() async {
    final savedAlarms = await _storageService.loadAlarms();
    setState(() {
      _alarms = savedAlarms.isNotEmpty ? savedAlarms : [];
    });
  }

  Future<void> _saveAlarms() async {
    await _storageService.saveAlarms(_alarms);
    if (_hasLocation) {
      await _storageService.saveLocation(_selectedLocation);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _isLoadingLocation = true);

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _selectedLocation = 'Location permission denied';
            _hasLocation = false;
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _selectedLocation = 'Location permission permanently denied';
          _hasLocation = false;
          _isLoadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '';

        if (place.street?.isNotEmpty ?? false) address = place.street!;
        if (place.locality?.isNotEmpty ?? false) {
          address += address.isNotEmpty ? ', ${place.locality!}' : place.locality!;
        }
        if (place.administrativeArea?.isNotEmpty ?? false) {
          address += address.isNotEmpty ? ', ${place.administrativeArea!}' : place.administrativeArea!;
        }
        if (place.country?.isNotEmpty ?? false) {
          address += address.isNotEmpty ? ', ${place.country!}' : place.country!;
        }

        setState(() {
          _selectedLocation = address.isNotEmpty
              ? address
              : '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
          _hasLocation = true;
          _isLoadingLocation = false;
        });

        await _storageService.saveLocation(_selectedLocation);
      } else {
        setState(() {
          _selectedLocation =
          '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
          _hasLocation = true;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      print('Location error: $e');
      setState(() {
        _selectedLocation = 'Unable to fetch location';
        _hasLocation = false;
        _isLoadingLocation = false;
      });
    }
  }

  void _addNewAlarm() {
    _showDateTimePicker(context);
  }

  void _showDateTimePicker(BuildContext context) {
    DateTime selectedDateTime = DateTime.now().add(const Duration(minutes: 10));

    Future<void> selectDate() async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDateTime,
        firstDate: DateTime.now(),
        lastDate: DateTime(2100),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF5200FF),
                onPrimary: Colors.white,
                surface: Color(0xFF1E1E1E),
                onSurface: Colors.white,
              ),
              dialogBackgroundColor: const Color(0xFF2D2D2D),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF5200FF)),
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null && mounted) {
        selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          selectedDateTime.hour,
          selectedDateTime.minute,
        );
      }
    }

    Future<void> selectTime() async {
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDateTime),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF5200FF),
                onPrimary: Colors.white,
                surface: Color(0xFF1E1E1E),
                onSurface: Colors.white,
              ),
              dialogBackgroundColor: const Color(0xFF2D2D2D),
            ),
            child: child!,
          );
        },
      );

      if (picked != null && mounted) {
        selectedDateTime = DateTime(
          selectedDateTime.year,
          selectedDateTime.month,
          selectedDateTime.day,
          picked.hour,
          picked.minute,
        );
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Set New Alarm',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter',
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white, size: 24),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D2D2D),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF5200FF).withOpacity(0.3), width: 1),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _formatTimeForPicker(selectedDateTime),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatDateForPicker(selectedDateTime),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              await selectDate();
                              setStateModal(() {});
                            },
                            child: Container(
                              height: 100,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D2D2D),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.calendar_today, color: Color(0xFF5200FF), size: 32),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Select Date',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              await selectTime();
                              setStateModal(() {});
                            },
                            child: Container(
                              height: 100,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D2D2D),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.access_time, color: Color(0xFF5200FF), size: 32),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Select Time',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5200FF), Color(0xFF8A2BE2)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5200FF).withOpacity(0.4),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(28),
                          onTap: () {
                            _saveAlarmToStorage(selectedDateTime);
                            Navigator.pop(context);
                          },
                          child: const Center(
                            child: Text(
                              'SET ALARM',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Inter',
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveAlarmToStorage(DateTime dateTime) async {
    if (!mounted) return;

    if (dateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cannot set alarm in the past"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final hour12 = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final amPm = dateTime.hour < 12 ? 'AM' : 'PM';
    final timeString = '$hour12:$minute $amPm';

    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    final dayName = days[dateTime.weekday - 1];
    final monthName = months[dateTime.month - 1];
    final dateString = '$dayName ${dateTime.day} $monthName ${dateTime.year}';

    final String alarmId = DateTime.now().millisecondsSinceEpoch.toString();

    final newAlarm = AlarmModel(
      id: alarmId,
      time: timeString,
      date: dateString,
      isActive: true,
      dateTime: dateTime,
      location: _hasLocation ? _selectedLocation : null,
    );

    setState(() {
      _alarms.insert(0, newAlarm);
    });

    await _saveAlarms();

    final success = await _scheduleAlarmNotification(newAlarm);

    if (!success && mounted) {
      _showAlarmPermissionGuide();
    }

    // Debug pending
    await notificationService.printPending();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alarm set for $timeString'),
          backgroundColor: const Color(0xFF5200FF),
        ),
      );
    }
  }

  Future<bool> _scheduleAlarmNotification(AlarmModel alarm) async {
    if (!alarm.isActive || alarm.dateTime.isBefore(DateTime.now())) {
      print("Skipped scheduling: not active or past time → ${alarm.id}");
      return false;
    }

    print("Scheduling alarm → ID: ${alarm.id} at ${alarm.dateTime}");

    final success = await notificationService.scheduleAlarmNotification(
      id: alarm.id,
      scheduledDateTime: alarm.dateTime,
      title: 'Travel Alarm',
      body: 'Time: ${alarm.time} • ${alarm.date} ${alarm.location != null ? '• Location: ${alarm.location}' : ''}',
    );

    return success;
  }

  void _toggleAlarm(int index) async {
    final alarm = _alarms[index];

    final updatedAlarm = AlarmModel(
      id: alarm.id,
      time: alarm.time,
      date: alarm.date,
      isActive: !alarm.isActive,
      dateTime: alarm.dateTime,
      location: alarm.location,
    );

    setState(() {
      _alarms[index] = updatedAlarm;
    });

    if (updatedAlarm.isActive && updatedAlarm.dateTime.isAfter(DateTime.now())) {
      final success = await _scheduleAlarmNotification(updatedAlarm);
      if (!success && mounted) {
        _showAlarmPermissionGuide();
      }
    } else if (alarm.isActive) {
      await notificationService.cancelNotification(alarm.id);
      print("Cancelled notification for ID: ${alarm.id}");
    }

    await _saveAlarms();

    await notificationService.printPending();
  }

  void _deleteAlarm(int index) async {
    final alarm = _alarms[index];

    await notificationService.cancelNotification(alarm.id);
    print("Deleted and cancelled ID: ${alarm.id}");

    setState(() {
      _alarms.removeAt(index);
    });

    await _saveAlarms();

    await notificationService.printPending();
  }

  void _showAlarmPermissionGuide() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Exact Alarms May Not Work',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'On Android 13+, exact timed alarms require special permission.\n\n'
              'Go to:\n'
              'Settings → Apps → [Your App] → Alarms & reminders\n'
              '→ Allow setting alarms and reminders',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text('Open Settings', style: TextStyle(color: Color(0xFF5200FF))),
          ),
        ],
      ),
    );
  }

  String _formatDateForPicker(DateTime dateTime) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    final dayName = days[dateTime.weekday - 1];
    final monthName = months[dateTime.month - 1];
    return '$dayName, $monthName ${dateTime.day}, ${dateTime.year}';
  }

  String _formatTimeForPicker(DateTime dateTime) {
    final hour12 = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final amPm = dateTime.hour < 12 ? 'AM' : 'PM';
    return '$hour12:$minute $amPm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppColors.backgroundGradient,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 40, bottom: 12),
                  child: Text(
                    'Selected Location',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),

                Container(
                  width: double.infinity,
                  height: 56,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(61),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8.9, sigmaY: 8.9),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(61),
                        ),
                        child: GestureDetector(
                          onTap: _getCurrentLocation,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(
                              children: [
                                _isLoadingLocation
                                    ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white70,
                                  ),
                                )
                                    : const Icon(
                                  Icons.location_on,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _selectedLocation,
                                    style: TextStyle(
                                      color: _hasLocation ? Colors.white : Colors.white.withOpacity(0.5),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Inter',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.only(top: 40, bottom: 20),
                  child: Text(
                    'Alarms',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),

                Expanded(
                  child: _alarms.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.alarm,
                          color: Colors.white.withOpacity(0.3),
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No alarms set',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the + button to add an alarm',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _alarms.length,
                    itemBuilder: (context, index) {
                      final alarm = _alarms[index];

                      return Container(
                        width: double.infinity,
                        height: 56,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(61),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8.9, sigmaY: 8.9),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFFFF).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(61),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      alarm.time,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          alarm.date,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.7),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Transform.scale(
                                          scale: 0.8,
                                          child: Switch(
                                            value: alarm.isActive,
                                            onChanged: (value) => _toggleAlarm(index),
                                            activeColor: Colors.white,
                                            activeTrackColor: const Color(0xFF5200FF),
                                            inactiveThumbColor: Colors.black,
                                            inactiveTrackColor: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _addNewAlarm,
        backgroundColor: const Color(0xFF5200FF),
        shape: const CircleBorder(),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}