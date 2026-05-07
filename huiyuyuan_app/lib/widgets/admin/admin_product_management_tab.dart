library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huiyuyuan/providers/app_settings_provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/l10n_provider.dart';
import '../../l10n/product_translator.dart';
import '../../models/product_model.dart';
import '../../models/product_upsert_request.dart';
import '../../providers/product_catalog_provider.dart';
import '../../themes/colors.dart';
import '../common/error_handler.dart';

class AdminProductManagementTab extends ConsumerStatefulWidget {
  const AdminProductManagementTab({super.key});

  @override
  ConsumerState<AdminProductManagementTab> createState() =>
      AdminProductManagementTabState();
}

class AdminProductManagementTabState
    extends ConsumerState<AdminProductManagementTab> {
  String _productSearchQuery = '';

  static const List<String> _productCategories = [
    '手链',
    '吊坠',
    '戒指',
    '手镯',
    '项链',
    '手串',
    '耳饰',
    '摆件',
    '套装',
  ];

  static const List<String> _productMaterials = [
    '和田玉',
    '缅甸翡翠',
    '南红玛瑙',
    '紫水晶',
    '黄金',
    '红宝石',
    '蓝宝石',
    '碧玉',
    '蜜蜡',
    '钻石',
    '珍珠',
  ];

  AppLanguage get _language => ref.watch(appSettingsProvider).language;

  String _productSearchHint() => ref.tr('admin_search_products');

  String _productCountSummary(int visibleCount, int totalCount) {
    return ref.tr(
      'admin_product_count_summary',
      params: {'visible': visibleCount, 'total': totalCount},
    );
  }

  String _productMetaSummary(List<ProductModel> products) {
    final hotCount = products.where((product) => product.isHot).length;
    final newCount = products.where((product) => product.isNew).length;

    return ref.tr(
      'admin_hot_new_summary',
      params: {'hot': hotCount, 'new': newCount},
    );
  }

  String _stockLabel(int stock) =>
      ref.tr('admin_stock_inline', params: {'count': stock});

  String _salesLabel(int salesCount) =>
      ref.tr('admin_sold_inline', params: {'count': salesCount});

  String _categoryLabel(String category) {
    return ProductTranslator.translateCategory(_language, category);
  }

  String _materialLabel(String material) {
    return ProductTranslator.translateMaterial(_language, material);
  }

  void openAddProductDialog() {
    _showAddProductDialog();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appSettingsProvider).language;
    final productCatalogState = ref.watch(productCatalogProvider);
    final products = productCatalogState.products;
    final normalizedQuery = _productSearchQuery.trim().toLowerCase();
    final visibleProducts = normalizedQuery.isEmpty
        ? products
        : products.where((product) {
            final searchableText = <String>[
              product.id,
              product.localizedTitleFor(lang),
              product.localizedDescriptionFor(lang),
              product.localizedCategoryFor(lang),
              product.localizedMaterialFor(lang),
            ].join(' ').toLowerCase();
            return searchableText.contains(normalizedQuery);
          }).toList(growable: false);

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                        onChanged: (value) {
                          setState(() => _productSearchQuery = value);
                        },
                        decoration: InputDecoration(
                          hintText: _productSearchHint(),
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.white.withOpacity(0.4),
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _showAddProductDialog,
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: JewelryColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: JewelryColors.primary.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.add, color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            ref.tr('admin_add_product'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    _productCountSummary(
                      visibleProducts.length,
                      products.length,
                    ),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _productMetaSummary(products),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: productCatalogState.isLoading && products.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: JewelryColors.primary,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16)
                          .copyWith(bottom: 80),
                      itemCount: visibleProducts.length,
                      itemBuilder: (context, index) {
                        return _buildProductItem(visibleProducts[index]);
                      },
                    ),
            ),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: GestureDetector(
            onTap: _showAddProductDialog,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductItem(ProductModel product) {
    final lang = ref.watch(appSettingsProvider).language;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: JewelryColors.getMaterialColor(product.localizedMaterialFor(lang))
                  .withOpacity(0.2),
            ),
            clipBehavior: Clip.antiAlias,
            child: product.images.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: product.images.first,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: JewelryColors.getMaterialColor(
                              product.localizedMaterialFor(lang)),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Center(
                      child: Icon(
                        Icons.diamond,
                        color: JewelryColors.getMaterialColor(
                            product.localizedMaterialFor(lang)),
                        size: 28,
                      ),
                    ),
                  )
                : Center(
                    child: Icon(
                      Icons.diamond,
                      color: JewelryColors.getMaterialColor(
                          product.localizedMaterialFor(lang)),
                      size: 28,
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.localizedTitleFor(lang),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: JewelryColors.getMaterialColor(
                                product.localizedMaterialFor(lang))
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.localizedMaterialFor(lang),
                        style: TextStyle(
                          color: JewelryColors.getMaterialColor(
                              product.localizedMaterialFor(lang)),
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.localizedCategoryFor(lang),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 10,
                        ),
                      ),
                    ),
                    if (product.isHot) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: JewelryColors.error.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'HOT',
                          style: TextStyle(
                            color: JewelryColors.error,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '¥${product.price.toInt()}',
                      style: const TextStyle(
                        color: JewelryColors.price,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _stockLabel(product.stock),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _salesLabel(product.salesCount),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              GestureDetector(
                onTap: () => _showEditProductDialog(product),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: JewelryColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: JewelryColors.primary,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showDeleteConfirm(product),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: JewelryColors.error.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: JewelryColors.error,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showAddProductDialog() async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final originalPriceController = TextEditingController();
    final descController = TextEditingController();
    final stockController = TextEditingController(text: '100');
    final imageUrlController = TextEditingController();
    var selectedCategory = _productCategories.first;
    var selectedMaterial = _productMaterials.first;
    final parentContext = context;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setDialogState) {
          return _buildProductSheetScaffold(
            context: sheetContext,
            icon: const Icon(Icons.add_box, color: JewelryColors.primary),
            title: ref.tr('admin_add_product'),
            body: [
              _buildDialogInput(
                '${ref.tr('admin_product_name_label')} *',
                nameController,
                hint: ref.tr('admin_product_name_hint'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDialogInput(
                      '${ref.tr('admin_sale_price')} *',
                      priceController,
                      hint: '299',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDialogInput(
                      ref.tr('admin_original_price'),
                      originalPriceController,
                      hint: '599',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDialogLabel(ref.tr('product_category')),
              const SizedBox(height: 8),
              _buildOptionChips(
                options: _productCategories,
                selectedValue: selectedCategory,
                onSelected: (value) {
                  setDialogState(() => selectedCategory = value);
                },
                selectedGradient: JewelryColors.primaryGradient,
                selectedTextColor: Colors.white,
                labelBuilder: _categoryLabel,
              ),
              const SizedBox(height: 16),
              _buildDialogLabel(ref.tr('admin_material_type')),
              const SizedBox(height: 8),
              _buildOptionChips(
                options: _productMaterials,
                selectedValue: selectedMaterial,
                onSelected: (value) {
                  setDialogState(() => selectedMaterial = value);
                },
                selectedGradient: JewelryColors.goldGradient,
                selectedTextColor: Colors.black87,
                labelBuilder: _materialLabel,
              ),
              const SizedBox(height: 16),
              _buildDialogInput(
                ref.tr('admin_stock_quantity'),
                stockController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildDialogInput(
                ref.tr('product_description'),
                descController,
                hint: ref.tr('admin_product_description_hint'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _buildDialogLabel(ref.tr('admin_product_images')),
              const SizedBox(height: 8),
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final image = await picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 1920,
                        maxHeight: 1920,
                        imageQuality: 85,
                      );
                      if (image != null) {
                        setDialogState(() {
                          imageUrlController.text = image.path;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: JewelryColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.photo_library,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            ref.tr('admin_pick_from_album'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final image = await picker.pickImage(
                        source: ImageSource.camera,
                        maxWidth: 1920,
                        maxHeight: 1920,
                        imageQuality: 85,
                      );
                      if (image != null) {
                        setDialogState(() {
                          imageUrlController.text = image.path;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.camera_alt,
                            color: Colors.white70,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            ref.tr('admin_take_photo'),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (imageUrlController.text.isNotEmpty)
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: JewelryColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.check_circle,
                        color: JewelryColors.success,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          imageUrlController.text.length > 40
                              ? '...${imageUrlController.text.substring(imageUrlController.text.length - 40)}'
                              : imageUrlController.text,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: Colors.white.withOpacity(0.5),
                          size: 18,
                        ),
                        onPressed: () {
                          setDialogState(imageUrlController.clear);
                        },
                      ),
                    ],
                  ),
                )
              else
                _buildDialogInput(
                  ref.tr('admin_or_enter_image_url'),
                  imageUrlController,
                  hint: ref.tr('admin_image_url_hint'),
                ),
            ],
            footer: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(sheetContext),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        ref.tr('cancel'),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () async {
                    if (nameController.text.trim().isEmpty ||
                        priceController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                          content: Text(ref.tr('admin_fill_name_and_price')),
                          backgroundColor: JewelryColors.error,
                        ),
                      );
                      return;
                    }

                    final imgUrl = imageUrlController.text.trim().isNotEmpty
                        ? imageUrlController.text.trim()
                        : 'https://picsum.photos/400/400';

                    final request = ProductUpsertRequest(
                      name: nameController.text.trim(),
                      description: descController.text.trim().isEmpty
                          ? '优质$selectedMaterial$selectedCategory，品质保证。'
                          : descController.text.trim(),
                      price: double.tryParse(priceController.text) ?? 0,
                      originalPrice:
                          double.tryParse(originalPriceController.text),
                      category: selectedCategory,
                      material: selectedMaterial,
                      images: [imgUrl],
                      stock: int.tryParse(stockController.text) ?? 100,
                      isNew: true,
                      certificate: 'NGTC-${DateTime.now().year}-NEW',
                    );

                    Navigator.pop(sheetContext);

                    final createdProduct = await ref
                        .read(productCatalogProvider.notifier)
                        .createProduct(request);
                    if (createdProduct != null && mounted) {
                      final lang = ref.read(appSettingsProvider).language;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ref.tr(
                              'admin_product_added',
                              params: {'name': createdProduct.localizedTitleFor(lang)},
                            ),
                          ),
                          backgroundColor: JewelryColors.success,
                        ),
                      );
                    } else if (mounted) {
                      context.showError(ref.tr('admin_add_product_failed'));
                    }
                  },
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: JewelryColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        ref.tr('admin_confirm_add'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    nameController.dispose();
    priceController.dispose();
    originalPriceController.dispose();
    descController.dispose();
    stockController.dispose();
    imageUrlController.dispose();
  }

  Future<void> _showEditProductDialog(ProductModel product) async {
    final lang = ref.read(appSettingsProvider).language;
    final nameController = TextEditingController(text: product.localizedTitleFor(lang));
    final priceController =
        TextEditingController(text: product.price.toStringAsFixed(0));
    final originalPriceController = TextEditingController(
      text: product.originalPrice?.toStringAsFixed(0) ?? '',
    );
    final stockController =
        TextEditingController(text: product.stock.toString());
    final descController = TextEditingController(text: product.localizedDescriptionFor(lang));
    var selectedCategory =
        ProductTranslator.canonicalCategory(product.category);
    var selectedMaterial =
        ProductTranslator.canonicalMaterial(product.material);
    if (!_productCategories.contains(selectedCategory)) {
      selectedCategory = _productCategories.first;
    }
    if (!_productMaterials.contains(selectedMaterial)) {
      selectedMaterial = _productMaterials.first;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setDialogState) {
          return _buildProductSheetScaffold(
            context: sheetContext,
            icon: const Icon(Icons.edit, color: JewelryColors.gold),
            title: ref.tr('admin_edit_product'),
            body: [
              _buildDialogInput(
                  ref.tr('admin_product_name_label'), nameController),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDialogInput(
                      ref.tr('admin_sale_price'),
                      priceController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDialogInput(
                      ref.tr('admin_original_price'),
                      originalPriceController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDialogLabel(ref.tr('product_category')),
              const SizedBox(height: 8),
              _buildOptionChips(
                options: _productCategories,
                selectedValue: selectedCategory,
                onSelected: (value) {
                  setDialogState(() => selectedCategory = value);
                },
                selectedGradient: JewelryColors.primaryGradient,
                selectedTextColor: Colors.white,
                labelBuilder: _categoryLabel,
              ),
              const SizedBox(height: 16),
              _buildDialogLabel(ref.tr('product_material')),
              const SizedBox(height: 8),
              _buildOptionChips(
                options: _productMaterials,
                selectedValue: selectedMaterial,
                onSelected: (value) {
                  setDialogState(() => selectedMaterial = value);
                },
                selectedGradient: JewelryColors.goldGradient,
                selectedTextColor: Colors.black87,
                labelBuilder: _materialLabel,
              ),
              const SizedBox(height: 16),
              _buildDialogInput(
                ref.tr('product_stock'),
                stockController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildDialogInput(
                ref.tr('admin_description_label'),
                descController,
                maxLines: 3,
              ),
            ],
            footer: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(sheetContext),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        ref.tr('cancel'),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () async {
                    final request = ProductUpsertRequest(
                      name: nameController.text.trim(),
                      description: descController.text.trim(),
                      price: double.tryParse(priceController.text) ??
                          product.price,
                      originalPrice:
                          double.tryParse(originalPriceController.text),
                      category: selectedCategory,
                      material: selectedMaterial,
                      stock:
                          int.tryParse(stockController.text) ?? product.stock,
                    );

                    Navigator.pop(sheetContext);

                    final updatedProduct = await ref
                        .read(productCatalogProvider.notifier)
                        .updateProduct(product.id, request);
                    if (updatedProduct != null && mounted) {
                      final updatedLang = ref.read(appSettingsProvider).language;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ref.tr(
                              'admin_product_updated',
                              params: {'name': updatedProduct.localizedTitleFor(updatedLang)},
                            ),
                          ),
                          backgroundColor: JewelryColors.success,
                        ),
                      );
                    } else if (mounted) {
                      context.showError(ref.tr('admin_update_product_failed'));
                    }
                  },
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: JewelryColors.goldGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        ref.tr('admin_save_changes'),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    nameController.dispose();
    priceController.dispose();
    originalPriceController.dispose();
    stockController.dispose();
    descController.dispose();
  }

  void _showDeleteConfirm(ProductModel product) {
    final lang = ref.read(appSettingsProvider).language;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        title: Text(ref.tr('admin_delete_product'),
            style: const TextStyle(color: Colors.white)),
        content: Text(
          ref.tr(
            'admin_delete_product_confirm',
            params: {'name': product.localizedTitleFor(lang)},
          ),
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              ref.tr('cancel'),
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await ref
                  .read(productCatalogProvider.notifier)
                  .deleteProduct(product.id);
                      if (success && mounted) {
                final deletedLang = ref.read(appSettingsProvider).language;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ref.tr(
                        'admin_product_deleted',
                        params: {'name': product.localizedTitleFor(deletedLang)},
                      ),
                    ),
                    backgroundColor: JewelryColors.error,
                  ),
                );
              } else if (mounted) {
                context.showError(ref.tr('admin_delete_product_failed'));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: JewelryColors.error,
            ),
            child: Text(ref.tr('delete')),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSheetScaffold({
    required BuildContext context,
    required Widget icon,
    required String title,
    required List<Widget> body,
    required List<Widget> footer,
  }) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            child: Row(
              children: [
                icon,
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.close,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...body,
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
            ),
            child: Row(children: footer),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.white.withOpacity(0.7),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildDialogInput(
    String label,
    TextEditingController controller, {
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDialogLabel(label),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionChips({
    required List<String> options,
    required String selectedValue,
    required ValueChanged<String> onSelected,
    required Gradient selectedGradient,
    required Color selectedTextColor,
    String Function(String value)? labelBuilder,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selectedValue == option;
        return GestureDetector(
          onTap: () => onSelected(option),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: isSelected ? selectedGradient : null,
              color: isSelected ? null : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              labelBuilder?.call(option) ?? option,
              style: TextStyle(
                color: isSelected ? selectedTextColor : Colors.white60,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}
