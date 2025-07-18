import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/property_service.dart';

/// Add Property Page with Vertical Animated Stepper
/// Integrates with Algeria Real Estate API for property creation
/// Supports both dark and light themes with adaptive UI
class AddPropertyPage extends StatefulWidget {
  const AddPropertyPage({super.key});

  @override
  State<AddPropertyPage> createState() => _AddPropertyPageState();
}

class _AddPropertyPageState extends State<AddPropertyPage>
    with TickerProviderStateMixin {
  // Stepper control
  int _currentStep = 0;
  late AnimationController _stepperController;
  late Animation<double> _stepperAnimation;
  late AnimationController _pageController;
  late Animation<double> _pageAnimation;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _areaController = TextEditingController();
  final _roomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _wilayaController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _buildingAgeController = TextEditingController();
  final _floorController = TextEditingController();
  final _totalFloorsController = TextEditingController();

  // Form data
  String _selectedPropertyType = 'APARTMENT';
  String _selectedTransactionType = 'SALE';
  String _selectedFurnishing = 'UNFURNISHED';
  String _selectedCondition = 'GOOD';

  // Boolean features
  bool _hasParking = false;
  bool _hasSecurity = false;
  bool _hasElevator = false;
  bool _hasGarden = false;
  bool _hasBalcony = false;
  bool _hasSwimmingPool = false;
  bool _isFeatured = false;

  // Location data
  double? _latitude;
  double? _longitude;

  // Images
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  // Loading state
  bool _isLoading = false;

  // Algerian wilayas
  final List<String> _wilayas = [
    'Adrar',
    'Chlef',
    'Laghouat',
    'Oum El Bouaghi',
    'Batna',
    'Béjaïa',
    'Biskra',
    'Béchar',
    'Blida',
    'Bouira',
    'Tamanrasset',
    'Tébessa',
    'Tlemcen',
    'Tiaret',
    'Tizi Ouzou',
    'Alger',
    'Djelfa',
    'Jijel',
    'Sétif',
    'Saïda',
    'Skikda',
    'Sidi Bel Abbès',
    'Annaba',
    'Guelma',
    'Constantine',
    'Médéa',
    'Mostaganem',
    'M\'Sila',
    'Mascara',
    'Ouargla',
    'Oran',
    'El Bayadh',
    'Illizi',
    'Bordj Bou Arréridj',
    'Boumerdès',
    'El Tarf',
    'Tindouf',
    'Tissemsilt',
    'El Oued',
    'Khenchela',
    'Souk Ahras',
    'Tipaza',
    'Mila',
    'Aïn Defla',
    'Naâma',
    'Aïn Témouchent',
    'Ghardaïa',
    'Relizane',
    'Timimoun',
    'Bordj Badji Mokhtar',
    'Ouled Djellal',
    'Béni Abbès',
    'In Salah',
    'In Guezzam',
    'Touggourt',
    'Djanet',
    'El M\'Ghair',
    'El Meniaa',
  ];

  // Property types
  final Map<String, String> _propertyTypes = {
    'APARTMENT': 'شقة',
    'VILLA': 'فيلا',
    'HOUSE': 'منزل',
    'OFFICE': 'مكتب',
    'SHOP': 'محل تجاري',
    'WAREHOUSE': 'مستودع',
    'LAND': 'أرض',
    'GARAGE': 'كراج',
  };

  // Transaction types
  final Map<String, String> _transactionTypes = {
    'RENT': 'إيجار',
    'SALE': 'بيع',
  };

  // Furnishing options
  final Map<String, String> _furnishingOptions = {
    'FURNISHED': 'مفروش',
    'SEMI_FURNISHED': 'نصف مفروش',
    'UNFURNISHED': 'غير مفروش',
  };

  // Condition options
  final Map<String, String> _conditionOptions = {
    'POOR': 'رديء',
    'FAIR': 'مقبول',
    'GOOD': 'جيد',
    'EXCELLENT': 'ممتاز',
    'NEW': 'جديد',
  };

  @override
  void initState() {
    super.initState();
    _stepperController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _stepperAnimation = CurvedAnimation(
      parent: _stepperController,
      curve: Curves.easeInOut,
    );

    _pageController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pageAnimation = CurvedAnimation(
      parent: _pageController,
      curve: Curves.easeInOut,
    );

    _stepperController.forward();
  }

  @override
  void dispose() {
    _stepperController.dispose();
    _pageController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _areaController.dispose();
    _roomsController.dispose();
    _bathroomsController.dispose();
    _wilayaController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _buildingAgeController.dispose();
    _floorController.dispose();
    _totalFloorsController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() {
        _currentStep++;
      });
      _pageController.forward().then((_) {
        _pageController.reset();
        _pageController.forward();
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.forward().then((_) {
        _pageController.reset();
        _pageController.forward();
      });
    }
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((image) => File(image.path)));
      });
    }
  }

  Future<void> _submitProperty() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare the property data
      final propertyData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'price': double.parse(_priceController.text),
        'area': double.parse(_areaController.text),
        'rooms': int.parse(_roomsController.text),
        'bathrooms': int.parse(_bathroomsController.text),
        'wilaya': _wilayaController.text,
        'city': _cityController.text,
        'address': _addressController.text,
        'propertyType': _selectedPropertyType,
        'transactionType': _selectedTransactionType,
        'furnishing': _selectedFurnishing,
        'condition': _selectedCondition,
        'hasParking': _hasParking,
        'hasSecurity': _hasSecurity,
        'hasElevator': _hasElevator,
        'hasGarden': _hasGarden,
        'hasBalcony': _hasBalcony,
        'hasSwimmingPool': _hasSwimmingPool,
        'featured': _isFeatured,
        if (_buildingAgeController.text.isNotEmpty)
          'buildingAge': int.parse(_buildingAgeController.text),
        if (_floorController.text.isNotEmpty)
          'floor': int.parse(_floorController.text),
        if (_totalFloorsController.text.isNotEmpty)
          'totalFloors': int.parse(_totalFloorsController.text),
        if (_latitude != null) 'latitude': _latitude,
        if (_longitude != null) 'longitude': _longitude,
      };

      // Use the property service
      final result = await PropertyService().createProperty(
        propertyData: propertyData,
        images: _selectedImages.isNotEmpty ? _selectedImages : null,
      );

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'تم إضافة العقار بنجاح!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        throw Exception(result['message'] ?? 'فشل في إضافة العقار');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'إضافة عقار جديد',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: isDark ? Colors.white : colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Row(
        children: [
          // Vertical Stepper Sidebar
          Container(
            width: 280,
            padding: const EdgeInsets.all(20),
            child: FadeTransition(
              opacity: _stepperAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-0.5, 0),
                  end: Offset.zero,
                ).animate(_stepperAnimation),
                child: _buildVerticalStepper(isDark, colorScheme),
              ),
            ),
          ),

          // Vertical Divider
          Container(
            width: 1,
            margin: const EdgeInsets.symmetric(vertical: 20),
            color: colorScheme.outline.withOpacity(0.3),
          ),

          // Content Area
          Expanded(
            child: FadeTransition(
              opacity: _pageAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.3, 0),
                  end: Offset.zero,
                ).animate(_pageAnimation),
                child: _buildCurrentStep(isDark, colorScheme),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalStepper(bool isDark, ColorScheme colorScheme) {
    final steps = [
      {
        'title': 'معلومات أساسية',
        'subtitle': 'العنوان والوصف والسعر',
        'icon': Icons.info_outline,
      },
      {
        'title': 'الموقع',
        'subtitle': 'الولاية والمدينة والعنوان',
        'icon': Icons.location_on_outlined,
      },
      {
        'title': 'التفاصيل',
        'subtitle': 'الحالة والتأثيث والعمر',
        'icon': Icons.details_outlined,
      },
      {
        'title': 'المميزات',
        'subtitle': 'المرافق والخدمات',
        'icon': Icons.featured_play_list_outlined,
      },
      {
        'title': 'الصور',
        'subtitle': 'إضافة صور العقار',
        'icon': Icons.photo_library_outlined,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'خطوات إضافة العقار',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: isDark ? Colors.white : colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),

        Expanded(
          child: ListView.builder(
            itemCount: steps.length,
            itemBuilder: (context, index) {
              final step = steps[index];
              final isActive = index == _currentStep;
              final isCompleted = index < _currentStep;
              final isUpcoming = index > _currentStep;

              return _buildVerticalStepItem(
                index: index,
                step: step,
                isActive: isActive,
                isCompleted: isCompleted,
                isUpcoming: isUpcoming,
                isDark: isDark,
                colorScheme: colorScheme,
              );
            },
          ),
        ),

        // Navigation Buttons
        const SizedBox(height: 20),
        _buildNavigationButtons(isDark, colorScheme),
      ],
    );
  }

  Widget _buildVerticalStepItem({
    required int index,
    required Map<String, dynamic> step,
    required bool isActive,
    required bool isCompleted,
    required bool isUpcoming,
    required bool isDark,
    required ColorScheme colorScheme,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Circle and Line
          Column(
            children: [
              // Step Circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? colorScheme.primary
                      : isActive
                      ? colorScheme.primary.withOpacity(0.8)
                      : colorScheme.outline.withOpacity(0.3),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  isCompleted ? Icons.check : step['icon'] as IconData,
                  color: isCompleted || isActive
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface.withOpacity(0.5),
                  size: 24,
                ),
              ),

              // Vertical Line
              if (index < 4)
                Container(
                  width: 2,
                  height: 40,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? colorScheme.primary
                        : colorScheme.outline.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 16),

          // Step Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isActive
                    ? colorScheme.primary.withOpacity(0.1)
                    : isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.02),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? colorScheme.primary.withOpacity(0.3)
                      : colorScheme.outline.withOpacity(0.2),
                  width: isActive ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step['title'] as String,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isActive || isCompleted
                          ? colorScheme.primary
                          : isDark
                          ? Colors.white
                          : colorScheme.onSurface,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step['subtitle'] as String,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
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

  Widget _buildCurrentStep(bool isDark, ColorScheme colorScheme) {
    switch (_currentStep) {
      case 0:
        return _buildBasicInfoStep(isDark, colorScheme);
      case 1:
        return _buildLocationStep(isDark, colorScheme);
      case 2:
        return _buildDetailsStep(isDark, colorScheme);
      case 3:
        return _buildFeaturesStep(isDark, colorScheme);
      case 4:
        return _buildImagesStep(isDark, colorScheme);
      default:
        return Container();
    }
  }

  Widget _buildBasicInfoStep(bool isDark, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'المعلومات الأساسية',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: isDark ? Colors.white : colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            _buildTextField(
              controller: _titleController,
              label: 'عنوان العقار',
              hint: 'أدخل عنوان العقار',
              isDark: isDark,
              colorScheme: colorScheme,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'يرجى إدخال عنوان';
                }
                if (value.length < 5) {
                  return 'يجب أن يكون العنوان 5 أحرف على الأقل';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Description
            _buildTextField(
              controller: _descriptionController,
              label: 'الوصف',
              hint: 'صف عقارك...',
              maxLines: 3,
              isDark: isDark,
              colorScheme: colorScheme,
            ),

            const SizedBox(height: 16),

            // Price and Area Row
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _priceController,
                    label: 'السعر (دينار جزائري)',
                    hint: '0',
                    keyboardType: TextInputType.number,
                    isDark: isDark,
                    colorScheme: colorScheme,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال السعر';
                      }
                      if (double.tryParse(value) == null) {
                        return 'يرجى إدخال رقم صحيح';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _areaController,
                    label: 'المساحة (م²)',
                    hint: '0',
                    keyboardType: TextInputType.number,
                    isDark: isDark,
                    colorScheme: colorScheme,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال المساحة';
                      }
                      if (double.tryParse(value) == null) {
                        return 'يرجى إدخال رقم صحيح';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Rooms and Bathrooms Row
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _roomsController,
                    label: 'الغرف',
                    hint: '0',
                    keyboardType: TextInputType.number,
                    isDark: isDark,
                    colorScheme: colorScheme,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال عدد الغرف';
                      }
                      if (int.tryParse(value) == null) {
                        return 'يرجى إدخال رقم صحيح';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _bathroomsController,
                    label: 'الحمامات',
                    hint: '0',
                    keyboardType: TextInputType.number,
                    isDark: isDark,
                    colorScheme: colorScheme,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال عدد الحمامات';
                      }
                      if (int.tryParse(value) == null) {
                        return 'يرجى إدخال رقم صحيح';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Property Type and Transaction Type
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'نوع العقار',
                    value: _selectedPropertyType,
                    items: _propertyTypes,
                    isDark: isDark,
                    colorScheme: colorScheme,
                    onChanged: (value) {
                      setState(() {
                        _selectedPropertyType = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    label: 'نوع المعاملة',
                    value: _selectedTransactionType,
                    items: _transactionTypes,
                    isDark: isDark,
                    colorScheme: colorScheme,
                    onChanged: (value) {
                      setState(() {
                        _selectedTransactionType = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationStep(bool isDark, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تفاصيل الموقع',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: isDark ? Colors.white : colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Wilaya Dropdown
          _buildDropdown(
            label: 'الولاية',
            value: _wilayaController.text.isEmpty
                ? null
                : _wilayaController.text,
            items: Map.fromEntries(_wilayas.map((w) => MapEntry(w, w))),
            isDark: isDark,
            colorScheme: colorScheme,
            onChanged: (value) {
              setState(() {
                _wilayaController.text = value!;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى اختيار الولاية';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // City
          _buildTextField(
            controller: _cityController,
            label: 'المدينة',
            hint: 'أدخل اسم المدينة',
            isDark: isDark,
            colorScheme: colorScheme,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال اسم المدينة';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Address
          _buildTextField(
            controller: _addressController,
            label: 'العنوان',
            hint: 'أدخل العنوان الكامل',
            maxLines: 2,
            isDark: isDark,
            colorScheme: colorScheme,
          ),

          const SizedBox(height: 20),

          // Coordinates (Optional)
          Text(
            'الإحداثيات (اختياري)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: isDark ? Colors.white : colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: TextEditingController(
                    text: _latitude?.toString() ?? '',
                  ),
                  label: 'خط العرض',
                  hint: '36.7538',
                  keyboardType: TextInputType.number,
                  isDark: isDark,
                  colorScheme: colorScheme,
                  onChanged: (value) {
                    _latitude = double.tryParse(value);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: TextEditingController(
                    text: _longitude?.toString() ?? '',
                  ),
                  label: 'خط الطول',
                  hint: '3.0588',
                  keyboardType: TextInputType.number,
                  isDark: isDark,
                  colorScheme: colorScheme,
                  onChanged: (value) {
                    _longitude = double.tryParse(value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsStep(bool isDark, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تفاصيل العقار',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: isDark ? Colors.white : colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Condition and Furnishing
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'الحالة',
                  value: _selectedCondition,
                  items: _conditionOptions,
                  isDark: isDark,
                  colorScheme: colorScheme,
                  onChanged: (value) {
                    setState(() {
                      _selectedCondition = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown(
                  label: 'التأثيث',
                  value: _selectedFurnishing,
                  items: _furnishingOptions,
                  isDark: isDark,
                  colorScheme: colorScheme,
                  onChanged: (value) {
                    setState(() {
                      _selectedFurnishing = value!;
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Building Age and Floor
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _buildingAgeController,
                  label: 'عمر المبنى (سنوات)',
                  hint: '0',
                  keyboardType: TextInputType.number,
                  isDark: isDark,
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _floorController,
                  label: 'الطابق',
                  hint: '0',
                  keyboardType: TextInputType.number,
                  isDark: isDark,
                  colorScheme: colorScheme,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Total Floors
          _buildTextField(
            controller: _totalFloorsController,
            label: 'إجمالي الطوابق',
            hint: '1',
            keyboardType: TextInputType.number,
            isDark: isDark,
            colorScheme: colorScheme,
          ),

          const SizedBox(height: 20),

          // Featured Property
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.2)
                    : Colors.black.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.star,
                  color: _isFeatured
                      ? Colors.amber
                      : colorScheme.onSurface.withOpacity(0.5),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'عقار مميز',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: isDark
                                  ? Colors.white
                                  : colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        'عرض هذا العقار في نتائج البحث',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isFeatured,
                  onChanged: (value) {
                    setState(() {
                      _isFeatured = value;
                    });
                  },
                  activeColor: colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesStep(bool isDark, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مميزات العقار',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: isDark ? Colors.white : colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Feature toggles
          _buildFeatureToggle(
            title: 'موقف سيارات',
            subtitle: 'العقار يحتوي على موقف سيارات',
            icon: Icons.local_parking,
            value: _hasParking,
            isDark: isDark,
            colorScheme: colorScheme,
            onChanged: (value) {
              setState(() {
                _hasParking = value;
              });
            },
          ),

          _buildFeatureToggle(
            title: 'حراسة',
            subtitle: 'خدمة حراسة 24/7',
            icon: Icons.security,
            value: _hasSecurity,
            isDark: isDark,
            colorScheme: colorScheme,
            onChanged: (value) {
              setState(() {
                _hasSecurity = value;
              });
            },
          ),

          _buildFeatureToggle(
            title: 'مصعد',
            subtitle: 'المبنى يحتوي على مصعد',
            icon: Icons.elevator,
            value: _hasElevator,
            isDark: isDark,
            colorScheme: colorScheme,
            onChanged: (value) {
              setState(() {
                _hasElevator = value;
              });
            },
          ),

          _buildFeatureToggle(
            title: 'حديقة',
            subtitle: 'العقار يحتوي على حديقة',
            icon: Icons.yard,
            value: _hasGarden,
            isDark: isDark,
            colorScheme: colorScheme,
            onChanged: (value) {
              setState(() {
                _hasGarden = value;
              });
            },
          ),

          _buildFeatureToggle(
            title: 'شرفة',
            subtitle: 'العقار يحتوي على شرفة',
            icon: Icons.balcony,
            value: _hasBalcony,
            isDark: isDark,
            colorScheme: colorScheme,
            onChanged: (value) {
              setState(() {
                _hasBalcony = value;
              });
            },
          ),

          _buildFeatureToggle(
            title: 'مسبح',
            subtitle: 'العقار يحتوي على مسبح',
            icon: Icons.pool,
            value: _hasSwimmingPool,
            isDark: isDark,
            colorScheme: colorScheme,
            onChanged: (value) {
              setState(() {
                _hasSwimmingPool = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImagesStep(bool isDark, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'صور العقار',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: isDark ? Colors.white : colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Image picker button
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.2)
                    : Colors.black.withOpacity(0.1),
                style: BorderStyle.solid,
              ),
            ),
            child: InkWell(
              onTap: _pickImages,
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 48,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'إضافة صور',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isDark ? Colors.white : colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'اضغط لاختيار صور متعددة',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Selected images grid
          if (_selectedImages.isNotEmpty) ...[
            Text(
              'الصور المختارة (${_selectedImages.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isDark ? Colors.white : colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(_selectedImages[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImages.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(bool isDark, ColorScheme colorScheme) {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : _previousStep,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'السابق',
                style: TextStyle(
                  color: isDark ? Colors.white : colorScheme.onSurface,
                ),
              ),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : (_currentStep == 4 ? _submitProperty : _nextStep),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.onPrimary,
                      ),
                    ),
                  )
                : Text(
                    _currentStep == 4 ? 'إضافة العقار' : 'التالي',
                    style: TextStyle(color: colorScheme.onPrimary),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    required ColorScheme colorScheme,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: isDark ? Colors.white : colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          onChanged: onChanged,
          style: TextStyle(
            color: isDark ? Colors.white : colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required Map<String, String> items,
    required bool isDark,
    required ColorScheme colorScheme,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: isDark ? Colors.white : colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          validator: validator,
          style: TextStyle(
            color: isDark ? Colors.white : colorScheme.onSurface,
          ),
          dropdownColor: isDark ? Colors.grey[900] : Colors.white,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          items: items.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(
                entry.value,
                style: TextStyle(
                  color: isDark ? Colors.white : colorScheme.onSurface,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFeatureToggle({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required bool isDark,
    required ColorScheme colorScheme,
    required void Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.2)
              : Colors.black.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value
                  ? colorScheme.primary.withOpacity(0.2)
                  : colorScheme.outline.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: value
                  ? colorScheme.primary
                  : colorScheme.onSurface.withOpacity(0.5),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isDark ? Colors.white : colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
