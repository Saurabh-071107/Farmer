import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/animal_model.dart';
import '../services/api_service.dart';

class QueueIntakeData {
  final AnimalModel animal;
  final List<String> symptoms;
  final String description;
  final List<String> photoPaths;

  QueueIntakeData({
    required this.animal,
    required this.symptoms,
    required this.description,
    required this.photoPaths,
  });
}

/// Opens the pre-queue clinical intake sheet.
/// Asks the farmer for symptoms, description, and photos BEFORE joining the live doctor queue.
Future<QueueIntakeData?> showQueueIntakeBottomSheet(
  BuildContext context, {
  required Map<String, dynamic> doctor,
  AnimalModel? preselectedAnimal,
}) {
  return showModalBottomSheet<QueueIntakeData>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _QueueIntakeSheet(
      doctor: doctor,
      preselectedAnimal: preselectedAnimal,
    ),
  );
}

class _QueueIntakeSheet extends StatefulWidget {
  final Map<String, dynamic> doctor;
  final AnimalModel? preselectedAnimal;

  const _QueueIntakeSheet({
    required this.doctor,
    this.preselectedAnimal,
  });

  @override
  State<_QueueIntakeSheet> createState() => _QueueIntakeSheetState();
}

class _QueueIntakeSheetState extends State<_QueueIntakeSheet> {
  static const Color _green = Color(0xFF1B5E20);
  static const Color _orange = Color(0xFFFF6D00);

  final TextEditingController _descController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  late List<AnimalModel> _availableAnimals;
  AnimalModel? _selectedAnimal;

  final Set<String> _selectedSymptoms = {};
  final List<String> _photos = [];

  String? _validationError;

  // Curated list of common livestock symptoms
  static const List<Map<String, dynamic>> _symptomOptions = [
    {'name': 'High Fever', 'icon': Icons.thermostat_rounded, 'label': 'Fever'},
    {'name': 'Loss of Appetite', 'icon': Icons.grass_rounded, 'label': 'Low Appetite'},
    {'name': 'Digestive Issue', 'icon': Icons.bubble_chart_rounded, 'label': 'Digestive'},
    {'name': 'Sudden Milk Drop', 'icon': Icons.water_drop_outlined, 'label': 'Low Milk'},
    {'name': 'Wound / Injury', 'icon': Icons.healing_rounded, 'label': 'Wound'},
    {'name': 'Bleeding', 'icon': Icons.bloodtype_outlined, 'label': 'Bleeding'},
    {'name': 'Limping / Inability to Stand', 'icon': Icons.accessibility_new_rounded, 'label': 'Limping'},
    {'name': 'Cough / Heavy Breathing', 'icon': Icons.air_rounded, 'label': 'Coughing'},
    {'name': 'Eye / Nose Discharge', 'icon': Icons.remove_red_eye_outlined, 'label': 'Discharge'},
    {'name': 'Body Shivering / Tremors', 'icon': Icons.vibration_rounded, 'label': 'Shivering'},
    {'name': 'Other Symptoms', 'icon': Icons.help_outline_rounded, 'label': 'Other'},
  ];

