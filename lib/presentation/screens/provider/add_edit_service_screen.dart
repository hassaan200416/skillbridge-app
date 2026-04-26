
// ---------------------------------------------------------------------------
// add_edit_service_screen.dart
//
// Purpose: Create or edit a provider service. Two-column web layout:
// left = form fields, right = image gallery + live preview.
// All fields map to real DB columns. No premium tier UI.
//
// ---------------------------------------------------------------------------

import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/route_names.dart';
import '../../../data/models/service_model.dart';
import '../../../data/models/user_model.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/service_provider.dart';
import '../../../presentation/widgets/common/app_sidebar.dart';
import '../../../presentation/widgets/common/app_top_bar.dart';

class AddEditServiceScreen extends ConsumerStatefulWidget {
  const AddEditServiceScreen({super.key, this.serviceId});
  final String? serviceId;

  @override
  ConsumerState<AddEditServiceScreen> createState() =>
      _AddEditServiceScreenState();
}

class _AddEditServiceScreenState extends ConsumerState<AddEditServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  ServiceCategory _category = ServiceCategory.other;
  PriceType _priceType = PriceType.fixed;
  List<String> _availableDays = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
  ];
  final List<XFile> _newImages = [];
  List<String> _existingImageUrls = [];
  bool _isLoading = false;
  bool _isLoaded = false;

  static const _allDays = [
    ('monday', 'Mon'),
    ('tuesday', 'Tue'),
    ('wednesday', 'Wed'),
    ('thursday', 'Thu'),
    ('friday', 'Fri'),
    ('saturday', 'Sat'),
    ('sunday', 'Sun'),
  ];

  bool get _isEditing => widget.serviceId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExisting();
      });
    } else {
      _isLoaded = true;
    }
  }

  Future<void> _loadExisting() async {
    try {
      final s = await ref.read(serviceDetailProvider(widget.serviceId!).future);
      if (!mounted) return;
      _titleCtrl.text = s.title;
      _descCtrl.text = s.description;
      _priceCtrl.text = s.price.toStringAsFixed(0);
      setState(() {
        _category = s.category;
        _priceType = s.priceType;
        _availableDays = List.from(s.availableDays);
        _existingImageUrls = List.from(s.imageUrls);
        _isLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoaded = true);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final totalImages = _existingImageUrls.length + _newImages.length;
    if (totalImages >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 5 photos allowed'),
        ),
      );
      return;
    }
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          setState(() {
            _newImages.add(XFile.fromData(
              file.bytes!,
              name: file.name,
              mimeType: 'image/${file.extension ?? 'png'}',
            ));
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image pick failed: $e')),
        );
      }
    }
  }

  void _removeNewImage(int i) {
    setState(() => _newImages.removeAt(i));
  }

  void _removeExistingImage(int i) {
    setState(() => _existingImageUrls.removeAt(i));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() => _isLoading = true);

    bool success;
    if (_isEditing) {
      success = await ref.read(serviceActionProvider.notifier).updateService(
            serviceId: widget.serviceId!,
            providerId: currentUser.id,
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            category: _category,
            priceType: _priceType,
            price: double.parse(_priceCtrl.text.trim()),
            availableDays: _availableDays,
            imageUrls: _existingImageUrls,
            isActive: true,
          );
    } else {
      success = await ref.read(serviceActionProvider.notifier).createService(
            providerId: currentUser.id,
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            category: _category,
            priceType: _priceType,
            price: double.parse(_priceCtrl.text.trim()),
            availableDays: _availableDays,
            imageFiles: _newImages,
            isDraft: false,
          );
    }

    if (mounted) setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Service updated' : 'Service published'),
          backgroundColor: AppColors.primary,
        ),
      );
      context.go(RouteNames.myServices);
    } else if (!success && mounted) {
      final errorState = ref.read(serviceActionProvider);
      final errorMsg = errorState.error?.message ??
          'Failed to publish service. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= 1100;
    final showSidebar = screenWidth >= 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          if (showSidebar)
            const AppSidebar(
              role: UserRole.provider,
              currentRoute: RouteNames.addService,
            ),
          Expanded(
            child: Column(
              children: [
                const AppTopBar(),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final w = constraints.maxWidth.isFinite
                              ? constraints.maxWidth
                              : MediaQuery.sizeOf(context).width;
                          return ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Breadcrumb(isEditing: _isEditing),
                                const SizedBox(height: 12),
                                Text(
                                  _isEditing
                                      ? 'Edit Service'
                                      : 'Create a Service',
                                  style: GoogleFonts.poppins(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.secondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Define your craft. High-quality descriptions and photos help you get more bookings.',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppColors.grey500,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                if (isWide)
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 55,
                                        child: _FormCard(
                                          titleCtrl: _titleCtrl,
                                          descCtrl: _descCtrl,
                                          priceCtrl: _priceCtrl,
                                          category: _category,
                                          onCategoryChange: (v) =>
                                              setState(() => _category = v),
                                          priceType: _priceType,
                                          onPriceTypeChange: (v) =>
                                              setState(() => _priceType = v),
                                          availableDays: _availableDays,
                                          onDaysChange: (days) => setState(
                                              () => _availableDays = days),
                                          allDays: _allDays,
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        flex: 45,
                                        child: Column(
                                          children: [
                                            _GalleryCard(
                                              existingUrls: _existingImageUrls,
                                              newImages: _newImages,
                                              onAdd: _pickImage,
                                              onRemoveExisting:
                                                  _removeExistingImage,
                                              onRemoveNew: _removeNewImage,
                                            ),
                                            const SizedBox(height: 16),
                                            _LivePreview(
                                              category: _category,
                                              days: _availableDays,
                                              providerName: user.name,
                                              providerAvatar: user.avatarUrl,
                                              existingImageUrls:
                                                  _existingImageUrls,
                                              newImages: _newImages,
                                              titleListener: _titleCtrl,
                                              priceListener: _priceCtrl,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Column(
                                    children: [
                                      _FormCard(
                                        titleCtrl: _titleCtrl,
                                        descCtrl: _descCtrl,
                                        priceCtrl: _priceCtrl,
                                        category: _category,
                                        onCategoryChange: (v) =>
                                            setState(() => _category = v),
                                        priceType: _priceType,
                                        onPriceTypeChange: (v) =>
                                            setState(() => _priceType = v),
                                        availableDays: _availableDays,
                                        onDaysChange: (days) => setState(
                                            () => _availableDays = days),
                                        allDays: _allDays,
                                      ),
                                      const SizedBox(height: 20),
                                      _GalleryCard(
                                        existingUrls: _existingImageUrls,
                                        newImages: _newImages,
                                        onAdd: _pickImage,
                                        onRemoveExisting: _removeExistingImage,
                                        onRemoveNew: _removeNewImage,
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 24),
                                const Divider(color: AppColors.divider),
                                const SizedBox(height: 16),
                                Wrap(
                                  alignment: WrapAlignment.end,
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    TextButton(
                                      onPressed: () =>
                                          context.go(RouteNames.myServices),
                                      child: Text(
                                        'Discard Changes',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.grey500,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: _isLoading ? null : _save,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 28,
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(
                                              _isEditing
                                                  ? 'Save Changes'
                                                  : 'Publish Service',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 40),
                              ],
                            ),
                          );
                        },
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

// ── Breadcrumb ────────────────────────────────────────────────────────────────

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.isEditing});
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.go(RouteNames.myServices),
          child: Text('Services',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.grey500,
                  fontWeight: FontWeight.w500)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.chevron_right, size: 14, color: AppColors.grey400),
        ),
        Flexible(
          child: Text(isEditing ? 'Edit Service' : 'Add New Service',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

// ── Form Card ─────────────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.titleCtrl,
    required this.descCtrl,
    required this.priceCtrl,
    required this.category,
    required this.onCategoryChange,
    required this.priceType,
    required this.onPriceTypeChange,
    required this.availableDays,
    required this.onDaysChange,
    required this.allDays,
  });

  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final TextEditingController priceCtrl;
  final ServiceCategory category;
  final void Function(ServiceCategory) onCategoryChange;
  final PriceType priceType;
  final void Function(PriceType) onPriceTypeChange;
  final List<String> availableDays;
  final void Function(List<String>) onDaysChange;
  final List<(String, String)> allDays;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Basic Information',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              )),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 30,
            color: AppColors.primary,
          ),
          const SizedBox(height: 22),
          _Label('Service Title'),
          TextFormField(
            controller: titleCtrl,
            decoration: _inputDecoration('e.g. Premium Home Deep Cleaning'),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              if (v.trim().length < 5) {
                return 'Title must be at least 5 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          LayoutBuilder(builder: (context, c) {
            final wide = c.maxWidth > 500;
            final categoryField = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Label('Category'),
                DropdownButtonFormField<ServiceCategory>(
                  isExpanded: true,
                  initialValue: category,
                  decoration: _inputDecoration(''),
                  items: ServiceCategory.values
                      .map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(_categoryLabel(cat.name),
                                style: GoogleFonts.inter(fontSize: 14)),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) onCategoryChange(v);
                  },
                ),
              ],
            );
            final priceTypeField = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Label('Pricing Model'),
                Row(
                  children: [
                    Expanded(
                      child: _PricingPill(
                        label: 'Fixed Price',
                        selected: priceType == PriceType.fixed,
                        onTap: () => onPriceTypeChange(PriceType.fixed),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PricingPill(
                        label: 'Starting From',
                        selected: priceType == PriceType.startingFrom,
                        onTap: () => onPriceTypeChange(PriceType.startingFrom),
                      ),
                    ),
                  ],
                ),
              ],
            );
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: categoryField),
                  const SizedBox(width: 14),
                  Expanded(child: priceTypeField),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                categoryField,
                const SizedBox(height: 18),
                priceTypeField,
              ],
            );
          }),
          const SizedBox(height: 18),
          _Label('Service Description'),
          TextFormField(
            controller: descCtrl,
            maxLines: 5,
            maxLength: 500,
            decoration: _inputDecoration(
                "Detail your process, what's included, and what makes your service stand out..."),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              if (v.trim().length < 20) {
                return 'Description must be at least 20 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          _Label('Price (PKR)'),
          TextFormField(
            controller: priceCtrl,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('0').copyWith(
              prefixText: 'PKR  ',
              prefixStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              ),
            ),
            validator: (v) {
              final n = double.tryParse(v ?? '');
              if (n == null || n <= 0) {
                return 'Enter a valid price';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          _Label('Available Days'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allDays.map((day) {
              final selected = availableDays.contains(day.$1);
              return GestureDetector(
                onTap: () {
                  final copy = List<String>.from(availableDays);
                  if (selected) {
                    copy.remove(day.$1);
                  } else {
                    copy.add(day.$1);
                  }
                  onDaysChange(copy);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.grey50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Text(day.$2,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : AppColors.secondary,
                      )),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.grey400),
      filled: true,
      fillColor: AppColors.grey50,
      counterText: '',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.secondary,
          )),
    );
  }
}

class _PricingPill extends StatelessWidget {
  const _PricingPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.grey50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Center(
          child: Text(label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.secondary,
              )),
        ),
      ),
    );
  }
}

