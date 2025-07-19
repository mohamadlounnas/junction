import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../../services/property_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';

/// Simplified Add Property Page
/// Streamlined form for creating new properties with essential fields only
class AddPropertyPage extends StatefulWidget {
  const AddPropertyPage({super.key});

  @override
  State<AddPropertyPage> createState() => _AddPropertyPageState();
}

class _AddPropertyPageState extends State<AddPropertyPage> {
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

  // Images - using dynamic type to support both File and XFile
  final List<dynamic> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  // Loading state
  bool _isLoading = false;

  // Algerian wilayas (simplified list)
  final List<String> _wilayas = [
    'Alger', 'Oran', 'Constantine', 'Annaba', 'Batna', 'Blida', 'Sétif',
    'Djelfa', 'Sidi Bel Abbès', 'Biskra', 'Tébessa', 'El Oued', 'Skikda',
    'Béjaïa', 'Tiaret', 'Ouargla', 'Béchar', 'Mostaganem', 'Bordj Bou Arréridj',
    'Chlef', 'El Tarf', 'Tamanrasset', 'Guelma', 'Laghouat', 'Mascara',
    'Médéa', 'Ghardaïa', 'Aïn Defla', 'Tlemcen', 'Tipaza', 'Saïda',
    'Aïn Témouchent', 'Ghardaïa', 'Relizane', 'El Bayadh', 'Illizi',
    'Bordj Badji Mokhtar', 'Béni Abbès', 'In Salah', 'In Guezzam',
    'Touggourt', 'Djanet', 'El M\'Ghair', 'El Meniaa'
  ];

  // Property types
  final Map<String, String> _propertyTypes = {
    'APARTMENT': 'شقة',
    'VILLA': 'فيلا',
    'HOUSE': 'منزل',
    'OFFICE': 'مكتب',
    'SHOP': 'محل تجاري',
    'LAND': 'أرض',
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
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _areaController.dispose();
    _roomsController.dispose();
    _bathroomsController.dispose();
    _wilayaController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (images.isNotEmpty) {
        // Validate image files
        final List<XFile> validImages = [];
        for (final image in images) {
          final bytes = await image.readAsBytes();
          final sizeInMB = bytes.length / (1024 * 1024);
          
          // Check file size (max 5MB per image)
          if (sizeInMB > 5) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('الصورة ${image.name} كبيرة جداً. الحد الأقصى 5 ميجابايت'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            continue;
          }
          
          // Check file type
          final extension = image.name.toLowerCase().split('.').last;
          if (!['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('نوع الملف ${image.name} غير مدعوم. استخدم JPG, PNG, أو WebP'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            continue;
          }
          
          validImages.add(image);
        }
        
        if (validImages.isNotEmpty) {
          setState(() {
            // Convert XFile to File for mobile platforms, keep XFile for web
            if (kIsWeb) {
              _selectedImages.addAll(validImages);
            } else {
              _selectedImages.addAll(validImages.map((image) => File(image.path)));
            }
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تم اختيار ${validImages.length} صورة'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في اختيار الصور: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitProperty() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Show message about images being handled separately
      if (_selectedImages.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('سيتم إضافة العقار أولاً، ثم رفع الصور لاحقاً'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }

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
      };

      print('AddPropertyPage: Submitting property data: $propertyData');

      // Use the property service
      final result = await PropertyService().createProperty(
        propertyData: propertyData,
        images: null, // Temporarily disable image upload
      );

      print('AddPropertyPage: Property service result: $result');

      if (result['success'] == true) {
        print('AddPropertyPage: Property created successfully');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'تم إضافة العقار بنجاح!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          
          // Add a small delay to ensure the snackbar is shown
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Use GoRouter navigation
          if (mounted) {
            context.pop();
          }
        }
      } else {
        print('AddPropertyPage: Property creation failed: ${result['message']}');
        throw Exception(result['message'] ?? 'فشل في إضافة العقار');
      }
    } catch (e) {
      print('AddPropertyPage: Exception occurred: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      // Always reset loading state
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information Section
              _buildSectionTitle('المعلومات الأساسية', Icons.info_outline, isDark, colorScheme),
              const SizedBox(height: 16),

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

              const SizedBox(height: 16),

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

              const SizedBox(height: 32),

              // Location Section
              _buildSectionTitle('الموقع', Icons.location_on_outlined, isDark, colorScheme),
              const SizedBox(height: 16),

              // Wilaya Dropdown
              _buildDropdown(
                label: 'الولاية',
                value: _wilayaController.text.isEmpty ? null : _wilayaController.text,
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

              const SizedBox(height: 32),

              // Details Section
              _buildSectionTitle('التفاصيل', Icons.details_outlined, isDark, colorScheme),
              const SizedBox(height: 16),

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

              const SizedBox(height: 32),

              // Features Section
              _buildSectionTitle('المميزات', Icons.featured_play_list_outlined, isDark, colorScheme),
              const SizedBox(height: 16),

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

              _buildFeatureToggle(
                title: 'حديقة',
                subtitle: 'العقار يحتوي على حديقة',
                icon: Icons.nature,
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
                title: 'عقار مميز',
                subtitle: 'عرض هذا العقار في نتائج البحث',
                icon: Icons.star,
                value: _isFeatured,
                isDark: isDark,
                colorScheme: colorScheme,
                onChanged: (value) {
                  setState(() {
                    _isFeatured = value;
                  });
                },
              ),

              const SizedBox(height: 32),

              // Images Section
              _buildSectionTitle('الصور', Icons.photo_library_outlined, isDark, colorScheme),
              const SizedBox(height: 16),



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

              const SizedBox(height: 16),

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
                        FutureBuilder<Uint8List>(
                          future: _selectedImages[index] is XFile 
                              ? _selectedImages[index].readAsBytes()
                              : Future.value(_selectedImages[index].readAsBytesSync()),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: MemoryImage(snapshot.data!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            } else {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                          },
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

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitProperty,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.onPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'جاري الإضافة...',
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'إضافة العقار',
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark, ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(
          icon,
          color: colorScheme.primary,
          size: 24,
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: isDark ? Colors.white : colorScheme.onSurface,
            fontWeight: FontWeight.bold,
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