  @override
  void initState() {
    super.initState();
    _availableAnimals = FarmerApiService.getCachedAnimals();
    if (widget.preselectedAnimal != null) {
      _selectedAnimal = widget.preselectedAnimal;
    } else if (_availableAnimals.isNotEmpty) {
      _selectedAnimal = _availableAnimals.first;
    } else {
      _selectedAnimal = AnimalModel(
        id: 'livestock-default',
        tagNumber: 'MH-LIVE-01',
        ownerId: 'farmer-default',
        name: 'Gauri',
        species: 'Cow',
        breed: 'Gir Cow',
        ageYears: 3.0,
        gender: 'Female',
        lactationStage: 'Mid Lactation',
        dailyMilkYieldLiters: 12.0,
        photoUrl: 'assets/images/animal_cow.png',
        vaccinationStatus: 'Up to Date',
        healthStatus: 'Healthy',
      );
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (_photos.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 4 photos allowed')),
      );
      return;
    }
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (picked != null && mounted) {
        setState(() {
          _photos.add(picked.path);
          _validationError = null;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showPhotoSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const Text(
              'Add Animal Photo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1B2A1E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Take a photo of the affected area or select from gallery.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: _green),
              ),
              title: const Text('Take Photo with Camera',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.camera);
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library_rounded, color: _orange),
              ),
              title: const Text('Choose from Gallery',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onConfirmAndJoin() {
    final effectiveSymptoms = _selectedSymptoms.isNotEmpty
        ? _selectedSymptoms.toList()
        : ['General Clinical Checkup'];
    final effectiveDesc = _descController.text.trim().isNotEmpty
        ? _descController.text.trim()
        : 'Live veterinary triage tele-consultation request via queue';

    if (_selectedAnimal == null) {
      if (_availableAnimals.isNotEmpty) {
        _selectedAnimal = _availableAnimals.first;
      } else {
        _selectedAnimal = AnimalModel(
          id: 'livestock-default',
          tagNumber: 'MH-LIVE-01',
          ownerId: 'farmer-default',
          name: 'Gauri',
          species: 'Cow',
          breed: 'Gir Cow',
          ageYears: 3.0,
          gender: 'Female',
          lactationStage: 'Mid Lactation',
          dailyMilkYieldLiters: 12.0,
          photoUrl: 'assets/images/animal_cow.png',
          vaccinationStatus: 'Up to Date',
          healthStatus: 'Healthy',
        );
      }
    }

    final data = QueueIntakeData(
      animal: _selectedAnimal!,
      symptoms: effectiveSymptoms,
      description: effectiveDesc,
      photoPaths: List<String>.from(_photos),
    );

    Navigator.pop(context, data);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isWide ? 580 : double.infinity,
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        child: Container(
          margin: EdgeInsets.only(
            top: 24,
            left: isWide ? 16 : 0,
            right: isWide ? 16 : 0,
            bottom: bottomInset > 0 ? bottomInset : 0,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFCFAF5),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(28),
              bottom: isWide ? const Radius.circular(28) : Radius.zero,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 24,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top drag pill
              Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // Scrollable form content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header & Doctor Preview
                      _buildDoctorHeader(),

                      const SizedBox(height: 16),

                      // Animal Selection Section
                      _buildAnimalSelector(),

                      const SizedBox(height: 18),

                      // Symptoms Selection Section
                      _buildSymptomsSection(),

                      const SizedBox(height: 18),

                      // Description TextField
                      _buildDescriptionInput(),

                      const SizedBox(height: 18),

                      // Photo upload section
                      _buildPhotoSection(),

                      if (_validationError != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFCDD2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Color(0xFFC62828), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _validationError!,
                                  style: const TextStyle(
                                    color: Color(0xFFC62828),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 22),

                      // Join Queue Button
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. DOCTOR PREVIEW & HEADER
  // ---------------------------------------------------------------------------
  Widget _buildDoctorHeader() {
    final docName = widget.doctor['name']?.toString() ?? 'Dr. Anand Sharma';
    final docSpecialization = widget.doctor['specialization']?.toString() ??
        widget.doctor['role']?.toString() ??
        'Veterinary Officer';
    final docImg = widget.doctor['image']?.toString() ?? 'assets/images/doctor_1.png';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              docImg,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 50,
                height: 50,
                color: const Color(0xFFE8F5E9),
                child: const Icon(Icons.person, color: _green),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flash_on_rounded, color: _green, size: 12),
                          SizedBox(width: 2),
                          Text(
                            'LIVE QUEUE INTAKE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: _green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  docName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1B2A1E),
                  ),
                ),
                Text(
                  docSpecialization,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. ANIMAL SELECTOR
  // ---------------------------------------------------------------------------
  Widget _buildAnimalSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '1. Select Animal Patient',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1B2A1E),
              ),
            ),
            Text(
              'Required',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_availableAnimals.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300, width: 1.2),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<AnimalModel>(
                isExpanded: true,
                value: _selectedAnimal,
                items: _availableAnimals.map((a) {
                  return DropdownMenuItem<AnimalModel>(
                    value: a,
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            a.assetImage,
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(Icons.pets, color: _green),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${a.name} (${a.species} • ${a.tagNumber})',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1B2A1E),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedAnimal = val);
                },
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.pets, color: _green, size: 26),
                const SizedBox(width: 10),
                Text(
                  _selectedAnimal?.name ?? 'Livestock',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 3. SYMPTOMS SELECTION (MULTI-SELECT CHIPS)
  // ---------------------------------------------------------------------------
  Widget _buildSymptomsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '2. What Symptoms Does Animal Have?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1B2A1E),
              ),
            ),
            if (_selectedSymptoms.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_selectedSymptoms.length} selected',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _green,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Select all that apply so the doctor can prepare immediate triage.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _symptomOptions.map((opt) {
            final name = opt['name'] as String;
            final label = opt['label'] as String;
            final icon = opt['icon'] as IconData;
            final isSelected = _selectedSymptoms.contains(name);

            return FilterChip(
              avatar: Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : const Color(0xFF2E7D32),
              ),
              label: Text(label),
              labelStyle: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFF1B2A1E),
              ),
              selected: isSelected,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selectedSymptoms.add(name);
                  } else {
                    _selectedSymptoms.remove(name);
                  }
                  _validationError = null;
                });
              },
              backgroundColor: Colors.white,
              selectedColor: _green,
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: isSelected ? _green : Colors.grey.shade300,
                width: 1.2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 4. DESCRIPTION INPUT
  // ---------------------------------------------------------------------------
  Widget _buildDescriptionInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '3. Problem Description (Optional)',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1B2A1E),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300, width: 1.2),
          ),
          child: TextField(
            controller: _descController,
            maxLines: 3,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'e.g. Animal is not eating since yesterday morning and has mild shivering...',
              hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
              contentPadding: const EdgeInsets.all(14),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 5. PHOTOS SECTION
  // ---------------------------------------------------------------------------
  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '4. Photos of Affected Area',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1B2A1E),
              ),
            ),
            Text(
              '${_photos.length}/4 photos',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Add clear photos of eyes, skin, wound, or posture for quick diagnosis.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 84,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Add photo button
              if (_photos.length < 4)
                InkWell(
                  onTap: _showPhotoSourceDialog,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 84,
                    height: 84,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _orange.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF3E0),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_a_photo_rounded, color: _orange, size: 18),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '+ Add Photo',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: _orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Existing photos
              ..._photos.asMap().entries.map((entry) {
                final idx = entry.key;
                final path = entry.value;

                return Container(
                  width: 84,
                  height: 84,
                  margin: const EdgeInsets.only(right: 10),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: kIsWeb
                              ? Image.network(path, fit: BoxFit.cover)
                              : Image.file(File(path), fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: InkWell(
                          onTap: () {
                            setState(() => _photos.removeAt(idx));
                          },
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.black87,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 6. CONFIRM & JOIN QUEUE BUTTON
  // ---------------------------------------------------------------------------
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _onConfirmAndJoin,
        style: ElevatedButton.styleFrom(
          backgroundColor: _orange,
          foregroundColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_rounded, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text(
              'Join Live Doctor Queue',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(width: 6),
            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}