// ── Gallery Card ──────────────────────────────────────────────────────────────

class _GalleryCard extends StatelessWidget {
  const _GalleryCard({
    required this.existingUrls,
    required this.newImages,
    required this.onAdd,
    required this.onRemoveExisting,
    required this.onRemoveNew,
  });

  final List<String> existingUrls;
  final List<XFile> newImages;
  final VoidCallback onAdd;
  final void Function(int) onRemoveExisting;
  final void Function(int) onRemoveNew;

  @override
  Widget build(BuildContext context) {
    final total = existingUrls.length + newImages.length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Service Gallery',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                    )),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$total / 5 SLOTS',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 0.8,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: total == 0 ? onAdd : null,
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.border,
                  style: total == 0 ? BorderStyle.solid : BorderStyle.none,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _mainPhoto(context),
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: 4,
            itemBuilder: (_, i) {
              final slotIndex = i + 1;
              final totalImgs = existingUrls.length + newImages.length;
              final hasImage = slotIndex < totalImgs;
              if (hasImage) {
                return _buildFilledSlot(slotIndex);
              }
              if (slotIndex == totalImgs) {
                return _EmptySlot(onTap: onAdd);
              }
              return const _DisabledSlot();
            },
          ),
          const SizedBox(height: 10),
          Text(
            'Upload up to 5 images. Preferred ratio 4:3.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.grey500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mainPhoto(BuildContext context) {
    if (existingUrls.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(imageUrl: existingUrls.first, fit: BoxFit.cover),
          Positioned(
            top: 8,
            right: 8,
            child: _RemoveBtn(onTap: () => onRemoveExisting(0)),
          ),
        ],
      );
    }
    if (newImages.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          FutureBuilder<Uint8List>(
            future: newImages.first.readAsBytes(),
            builder: (_, snap) {
              if (snap.data == null) {
                return Container(color: AppColors.grey100);
              }
              return Image.memory(snap.data!, fit: BoxFit.cover);
            },
          ),
          Positioned(
            top: 8,
            right: 8,
            child: _RemoveBtn(onTap: () => onRemoveNew(0)),
          ),
        ],
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_a_photo_outlined,
                color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text('Upload Main Photo',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              )),
        ],
      ),
    );
  }

  Widget _buildFilledSlot(int slotIndex) {
    final existingCount = existingUrls.length;
    if (slotIndex < existingCount) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
                imageUrl: existingUrls[slotIndex], fit: BoxFit.cover),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: _RemoveBtn(
                onTap: () => onRemoveExisting(slotIndex), small: true),
          ),
        ],
      );
    }
    final newIndex = slotIndex - existingCount;
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: FutureBuilder<Uint8List>(
            future: newImages[newIndex].readAsBytes(),
            builder: (_, snap) {
              if (snap.data == null) {
                return Container(color: AppColors.grey100);
              }
              return Image.memory(snap.data!, fit: BoxFit.cover);
            },
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: _RemoveBtn(onTap: () => onRemoveNew(newIndex), small: true),
        ),
      ],
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
        ),
        child: const Center(
          child: Icon(Icons.add, color: AppColors.grey400, size: 24),
        ),
      ),
    );
  }
}

