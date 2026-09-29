import 'package:flutter/material.dart';
import '../models/animal_model.dart';
import '../services/api_service.dart';
import '../services/app_translations.dart';

/// Opens a shared bottom sheet to either Add a new animal or Edit an existing one.
/// Adheres strictly to DRY / Lazy principles.
Future<AnimalModel?> showAnimalFormBottomSheet(
  BuildContext context, {
  AnimalModel? animalToEdit,
  ValueChanged<AnimalModel>? onSaved,
}) {
  return showModalBottomSheet<AnimalModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AnimalFormSheet(
      animalToEdit: animalToEdit,
      onSaved: onSaved,
    ),
  );
}

/// Confirmation dialog for deleting an animal with persistent backend sync.
Future<bool> showDeleteAnimalDialog(
  BuildContext context,
  AnimalModel animal,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFFFCFAF5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Row(
        children: [
          const Icon(Icons.delete_forever_rounded, color: Color(0xFFC62828), size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'delete_animal'.tr,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Color(0xFF1B2A1E),
              ),
            ),
          ),
        ],
      ),
      content: Text(
        'delete_animal_confirm'.tr,
        style: const TextStyle(
          fontSize: 13.5,
          color: Color(0xFF424242),
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            'cancel'.tr,
            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w700),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC62828),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: Text(
            'delete'.tr,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    try {
      await FarmerApiService().deleteAnimal(animal.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Livestock "${animal.name}" deleted successfully.'),
            backgroundColor: const Color(0xFFC62828),
          ),
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: ${e.toString().replaceAll("Exception:", "").trim()}'),
            backgroundColor: const Color(0xFFC62828),
          ),
        );
      }
      return false;
    }
  }
  return false;
}

class _AnimalFormSheet extends StatefulWidget {
  final AnimalModel? animalToEdit;
  final ValueChanged<AnimalModel>? onSaved;

  const _AnimalFormSheet({
    this.animalToEdit,
    this.onSaved,
  });

  @override
  State<_AnimalFormSheet> createState() => _AnimalFormSheetState();
}

class _AnimalFormSheetState extends State<_AnimalFormSheet> {
  final _apiService = FarmerApiService();
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _tagController;
  late final TextEditingController _breedController;

  late String _selectedSpecies;
  String? _formError;
  bool _isSubmitting = false;

  bool get _isEditing => widget.animalToEdit != null;

  @override
  void initState() {
    super.initState();
    final a = widget.animalToEdit;
    _nameController = TextEditingController(text: a?.name ?? '');
    _ageController = TextEditingController(text: a != null ? a.ageYears.toString() : '2');
    _tagController = TextEditingController(text: a?.tagNumber ?? '');
    _breedController = TextEditingController(text: a?.breed ?? 'HF Cross');
    _selectedSpecies = a?.species ?? 'Cow';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _tagController.dispose();
    _breedController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final tag = _tagController.text.trim();
    final age = double.tryParse(_ageController.text.trim()) ?? 1.0;
    final breed = _breedController.text.trim();

    if (name.isEmpty) {
      setState(() => _formError = 'Please enter an animal name.');
      return;
    }
    if (tag.isEmpty) {
      setState(() => _formError = 'Please enter the Ear Tag number.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _formError = null;
    });

    try {
      AnimalModel result;
      if (_isEditing) {
        result = await _apiService.updateAnimal(
          id: widget.animalToEdit!.id,
          name: name,
          species: _selectedSpecies,
          breed: breed.isNotEmpty ? breed : 'Indigenous',
          ageYears: age,
          tagNumber: tag,
        );
      } else {
        result = await _apiService.addAnimal(
          name: name,
          species: _selectedSpecies,
          breed: breed.isNotEmpty ? breed : 'Indigenous',
          ageYears: age,
          tagNumber: tag,
        );
      }

      if (mounted) {
        widget.onSaved?.call(result);
        Navigator.pop(context, result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Livestock "$name" updated successfully!'
                  : 'Livestock "$name" registered successfully!',
            ),
            backgroundColor: const Color(0xFF1B5E20),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _formError = e.toString().replaceAll('Exception:', '').trim();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInsets = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInsets + 24),
      decoration: const BoxDecoration(
        color: Color(0xFFFCFAF5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Row(
              children: [
                Icon(
                  _isEditing ? Icons.edit_note_rounded : Icons.add_circle_rounded,
                  color: const Color(0xFFE65100),
                  size: 26,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isEditing ? 'edit_livestock_details'.tr : 'add_new_livestock'.tr,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B2A1E),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _isEditing
                  ? 'edit_livestock'.tr
                  : 'add_livestock'.tr,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF616161)),
            ),
            const SizedBox(height: 18),
            if (_formError != null)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEF9A9A)),
                ),
                child: Text(
                  _formError!,
                  style: const TextStyle(
                    color: Color(0xFFC62828),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Text(
              'animal_category'.tr,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF37474F),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: ['Cow', 'Buffalo', 'Goat'].map((species) {
                final isSel = _selectedSpecies == species;
                final label = species == 'Cow'
                    ? 'cat_cow'.tr
                    : species == 'Buffalo'
                        ? 'cat_buffalo'.tr
                        : species == 'Goat'
                            ? 'cat_goat'.tr
                            : species;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedSpecies = species;
                        if (!_isEditing) {
                          if (species == 'Buffalo') {
                            _breedController.text = 'Murrah';
                          } else if (species == 'Goat') {
                            _breedController.text = 'Boer';
                          } else {
                            _breedController.text = 'HF Cross';
                          }
                        }
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFF1B5E20) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSel ? const Color(0xFF1B5E20) : Colors.grey.shade300,
                          width: 1.4,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isSel ? Colors.white : const Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _buildField(
              controller: _nameController,
              label: 'animal_name'.tr,
              hintText: 'enter_name'.tr,
              icon: Icons.pets_rounded,
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _ageController,
              label: '${'age'.tr} (${'years'.tr})',
              hintText: 'enter_age'.tr,
              icon: Icons.cake_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _tagController,
              label: 'ear_tag'.tr,
              hintText: 'enter_tag'.tr,
              icon: Icons.tag_rounded,
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _breedController,
              label: 'breed'.tr,
              hintText: 'enter_breed'.tr,
              icon: Icons.category_outlined,
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE65100),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      _isEditing ? 'save'.tr : 'register_livestock'.tr,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.words,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
        labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF1B5E20)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 1.8),
        ),
      ),
    );
  }
}
