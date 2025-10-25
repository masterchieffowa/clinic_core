import 'package:clinic_core/features/patient/presentation/pages/patients_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/patient_entity.dart';
import '../../data/models/patient_model.dart';
import '../../../../core/utils/date_util.dart';

class PatientFormPage extends ConsumerStatefulWidget {
  final PatientEntity? patient;

  const PatientFormPage({super.key, this.patient});

  @override
  ConsumerState<PatientFormPage> createState() => _PatientFormPageState();
}

class _PatientFormPageState extends ConsumerState<PatientFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _chronicDiseasesController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyRelationController = TextEditingController();

  DateTime? _selectedDate;
  String _selectedGender = 'male';
  String? _selectedBloodType;
  bool _isLoading = false;

  final List<String> _bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.patient != null) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final patient = widget.patient!;
    _nameController.text = patient.name;
    _nationalIdController.text = patient.nationalId ?? '';
    _phoneController.text = patient.phone;
    _emailController.text = patient.email ?? '';
    _addressController.text = patient.address ?? '';
    _selectedDate = patient.dateOfBirth;
    _selectedGender = patient.gender;
    _selectedBloodType = patient.bloodType;
    _chronicDiseasesController.text = patient.chronicDiseases ?? '';
    _allergiesController.text = patient.allergies ?? '';
    _emergencyNameController.text = patient.emergencyContactName ?? '';
    _emergencyPhoneController.text = patient.emergencyContactPhone ?? '';
    _emergencyRelationController.text = patient.emergencyContactRelation ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nationalIdController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _chronicDiseasesController.dispose();
    _allergiesController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ??
          DateTime.now().subtract(const Duration(days: 365 * 30)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date of birth')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final age = DateUtil.calculateAge(_selectedDate!);
    final now = DateTime.now();

    final patient = PatientModel(
      patientId: widget.patient?.patientId ?? '',
      nationalId: _nationalIdController.text.isEmpty
          ? null
          : _nationalIdController.text,
      name: _nameController.text.trim(),
      dateOfBirth: _selectedDate!,
      age: age,
      gender: _selectedGender,
      phone: _phoneController.text.trim(),
      email:
          _emailController.text.isEmpty ? null : _emailController.text.trim(),
      address: _addressController.text.isEmpty
          ? null
          : _addressController.text.trim(),
      bloodType: _selectedBloodType,
      chronicDiseases: _chronicDiseasesController.text.isEmpty
          ? null
          : _chronicDiseasesController.text.trim(),
      allergies: _allergiesController.text.isEmpty
          ? null
          : _allergiesController.text.trim(),
      emergencyContactName: _emergencyNameController.text.isEmpty
          ? null
          : _emergencyNameController.text.trim(),
      emergencyContactPhone: _emergencyPhoneController.text.isEmpty
          ? null
          : _emergencyPhoneController.text.trim(),
      emergencyContactRelation: _emergencyRelationController.text.isEmpty
          ? null
          : _emergencyRelationController.text.trim(),
      profilePicture: null,
      createdAt: widget.patient?.createdAt ?? now,
      updatedAt: now,
    );

    final bool success;
    if (widget.patient == null) {
      success =
          await ref.read(patientsProvider.notifier).createPatient(patient);
    } else {
      success =
          await ref.read(patientsProvider.notifier).updatePatient(patient);
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.patient == null
                  ? 'Patient created successfully'
                  : 'Patient updated successfully',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save patient')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.patient != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Patient' : 'Add New Patient'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _savePatient,
              tooltip: 'Save',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Basic Information Section
            _buildSectionTitle('Basic Information'),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter full name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _nationalIdController,
                    label: 'National ID (Optional)',
                    icon: Icons.credit_card,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter phone number';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _emailController,
              label: 'Email (Optional)',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Date of Birth & Gender
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date of Birth',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _selectedDate == null
                            ? 'Select date'
                            : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                        style: TextStyle(
                          color: _selectedDate == null ? Colors.grey : null,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedGender,
                    decoration: InputDecoration(
                      labelText: 'Gender',
                      prefixIcon: Icon(
                        _selectedGender == 'male' ? Icons.male : Icons.female,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedGender = value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Medical Information Section
            _buildSectionTitle('Medical Information'),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _selectedBloodType,
              decoration: InputDecoration(
                labelText: 'Blood Type (Optional)',
                prefixIcon: const Icon(Icons.bloodtype),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _bloodTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) => setState(() => _selectedBloodType = value),
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _chronicDiseasesController,
              label: 'Chronic Diseases (Optional)',
              icon: Icons.healing,
              maxLines: 2,
              hint: 'e.g., Diabetes, Hypertension',
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _allergiesController,
              label: 'Allergies (Optional)',
              icon: Icons.warning_amber,
              maxLines: 2,
              hint: 'e.g., Penicillin, Peanuts',
            ),
            const SizedBox(height: 24),

            // Contact Information Section
            _buildSectionTitle('Address & Emergency Contact'),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _addressController,
              label: 'Address (Optional)',
              icon: Icons.location_on,
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _emergencyNameController,
              label: 'Emergency Contact Name (Optional)',
              icon: Icons.contact_phone,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _emergencyPhoneController,
                    label: 'Emergency Phone (Optional)',
                    icon: Icons.phone_in_talk,
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _emergencyRelationController,
                    label: 'Relation (Optional)',
                    icon: Icons.family_restroom,
                    hint: 'e.g., Father, Mother',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _savePatient,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(isEditMode ? 'Update Patient' : 'Create Patient'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      enabled: !_isLoading,
    );
  }
}