class _DisabledSlot extends StatelessWidget {
  const _DisabledSlot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class _RemoveBtn extends StatelessWidget {
  const _RemoveBtn({required this.onTap, this.small = false});
  final VoidCallback onTap;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: small ? 22 : 26,
        height: small ? 22 : 26,
        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.close, color: Colors.white, size: small ? 14 : 16),
      ),
    );
  }
}

// ── Live Preview ──────────────────────────────────────────────────────────────

class _LivePreview extends StatefulWidget {
  const _LivePreview({
    required this.category,
    required this.days,
    required this.providerName,
    required this.providerAvatar,
    required this.existingImageUrls,
    required this.newImages,
    required this.titleListener,
    required this.priceListener,
  });

  final ServiceCategory category;
  final List<String> days;
  final String providerName;
  final String? providerAvatar;
  final List<String> existingImageUrls;
  final List<XFile> newImages;
  final TextEditingController titleListener;
  final TextEditingController priceListener;

  @override
  State<_LivePreview> createState() => _LivePreviewState();
}

class _LivePreviewState extends State<_LivePreview> {
  @override
  void initState() {
    super.initState();
    widget.titleListener.addListener(_rebuild);
    widget.priceListener.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.titleListener.removeListener(_rebuild);
    widget.priceListener.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final title = widget.titleListener.text.isEmpty
        ? 'Service Title Preview'
        : widget.titleListener.text;
    final price =
        widget.priceListener.text.isEmpty ? '0' : widget.priceListener.text;
    final availability = _availabilityLabel(widget.days);
    final firstImageWidget = _firstImage();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.visibility, color: AppColors.primary, size: 16),
              const SizedBox(width: 6),
              Text('LIVE PREVIEW',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 1,
                  )),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.grey100,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (firstImageWidget != null)
                          firstImageWidget
                        else
                          Container(color: AppColors.secondary),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.6),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          left: 14,
                          right: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _categoryLabel(widget.category.name)
                                    .toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                title,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(14),
                    color: AppColors.white,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Starting from',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: AppColors.grey500,
                                    fontWeight: FontWeight.w600,
                                  )),
                              const SizedBox(height: 2),
                              Text('PKR $price',
                                  style: GoogleFonts.poppins(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.secondary,
                                  )),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('AVAILABILITY',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  color: AppColors.grey500,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                )),
                            const SizedBox(height: 2),
                            Text(availability,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                )),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    color: AppColors.white,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.15),
                          backgroundImage: widget.providerAvatar != null
                              ? CachedNetworkImageProvider(
                                  widget.providerAvatar!)
                              : null,
                          child: widget.providerAvatar == null
                              ? Text(
                                  widget.providerName.isNotEmpty
                                      ? widget.providerName[0].toUpperCase()
                                      : 'P',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                              widget.providerName.isEmpty
                                  ? 'Provider'
                                  : widget.providerName,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.grey600,
                              ),
                              overflow: TextOverflow.ellipsis),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('Book Now',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              )),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _firstImage() {
    if (widget.existingImageUrls.isNotEmpty) {
      return CachedNetworkImage(
          imageUrl: widget.existingImageUrls.first, fit: BoxFit.cover);
    }
    if (widget.newImages.isNotEmpty) {
      return FutureBuilder<Uint8List>(
        future: widget.newImages.first.readAsBytes(),
        builder: (_, snap) {
          if (snap.data == null) {
            return Container(color: AppColors.grey100);
          }
          return Image.memory(snap.data!, fit: BoxFit.cover);
        },
      );
    }
    return null;
  }

  String _availabilityLabel(List<String> days) {
    if (days.isEmpty) return 'None';
    const abbrev = {
      'monday': 'Mon',
      'tuesday': 'Tue',
      'wednesday': 'Wed',
      'thursday': 'Thu',
      'friday': 'Fri',
      'saturday': 'Sat',
      'sunday': 'Sun',
    };
    final sorted = [...days]
      ..sort((a, b) => _dayOrder(a).compareTo(_dayOrder(b)));
    if (sorted.length <= 2) {
      return sorted.map((d) => abbrev[d] ?? d).join(', ');
    }
    final first = _dayOrder(sorted.first);
    final last = _dayOrder(sorted.last);
    if (last - first == sorted.length - 1) {
      return '${abbrev[sorted.first]} - ${abbrev[sorted.last]}';
    }
    return sorted.take(3).map((d) => abbrev[d] ?? d).join(', ');
  }

  int _dayOrder(String d) {
    const order = {
      'monday': 0,
      'tuesday': 1,
      'wednesday': 2,
      'thursday': 3,
      'friday': 4,
      'saturday': 5,
      'sunday': 6,
    };
    return order[d] ?? 0;
  }
}

String _categoryLabel(String name) {
  return name
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
