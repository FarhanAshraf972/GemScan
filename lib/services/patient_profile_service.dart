import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/patient_profile.dart';

/// Singleton, same lifecycle pattern as LocalAiEngine/CameraOcrService.
/// Persists as a small JSON file in app-private storage — no new
/// dependencies needed, path_provider is already in the project.
class PatientProfileService {
  static final PatientProfileService _instance = PatientProfileService._internal();
  factory PatientProfileService() => _instance;
  PatientProfileService._internal();

  PatientProfile? _cachedProfile;
  bool _hasCheckedDisk = false;

  Future<String> _profileFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/patient_profile.json';
  }

  Future<bool> hasProfile() async {
    if (!_hasCheckedDisk) await _loadFromDisk();
    return _cachedProfile != null;
  }

  Future<PatientProfile> getProfile() async {
    if (!_hasCheckedDisk) await _loadFromDisk();
    return _cachedProfile ?? PatientProfile.empty();
  }

  Future<void> _loadFromDisk() async {
    _hasCheckedDisk = true;
    try {
      final file = File(await _profileFilePath());
      if (!await file.exists()) {
        _cachedProfile = null;
        return;
      }
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      _cachedProfile = PatientProfile.fromJson(json);
    } catch (_) {
      _cachedProfile = null;
    }
  }

  Future<void> saveProfile(PatientProfile profile) async {
    final file = File(await _profileFilePath());
    await file.writeAsString(jsonEncode(profile.toJson()));
    _cachedProfile = profile;
    _hasCheckedDisk = true;
  }
}