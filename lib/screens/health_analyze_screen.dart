import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../models/animal_model.dart';
import '../services/api_service.dart';
import '../widgets/floating_nav_bar.dart';
import 'health_result_screen.dart';

class HealthAnalyzeScreen extends StatefulWidget {
  final AnimalModel? animal;
  final List<AnimalModel>? allAnimals;
  final int navIndex;

  const HealthAnalyzeScreen({
    super.key,
    this.animal,
    this.allAnimals,
    this.navIndex = 1,
  });

  @override
  State<HealthAnalyzeScreen> createState() => _HealthAnalyzeScreenState();
}

class _HealthAnalyzeScreenState extends State<HealthAnalyzeScreen>
    with TickerProviderStateMixin {
  static const _bg = Color(0xFFFCFAF5);
  static const _green = Color(0xFF1B5E20);
  static const _orange = Color(0xFFE65100);

  int _step = 0; // 0=Symptom, 1=Detail, 2=Photo, 3=Summary
  AnimalModel? _selectedAnimal;

  // Step 1: Symptoms
  final _symptoms = <String>{};

  // Step 2: Description
  final _descController = TextEditingController();

  // Step 3: Photos (Mandatory Animal Photo)
  final _photos = <XFile>[];
  final _picker = ImagePicker();
  bool _isVerifyingPhoto = false;

  // Submission
  bool _isSubmitting = false;
  late AnimationController _stepAnimController;
  late Animation<double> _stepAnim;

  // Symptom categories using user-provided image assets
  static const _symptomCategories = [
    {
      'id': 'Low Appetite',
      'label': 'Low Appetite',
      'image': 'assets/images/symptom_low_appetite.png',
    },
    {
      'id': 'Fever',
      'label': 'Fever',
      'image': 'assets/images/symptom_fever.png',
    },
    {
      'id': 'Bleeding',
      'label': 'Bleeding',
      'image': 'assets/images/symptom_bleeding.png',
    },
    {
      'id': 'Digestive Issue',
      'label': 'Digestive Issue',
      'image': 'assets/images/symptom_digestive.png',
    },
    {
      'id': 'Low Milk',
      'label': 'Low Milk',
      'image': 'assets/images/symptom_low_milk.png',
    },
    {
      'id': 'Wound',
      'label': 'Wound',
      'image': 'assets/images/symptom_wound.png',
    },
    {
      'id': 'Other',
      'label': 'Other',
      'image': 'assets/images/symptom_other.png',
    },
  ];

  static const _commonObservations = [
    'High body temperature / fever',
    'Refusing to eat fodder / grass',
    'Not drinking sufficient water',
    'Sudden drop in daily milk yield',
    'Lethargic / lying down constantly',
    'Rapid or heavy breathing',
    'Watery discharge from eyes or nose',
    'Limping or difficulty standing',
    'Swelling in stomach or legs',
    'Shivering / body tremors',
  ];

  @override
  void initState() {
    super.initState();
    _selectedAnimal = widget.animal;
    _stepAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _stepAnim = CurvedAnimation(
      parent: _stepAnimController,
      curve: Curves.easeInOut,
    );
    _stepAnimController.forward();
  }

  @override
  void dispose() {
    _descController.dispose();
    _stepAnimController.dispose();
    super.dispose();
  }

  void _goStep(int next) {
    _stepAnimController.reset();
    setState(() => _step = next);
    _stepAnimController.forward();
  }

  bool get _canProceed {
    switch (_step) {
      case 0:
        return _selectedAnimal != null && _symptoms.isNotEmpty;
      case 1:
        return _descController.text.trim().length >= 10;
      case 2:
        return _photos.isNotEmpty && !_isVerifyingPhoto;
      case 3:
        return _photos.isNotEmpty;
      default:
        return false;
    }
  }

  Future<void> _handlePhotoPicked(XFile picked) async {
    setState(() => _isVerifyingPhoto = true);
    try {
      final bytes = await picked.readAsBytes();
      final b64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      final res = await FarmerApiService().verifyAnimalPhoto(
        imageBase64: b64,
        fileName: picked.name,
      );

      if (!mounted) return;
      if (res['isAnimal'] != true) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: const [
                Icon(Icons.gpp_bad_rounded, color: Colors.red, size: 26),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Animal Photo Required',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ),
              ],
            ),
            content: Text(
              res['message'] ??
                  'The uploaded photo was not recognized as a livestock animal. Please upload a clear photo of your cattle, buffalo, goat, or sheep.',
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Try Again',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: _orange)),
              ),
            ],
          ),
        );
        return;
      }

      setState(() => _photos.add(picked));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verified livestock photo (${res['detected'] ?? 'Animal detected'})'),
          backgroundColor: _green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification failed: ${e.toString().replaceAll("Exception:", "").trim()}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isVerifyingPhoto = false);
    }
  }

  Future<void> _pickPhoto() async {
    if (_photos.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 4 photos allowed.'),
          backgroundColor: _orange,
        ),
      );
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38, height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            _photoOptionRow(
              Icons.camera_alt_rounded,
              'Take Photo',
              'Use camera to capture animal now',
              ImageSource.camera,
              ctx,
            ),
            const SizedBox(height: 12),
            _photoOptionRow(
              Icons.photo_library_rounded,
              'Choose from Gallery',
              'Select existing animal photo',
              ImageSource.gallery,
              ctx,
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (picked != null && mounted) {
      await _handlePhotoPicked(picked);
    }
  }

  Future<void> _pickPhotoDirect(ImageSource source) async {
    if (_photos.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 4 photos allowed')),
      );
      return;
    }
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (picked != null && mounted) {
      await _handlePhotoPicked(picked);
    }
  }

  String _getActionButtonText() {
    switch (_step) {
      case 0:
        return _symptoms.isEmpty
            ? 'Select Symptom to Continue'
            : 'Next: Describe Symptoms';
      case 1:
        return _descController.text.trim().length < 10
            ? 'Enter At Least 10 Characters'
            : 'Next: Add Photos';
      case 2:
        if (_isVerifyingPhoto) return 'Verifying Photo with AI...';
        if (_photos.isEmpty) return 'Upload Animal Photo (Mandatory)';
        return 'Next: Review Summary (${_photos.length} Photo${_photos.length == 1 ? '' : 's'})';
      case 3:
        return 'Analyze Health Now';
      default:
        return 'Next';
    }
  }

  Widget _photoOptionRow(
      IconData icon, String title, String subtitle, ImageSource src, BuildContext ctx) {
    return InkWell(
      onTap: () => Navigator.pop(ctx, src),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _green, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800,
                        color: Color(0xFF1B2A1E))),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF757575))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedAnimal == null) return;
    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least 1 animal photo is mandatory for health analysis.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final photoUrls = <String>[];
      for (final p in _photos) {
        final bytes = await p.readAsBytes();
        photoUrls.add('data:image/jpeg;base64,${base64Encode(bytes)}');
      }

      final result = await FarmerApiService().reportHealthCase(
        animalId: _selectedAnimal!.id,
        symptoms: _symptoms.toList(),
        description: _descController.text.trim(),
        photoUrls: photoUrls,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HealthResultScreen(
            caseResult: result,
            animal: _selectedAnimal!,
            navIndex: widget.navIndex,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll('Exception:', '').trim()),
        backgroundColor: Colors.red.shade700,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      extendBody: false,
      bottomNavigationBar: Container(
        color: _bg,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // ── Next / Submit button (Always Visible) ────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _canProceed && !_isSubmitting
                      ? () {
                          if (_step < 3) {
                            _goStep(_step + 1);
                          } else {
                            _submit();
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: _canProceed ? 3 : 0,
                    shadowColor: _orange.withValues(alpha: 0.4),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _getActionButtonText(),
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w900,
                                color: _canProceed
                                    ? Colors.white
                                    : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _step < 3
                                  ? Icons.arrow_forward_rounded
                                  : Icons.health_and_safety_rounded,
                              color: _canProceed
                                  ? Colors.white
                                  : Colors.grey.shade400,
                              size: 22,
                            ),
                          ],
                        ),
                ),
              ),
            ),
              FloatingNavBar(
                currentIndex: widget.navIndex,
                onTap: (i) {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Header ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      if (_step > 0) {
                        _goStep(_step - 1);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.chevron_left_rounded,
                          color: Color(0xFF263238), size: 24),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Health Analyze',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B2A1E),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Step indicator ───────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _StepIndicator(currentStep: _step),
            ),

            const SizedBox(height: 16),

            // ── Step body ────────────────────────────────
            Expanded(
              child: FadeTransition(
                opacity: _stepAnim,
                child: _buildStepBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────── STEP BODY ──────────────────────────
  Widget _buildStepBody() {
    switch (_step) {
      case 0:
        return _step1SelectSymptoms();
      case 1:
        return _step2Description();
      case 2:
        return _step3Photos();
      case 3:
        return _step4Summary();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Step 1 ────────────────────────────────────────────────
  Widget _step1SelectSymptoms() {
    final animals = widget.allAnimals;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Select livestock
          const Text('Select Livestock',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1B2A1E))),
          const SizedBox(height: 8),
          if (animals != null && animals.isNotEmpty)
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
                  hint: const Text('Choose animal...',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  items: animals
                      .map((a) => DropdownMenuItem(
                            value: a,
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(
                                    a.assetImage,
                                    width: 36,
                                    height: 36,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.pets, size: 28,
                                            color: Color(0xFF1B5E20)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text('${a.name} (${a.tagNumber})',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (a) => setState(() => _selectedAnimal = a),
                ),
              ),
            )
          else if (_selectedAnimal != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade200, width: 1.2),
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
                      _selectedAnimal!.assetImage,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.pets, size: 36, color: _green),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_selectedAnimal!.name,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF1B2A1E))),
                      const SizedBox(height: 2),
                      Text(
                          '${_selectedAnimal!.species}  •  ${_selectedAnimal!.tagNumber}',
                          style: const TextStyle(
                              fontSize: 13.5, color: Color(0xFF757575), fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.lock_rounded,
                      size: 18, color: Color(0xFF9E9E9E)),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFE082), width: 1.2),
              ),
              child: const Text(
                'Go back and select an animal first.',
                style: TextStyle(color: _orange, fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),

          const SizedBox(height: 22),
          const Text('Type of Symptoms',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1B2A1E))),
          const SizedBox(height: 4),
          Text('Select one or more that apply.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),

          // 6 primary symptoms in 2 columns
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.02,
            ),
            itemCount: 6,
            itemBuilder: (_, i) => _buildSymptomCard(_symptomCategories[i]),
          ),
          const SizedBox(height: 14),

          // 7th symptom: Other as a full-width card
          _buildOtherSymptomCard(_symptomCategories[6]),
        ],
      ),
    );
  }

  Widget _buildSymptomCard(Map<String, String> cat) {
    final id = cat['id']!;
    final label = cat['label']!;
    final imagePath = cat['image']!;
    final isSelected = _symptoms.contains(id);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _symptoms.remove(id);
          } else {
            _symptoms.add(id);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF8F0) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? _orange : Colors.grey.shade200,
            width: isSelected ? 2.4 : 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? _orange.withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? _orange : const Color(0xFF1B2A1E),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: _orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherSymptomCard(Map<String, String> cat) {
    final id = cat['id']!;
    final label = cat['label']!;
    final imagePath = cat['image']!;
    final isSelected = _symptoms.contains(id);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _symptoms.remove(id);
          } else {
            _symptoms.add(id);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF8F0) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? _orange : Colors.grey.shade200,
            width: isSelected ? 2.4 : 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? _orange.withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Image.asset(
              imagePath,
              width: 50,
              height: 50,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? _orange : const Color(0xFF1B2A1E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Different symptoms or behavioral changes',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected ? _orange : Colors.grey.shade100,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? _orange : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ── Helper: Get symptom asset image ──────────────────────
  String _getSymptomImage(String symptomId) {
    for (final cat in _symptomCategories) {
      if (cat['id'] == symptomId) return cat['image']!;
    }
    return 'assets/images/symptom_other.png';
  }

  // ── Helper: Animal Focus Banner for Steps 2, 3, 4 ─────────
  Widget _buildAnimalFocusBanner() {
    if (_selectedAnimal == null) return const SizedBox.shrink();
    final a = _selectedAnimal!;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
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
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              a.assetImage,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.pets, size: 36, color: _green),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      a.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B2A1E),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        a.species,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Ear Tag: ${a.tagNumber}  •  ${a.breed}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF546E7A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Step ${_step + 1} of 4',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: _orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper: Toggle Quick Observation into Description ─────
  void _toggleObservation(String obs) {
    final current = _descController.text.trim();
    if (current.contains(obs)) {
      var updated = current.replaceAll(obs, '');
      updated = updated.replaceAll(RegExp(r',\s*,'), ',');
      updated = updated.replaceAll(RegExp(r'^\s*,\s*|\s*,\s*$'), '').trim();
      _descController.text = updated;
    } else {
      if (current.isEmpty) {
        _descController.text = obs;
      } else {
        _descController.text = '$current, $obs';
      }
    }
    setState(() {});
  }

  Widget _buildObservationChip(String obs) {
    final isAdded = _descController.text.contains(obs);
    return InkWell(
      onTap: () => _toggleObservation(obs),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isAdded ? const Color(0xFFFFF3E0) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isAdded ? _orange : Colors.grey.shade300,
            width: isAdded ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isAdded
                  ? _orange.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAdded
                  ? Icons.check_circle_rounded
                  : Icons.add_circle_outline_rounded,
              size: 16,
              color: isAdded ? _orange : const Color(0xFF757575),
            ),
            const SizedBox(width: 6),
            Text(
              obs,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isAdded ? FontWeight.w900 : FontWeight.w700,
                color: isAdded ? _orange : const Color(0xFF37474F),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedSymptomsCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Selected Symptoms (${_symptoms.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1B2A1E),
                ),
              ),
              InkWell(
                onTap: () => _goStep(0),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: const [
                      Icon(Icons.edit_rounded, size: 15, color: _orange),
                      SizedBox(width: 4),
                      Text(
                        'Change',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _symptoms.map((s) {
              final img = _getSymptomImage(s);
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8F0),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: _orange.withValues(alpha: 0.35), width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(img,
                        width: 24, height: 24, fit: BoxFit.contain),
                    const SizedBox(width: 8),
                    Text(
                      s,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: _orange,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Step 2 ────────────────────────────────────────────────
  Widget _step2Description() {
    final charCount = _descController.text.trim().length;
    final isReady = charCount >= 10;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Animal context banner
          _buildAnimalFocusBanner(),

          // Section 1: Selected symptoms from Step 1
          _buildSelectedSymptomsCard(),

          const SizedBox(height: 6),

          // Section 2: Quick Observation tags
          Row(
            children: const [
              Icon(Icons.touch_app_rounded, size: 20, color: _orange),
              SizedBox(width: 8),
              Text(
                'Quick Observations',
                style: TextStyle(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1B2A1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap common observations below to add them to your notes:',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF546E7A),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _commonObservations
                .map((obs) => _buildObservationChip(obs))
                .toList(),
          ),

          const SizedBox(height: 20),

          // Section 3: Detailed Notes Input
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Detailed Observations',
                style: TextStyle(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1B2A1E),
                ),
              ),
              Text(
                'Min 10 characters',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isReady ? _green : Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isReady ? const Color(0xFF81C784) : Colors.grey.shade300,
                width: isReady ? 1.6 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _descController,
                  maxLines: 5,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    fontSize: 15.5,
                    height: 1.5,
                    color: Color(0xFF1B2A1E),
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'Tap observations above or type details here (e.g. started 2 days ago, restless behavior, temperature)...',
                    hintStyle: TextStyle(
                      fontSize: 14.5,
                      color: Colors.grey.shade400,
                      height: 1.5,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    border: InputBorder.none,
                  ),
                ),
                Divider(height: 1, color: Colors.grey.shade200),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        isReady
                            ? Icons.check_circle_rounded
                            : Icons.info_outline_rounded,
                        size: 18,
                        color: isReady ? _green : Colors.amber.shade800,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isReady
                            ? 'Ready for diagnosis ($charCount characters)'
                            : 'Need at least ${10 - charCount} more character${10 - charCount == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isReady ? _green : Colors.amber.shade900,
                        ),
                      ),
                      const Spacer(),
                      if (charCount > 0)
                        InkWell(
                          onTap: () {
                            _descController.clear();
                            setState(() {});
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            child: Text(
                              'Clear',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 3 ────────────────────────────────────────────────
  Widget _step3Photos() {
    const slotLabels = [
      'Affected Area / Wound',
      'Face, Eyes & Mouth',
      'Body Posture & Stance',
      'Additional Evidence',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Animal context banner
          _buildAnimalFocusBanner(),

          // Title & subtitle
          Row(
            children: [
              const Text(
                'Upload Livestock Photos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1B2A1E),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _photos.isEmpty
                      ? const Color(0xFFFFEBEE)
                      : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _photos.isEmpty
                        ? Colors.red.shade200
                        : _green.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _photos.isEmpty ? 'MANDATORY' : 'VERIFIED (${_photos.length}/4)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: _photos.isEmpty ? Colors.red.shade800 : _green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'At least 1 photo is strictly required. Antigravity AI inspects and verifies that the photo contains an actual livestock animal.',
            style: TextStyle(
              fontSize: 13.5,
              color: Color(0xFF546E7A),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_isVerifyingPhoto) ...[
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _orange.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: const [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.2, color: _orange),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'AI is verifying animal in photo...',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Quick Action buttons row
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _photos.length < 4
                      ? () => _pickPhotoDirect(ImageSource.camera)
                      : null,
                  icon: const Icon(Icons.camera_alt_rounded, size: 20),
                  label: const Text(
                    'Take Photo',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _photos.length < 4
                      ? () => _pickPhotoDirect(ImageSource.gallery)
                      : null,
                  icon: const Icon(Icons.photo_library_rounded, size: 20),
                  label: const Text(
                    'From Gallery',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _green,
                    side:
                        const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Structured 4-Photo Grid (2x2)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.15,
            ),
            itemCount: 4,
            itemBuilder: (_, index) {
              final hasPhoto = index < _photos.length;
              final slotName = slotLabels[index];

              if (hasPhoto) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.file(
                        File(_photos[index].path),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    // Delete button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _photos.removeAt(index)),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                    // Slot tag badge
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(18)),
                        ),
                        child: Text(
                          slotName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              // Empty slot placeholder
              final isMandatoryFirst = index == 0 && _photos.isEmpty;
              return GestureDetector(
                onTap: _pickPhoto,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isMandatoryFirst ? const Color(0xFFFFF8F0) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isMandatoryFirst ? _orange : Colors.grey.shade300,
                      width: isMandatoryFirst ? 1.8 : 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isMandatoryFirst
                            ? _orange.withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isMandatoryFirst
                              ? const Color(0xFFFFE0B2)
                              : const Color(0xFFF1F8E9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add_a_photo_rounded,
                          color: isMandatoryFirst ? _orange : _green,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        slotName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: isMandatoryFirst ? _orange : const Color(0xFF37474F),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isMandatoryFirst ? '* Required (Min 1)' : '+ Add Photo',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          color: isMandatoryFirst ? Colors.red.shade800 : _orange,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Step 4 ────────────────────────────────────────────────
  Widget _step4Summary() {
    final a = _selectedAnimal;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Review Case Submission',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1B2A1E),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Confirm details below before initiating AI health analysis.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF546E7A),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Main Dossier Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.grey.shade200, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Livestock Header
                if (a != null)
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          a.assetImage,
                          width: 58,
                          height: 58,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.pets, size: 40, color: _green),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  a.name,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1B2A1E),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    a.species,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Ear Tag: ${a.tagNumber}  •  ${a.breed}',
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF546E7A),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Age: ${a.ageYears.toInt()} Years',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF78909C),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => _goStep(0),
                        child: const Icon(Icons.edit_outlined,
                            size: 20, color: _orange),
                      ),
                    ],
                  ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1),
                ),

                // 2. Selected Symptoms
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reported Symptoms (${_symptoms.length})',
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B2A1E),
                      ),
                    ),
                    InkWell(
                      onTap: () => _goStep(0),
                      child: const Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: _orange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _symptoms.map((s) {
                    final img = _getSymptomImage(s);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8F0),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: _orange.withValues(alpha: 0.35), width: 1.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(img,
                              width: 24, height: 24, fit: BoxFit.contain),
                          const SizedBox(width: 8),
                          Text(
                            s,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: _orange,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1),
                ),

                // 3. Observations
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Observations & Notes',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B2A1E),
                      ),
                    ),
                    InkWell(
                      onTap: () => _goStep(1),
                      child: const Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: _orange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FBF9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFFE5EDE6), width: 1.2),
                  ),
                  child: Text(
                    _descController.text.trim().isEmpty
                        ? 'No additional notes provided.'
                        : _descController.text.trim(),
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                      color: Color(0xFF263238),
                    ),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1),
                ),

                // 4. Photos
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Attached Photos (${_photos.length})',
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B2A1E),
                      ),
                    ),
                    InkWell(
                      onTap: () => _goStep(2),
                      child: const Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: _orange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_photos.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.photo_outlined,
                            size: 18, color: Colors.grey),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No photos attached (Analysis will use symptoms & notes)',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF757575),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _photos.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 10),
                      itemBuilder: (_, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          File(_photos[i].path),
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step Indicator ──────────────────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  static const _labels = ['Symptom', 'Detail', 'Photo', 'Summary'];
  static const _green = Color(0xFF1B5E20);
  static const _orange = Color(0xFFE65100);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_labels.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line
          final stepIndex = (i - 1) ~/ 2;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 3,
              decoration: BoxDecoration(
                color: stepIndex < currentStep ? _orange : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }
        final stepIndex = i ~/ 2;
        final isDone = stepIndex < currentStep;
        final isCurrent = stepIndex == currentStep;
        return Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? _green
                    : isCurrent
                        ? _orange
                        : Colors.grey.shade200,
                border: Border.all(
                  color: isCurrent
                      ? _orange
                      : isDone
                          ? _green
                          : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check_rounded,
                        size: 18, color: Colors.white)
                    : Text(
                        '${stepIndex + 1}',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          color: isCurrent ? Colors.white : Colors.grey,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _labels[stepIndex],
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w700,
                color: isCurrent
                    ? _orange
                    : isDone
                        ? _green
                        : Colors.grey.shade600,
              ),
            ),
          ],
        );
      }),
    );
  }
}
