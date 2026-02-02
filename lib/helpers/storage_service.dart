import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AlarmModel {
  final String id;
  final String time;
  final String date;
  final bool isActive;
  final DateTime dateTime;
  final String? location;

  AlarmModel({
    required this.id,
    required this.time,
    required this.date,
    required this.isActive,
    required this.dateTime,
    this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'time': time,
      'date': date,
      'isActive': isActive,
      'dateTime': dateTime.toIso8601String(),
      'location': location,
    };
  }

  factory AlarmModel.fromMap(Map<String, dynamic> map) {
    return AlarmModel(
      id: map['id'] as String? ?? '',
      time: map['time'] as String? ?? '',
      date: map['date'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? false,
      dateTime: DateTime.parse(map['dateTime'] as String? ?? DateTime.now().toIso8601String()),
      location: map['location'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory AlarmModel.fromJson(String source) =>
      AlarmModel.fromMap(json.decode(source) as Map<String, dynamic>);
}

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _alarmsKey = 'alarms_list';

  Future<void> saveAlarms(List<AlarmModel> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> alarmsJson = alarms.map((alarm) => alarm.toJson()).toList();
    await prefs.setStringList(_alarmsKey, alarmsJson);
  }

  Future<List<AlarmModel>> loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? alarmsJson = prefs.getStringList(_alarmsKey);

    if (alarmsJson == null) {
      return [];
    }

    return alarmsJson.map((json) => AlarmModel.fromJson(json)).toList();
  }

  Future<void> saveLocation(String location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_location', location);
  }

  Future<String?> loadLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_location');
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<void> removeAlarm(String id) async {
    final alarms = await loadAlarms();
    final filteredAlarms = alarms.where((alarm) => alarm.id != id).toList();
    await saveAlarms(filteredAlarms);
  }

  Future<void> updateAlarm(AlarmModel updatedAlarm) async {
    final alarms = await loadAlarms();
    final index = alarms.indexWhere((alarm) => alarm.id == updatedAlarm.id);

    if (index != -1) {
      alarms[index] = updatedAlarm;
      await saveAlarms(alarms);
    }
  }
}