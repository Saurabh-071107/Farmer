import 'package:flutter/material.dart';
import '../models/animal_model.dart';
import '../services/api_service.dart';
import '../services/app_translations.dart';
import '../services/session_manager.dart';
import '../widgets/animal_thumbnail.dart';
import '../widgets/animal_form_bottom_sheet.dart';
import 'animal_detail_screen.dart';

class MyAnimalsScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const MyAnimalsScreen({
    super.key,
    this.onBackToHome,
  });

  @override
  State<MyAnimalsScreen> createState() => _MyAnimalsScreenState();
}

class _MyAnimalsScreenState extends State<MyAnimalsScreen> {
  final FarmerApiService _apiService = FarmerApiService();

  List<AnimalModel> _allAnimals = [];
  bool _isLoading = false;
  String _selectedCategory = 'All'; // 'All' | 'Cow' | 'Buffalo' | 'Goat'

  @override
  void initState() {
    super.initState();
    // Instant 0ms load from memory cache
    _allAnimals = FarmerApiService.getCachedAnimals();
    _isLoading = _allAnimals.isEmpty;
    _fetchLivestock(silent: _allAnimals.isNotEmpty);
  }

  Future<void> _fetchLivestock({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }
    try {
      final animals = await _apiService.getMyAnimals(forceRefresh: true);
      if (mounted) {
        setState(() {
          _allAnimals = animals;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted && !silent) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<AnimalModel> get _filteredAnimals {
    if (_selectedCategory == 'All') return _allAnimals;
    final target = _selectedCategory.toLowerCase();
    return _allAnimals.where((a) {
      final species = a.species.toLowerCase();
      final breed = a.breed.toLowerCase();
      if (target == 'cow') {
        return species.contains('cow') || species.contains('cattle') || breed.contains('gir') || breed.contains('hf') || breed.contains('sahiwal');
      } else if (target == 'buffalo') {
        return species.contains('buffalo') || breed.contains('murrah');
      } else if (target == 'goat') {
        return species.contains('goat') || species.contains('sheep') || breed.contains('boer');
      }
      return species.contains(target);
    }).toList();
  }

  int _countForCategory(String category) {
    if (category == 'All') return _allAnimals.length;
    final target = category.toLowerCase();
    return _allAnimals.where((a) {
      final species = a.species.toLowerCase();
      final breed = a.breed.toLowerCase();
      if (target == 'cow') {
        return species.contains('cow') || species.contains('cattle') || breed.contains('gir') || breed.contains('hf') || breed.contains('sahiwal');
      } else if (target == 'buffalo') {
        return species.contains('buffalo') || breed.contains('murrah');
      } else if (target == 'goat') {
        return species.contains('goat') || species.contains('sheep') || breed.contains('boer');
      }
      return species.contains(target);
    }).length;
  }

  // ---------------------------------------------------------------------------
  // ADD & EDIT LIVESTOCK MODAL SHEET (DRY / Lazy code)
  // ---------------------------------------------------------------------------
  void _openAddAnimalModal() {
    showAnimalFormBottomSheet(
      context,
      onSaved: (_) => _fetchLivestock(),
    );
  }

  void _openEditAnimalModal(AnimalModel animal) {
    showAnimalFormBottomSheet(
      context,
      animalToEdit: animal,
      onSaved: (_) => _fetchLivestock(),
    );
  }

  void _deleteAnimal(AnimalModel animal) async {
    final deleted = await showDeleteAnimalDialog(context, animal);
    if (deleted && mounted) {
      _fetchLivestock();
    }
  }

  // ---------------------------------------------------------------------------
  // ANIMAL DETAILS MODAL (Doctor diagnosis / AI Scan response)
  // Requirement 8: Shows Ongoing Treatment details from Doctor or AI
  // ---------------------------------------------------------------------------
  void _openAnimalDetails(AnimalModel animal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnimalDetailScreen(
          animal: animal,
          initialNavIndex: 1,
          onNavTap: (i) {
            if (widget.onBackToHome != null && i == 0) {
              widget.onBackToHome!();
            }
          },
        ),
      ),
    ).then((_) => _fetchLivestock());
  }


  // ---------------------------------------------------------------------------
  // ADD ANIMAL INPUT FIELD HELPER
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SessionManager(),
      builder: (context, _) {
        final filtered = _filteredAnimals;

        return Scaffold(
          backgroundColor: const Color(0xFFFCFAF5),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // -----------------------------------------------------------------
                // 1. TOP APP BAR (Back Button + "My Livestock" + "+ Add Livestock")
                // -----------------------------------------------------------------
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      // Back Arrow Button
                      InkWell(
                        onTap: () {
                          if (widget.onBackToHome != null) {
                            widget.onBackToHome!();
                          } else {
                            Navigator.maybePop(context);
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.chevron_left_rounded,
                            color: Color(0xFF263238),
                            size: 26,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Screen Title: "My Livestock"
                      Expanded(
                        child: Text(
                          'livestock_title'.tr,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1B2A1E),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),

                      // Orange "+ Add Livestock" Button
                      GestureDetector(
                        onTap: _openAddAnimalModal,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6D00), // Vibrant Orange
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF6D00).withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add, color: Colors.white, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                'add_livestock'.tr,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // -----------------------------------------------------------------
                // 2. CATEGORY FILTER CHIPS ROW (All, Cow, Buffalo, Goat)
                // -----------------------------------------------------------------
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildCategoryChip('All'),
                      const SizedBox(width: 8),
                      _buildCategoryChip('Cow'),
                      const SizedBox(width: 8),
                      _buildCategoryChip('Buffalo'),
                      const SizedBox(width: 8),
                      _buildCategoryChip('Goat'),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // -----------------------------------------------------------------
                // 3. ANIMAL CARDS LIST
                // -----------------------------------------------------------------
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
                        )
                      : filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.pets_outlined, size: 48, color: Colors.grey.shade400),
                                  const SizedBox(height: 8),
                                  Text(
                                    'no_livestock_registered'.tr,
                                    style: const TextStyle(fontSize: 14, color: Color(0xFF757575)),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: _openAddAnimalModal,
                                    icon: const Icon(Icons.add, size: 16),
                                    label: Text('add_animal'.tr),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1B5E20),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchLivestock,
                              color: const Color(0xFF1B5E20),
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                                itemCount: filtered.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final animal = filtered[index];
                                  return _buildAnimalCard(animal);
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // FILTER CHIP WIDGET
  // ---------------------------------------------------------------------------
  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    final count = _countForCategory(category);
    final String label;
    if (category == 'All') {
      label = 'category_all'.tr;
    } else if (category == 'Cow') {
      label = 'cat_cow'.tr;
    } else if (category == 'Buffalo') {
      label = 'cat_buffalo'.tr;
    } else if (category == 'Goat') {
      label = 'cat_goat'.tr;
    } else {
      label = category;
    }

    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = category);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B5E20) : const Color(0xFFF1F8E9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF1B5E20) : const Color(0xFFDCEDC8),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1B5E20).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            '$label ($count)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
              color: isSelected ? Colors.white : const Color(0xFF2E7D32),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LIVESTOCK CARD WIDGET
  // ---------------------------------------------------------------------------
  Widget _buildAnimalCard(AnimalModel animal) {
    final isTreatment = animal.isUnderTreatment;

    // Species badge style
    Color badgeBg;
    Color badgeText;
    final speciesLower = animal.species.toLowerCase();
    if (speciesLower.contains('buffalo')) {
      badgeBg = const Color(0xFFE8F5E9);
      badgeText = const Color(0xFF2E7D32);
    } else if (speciesLower.contains('goat') || speciesLower.contains('sheep')) {
      badgeBg = const Color(0xFFFFEBEE);
      badgeText = const Color(0xFFC62828);
    } else {
      badgeBg = const Color(0xFFFFE0B2);
      badgeText = const Color(0xFFE65100);
    }

    final formattedAge = animal.ageYears % 1 == 0
        ? '${animal.ageYears.toInt()} ${'years'.tr}'
        : '${animal.ageYears} ${'years'.tr}';

    return GestureDetector(
      onTap: () => _openAnimalDetails(animal),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isTreatment ? const Color(0xFFFFCCBC) : Colors.grey.shade200,
            width: isTreatment ? 1.4 : 1.0,
          ),
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
            // Left Image: Animal with lush meadow background
            AnimalThumbnail(
              assetImage: animal.assetImage,
              size: 80,
              borderRadius: 18,
            ),

            const SizedBox(width: 14),

            // Middle Details Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Name + Species Pill
                  Row(
                    children: [
                      Text(
                        animal.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1B2A1E),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          animal.species,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: badgeText,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Row 2: Age • Breed
                  Text(
                    '$formattedAge • ${animal.breed}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF616161),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 3),

                  // Row 3: Ear Tag Number (Farmer visible)
                  Text(
                    '${'ear_tag'.tr}: ${animal.tagNumber}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF757575),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Row 4: Status Indicator (Healthy vs Ongoing Treatment)
                  Row(
                    children: [
                      Icon(
                        isTreatment ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                        size: 15,
                        color: isTreatment ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isTreatment ? 'ongoing_treatment'.tr : 'healthy'.tr,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: isTreatment ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Right Actions: Edit & Delete buttons + Chevron
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => _openEditAnimalModal(animal),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFC8E6C9)),
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _deleteAnimal(animal),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFFCDD2)),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                          color: Color(0xFFC62828),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF9E9E9E),
                  size: 22,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
