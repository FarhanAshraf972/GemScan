import 'package:flutter/material.dart';
import '../models/patient_profile.dart';
import '../services/patient_profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';

class PatientRegistrationScreen extends StatefulWidget {
  final bool isEditMode;
  final VoidCallback? onSaved;

  const PatientRegistrationScreen({super.key, this.isEditMode = false, this.onSaved});

  @override
  State<PatientRegistrationScreen> createState() => _PatientRegistrationScreenState();
}

class _PatientRegistrationScreenState extends State<PatientRegistrationScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _otherMedsController = TextEditingController();
  final _sleepController = TextEditingController();

  static const _availableConditions = [
    'Diabetes', 'Hypertension', 'Kidney Disease', 'Heart Disease', 'Liver Disease', 'Asthma',
  ];
  final Set<String> _selectedConditions = {};
  String _pregnancyStatus = 'Not Applicable';
  bool _isLoadingExisting = true;

  @override
  void initState() {
    super.initState();
    _loadExistingIfEditing();
  }

  Future<void> _loadExistingIfEditing() async {
    if (widget.isEditMode) {
      final existing = await PatientProfileService().getProfile();
      _nameController.text = existing.name;
      _ageController.text = existing.age?.toString() ?? '';
      _allergiesController.text = existing.allergies;
      _otherMedsController.text = existing.otherMedicines;
      _sleepController.text = existing.sleepSchedule;
      _selectedConditions.addAll(existing.conditions);
      _pregnancyStatus = existing.pregnancyStatus;
    }
    if (mounted) setState(() => _isLoadingExisting = false);
  }

  Future<void> _submit() async {
    final profile = PatientProfile(
      name: _nameController.text.trim(),
      age: int.tryParse(_ageController.text.trim()),
      conditions: _selectedConditions.toList(),
      pregnancyStatus: _pregnancyStatus,
      allergies: _allergiesController.text.trim(),
      otherMedicines: _otherMedsController.text.trim(),
      sleepSchedule: _sleepController.text.trim(),
    );

    await PatientProfileService().saveProfile(profile);
    if (!mounted) return;

    if (widget.isEditMode) {
      Navigator.of(context).pop();
    } else {
      widget.onSaved?.call();
    }
  }

  Future<void> _skip() async {
    await PatientProfileService().saveProfile(PatientProfile.empty());
    if (!mounted) return;
    widget.onSaved?.call();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _allergiesController.dispose();
    _otherMedsController.dispose();
    _sleepController.dispose();
    super.dispose();
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 14)),
      );

  @override
  Widget build(BuildContext context) {
    if (_isLoadingExisting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.isEditMode ? 'Edit Profile' : "Let's know you better")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.isEditMode) ...[
              const AppLogo(size: 48),
              const SizedBox(height: 16),
              const Text("This helps GemScan give you safer advice",
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 24),
            ],

            _sectionLabel("Your name"),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: "e.g. Jane Doe",
                prefixIcon: Icon(Icons.person_outline, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 20),

            _sectionLabel("Age"),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: "e.g. 65",
                prefixIcon: Icon(Icons.cake_outlined, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 24),

            _sectionLabel("Existing conditions"),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableConditions.map((condition) {
                final selected = _selectedConditions.contains(condition);
                return FilterChip(
                  label: Text(condition),
                  selected: selected,
                  showCheckmark: true,
                  checkmarkColor: AppColors.primary,
                  selectedColor: AppColors.primaryLight,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: selected ? AppColors.primaryDark : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: selected ? AppColors.primary : Colors.grey.shade200),
                  ),
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _selectedConditions.add(condition);
                      } else {
                        _selectedConditions.remove(condition);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            _sectionLabel("Pregnancy status"),
            DropdownButtonFormField<String>(
              value: _pregnancyStatus,
              items: const [
                DropdownMenuItem(value: 'Not Applicable', child: Text('Not applicable')),
                DropdownMenuItem(value: 'No', child: Text('No')),
                DropdownMenuItem(value: 'Yes', child: Text('Yes')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _pregnancyStatus = value);
              },
            ),
            const SizedBox(height: 20),

            _sectionLabel("Allergies"),
            TextField(
              controller: _allergiesController,
              decoration: const InputDecoration(hintText: "e.g. Penicillin, Aspirin"),
            ),
            const SizedBox(height: 20),

            _sectionLabel("Other regular medicines (not scanned)"),
            TextField(
              controller: _otherMedsController,
              decoration: const InputDecoration(hintText: "e.g. Metformin, Losartan"),
            ),
            const SizedBox(height: 20),

            _sectionLabel("Sleep schedule"),
            TextField(
              controller: _sleepController,
              decoration: const InputDecoration(hintText: "e.g. 11 PM - 6 AM"),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(16)),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, color: AppColors.primaryDark, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text("Your data is private and stays on this device",
                        style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                child: Text(widget.isEditMode ? "Save Changes" : "Save & Continue"),
              ),
            ),

            if (!widget.isEditMode)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _skip,
                    style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                    child: const Text("Skip for now"),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}