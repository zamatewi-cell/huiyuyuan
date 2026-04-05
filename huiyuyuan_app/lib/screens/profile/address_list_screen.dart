import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huiyuyuan/l10n/string_extension.dart';

import '../../l10n/l10n_provider.dart';
import '../../models/address_model.dart';
import '../../services/address_service.dart';
import '../../themes/colors.dart';
import '../../widgets/common/error_handler.dart';
import '../../widgets/common/region_picker.dart';

String _localizedAddressTag(String? tag) {
  if (tag == null || tag.isEmpty) {
    return '';
  }
  return tag.tr;
}

class AddressListScreen extends ConsumerStatefulWidget {
  final bool isSelectMode;

  const AddressListScreen({super.key, this.isSelectMode = false});

  @override
  ConsumerState<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends ConsumerState<AddressListScreen> {
  final AddressService _addressService = AddressService();
  List<AddressModel> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    await _addressService.init();
    final addresses = await _addressService.getAllAddresses();
    if (!mounted) {
      return;
    }
    setState(() {
      _addresses = addresses;
      _isLoading = false;
    });
  }

  Future<void> _deleteAddress(String addressId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ref.tr('delete')),
        content: Text(ref.tr('address_delete_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(ref.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(ref.tr('delete')),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    await _addressService.deleteAddress(addressId);
    await _loadAddresses();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ref.tr('address_deleted'))),
    );
  }

  Future<void> _setDefault(String addressId) async {
    await _addressService.setDefaultAddress(addressId);
    await _loadAddresses();
  }

  void _selectAddress(AddressModel address) {
    Navigator.pop(context, address);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? JewelryColors.darkBackground : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          widget.isSelectMode
              ? ref.tr('address_select_title')
              : ref.tr('address_management_title'),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
              ? _buildEmptyState()
              : _buildAddressList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToEdit(null),
        backgroundColor: JewelryColors.primaryGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          ref.tr('address_add'),
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            ref.tr('address_empty_title'),
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            ref.tr('address_empty_subtitle'),
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _addresses.length,
      itemBuilder: (context, index) {
        final address = _addresses[index];
        return _buildAddressCard(address);
      },
    );
  }

  Widget _buildAddressCard(AddressModel address) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSecondary =
        isDark ? const Color(0xFFB0B0C0) : const Color(0xFF6B7280);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: widget.isSelectMode ? () => _selectAddress(address) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (address.isDefault)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: JewelryColors.primaryGreen,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        ref.tr('address_default'),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  Text(
                    address.recipientName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    address.maskedPhone,
                    style: TextStyle(fontSize: 14, color: textSecondary),
                  ),
                  const Spacer(),
                  if (address.tag != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: JewelryColors.primaryGreen.withAlpha(25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _localizedAddressTag(address.tag),
                        style: const TextStyle(
                          fontSize: 12,
                          color: JewelryColors.primaryGreen,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                address.fullAddress,
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Divider(
                height: 1,
                color:
                    isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE5E7EB),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _setDefault(address.id),
                    child: Row(
                      children: [
                        Icon(
                          address.isDefault
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 18,
                          color: address.isDefault
                              ? JewelryColors.primaryGreen
                              : textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ref.tr('address_set_default'),
                          style: TextStyle(
                            fontSize: 13,
                            color: address.isDefault
                                ? JewelryColors.primaryGreen
                                : textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _navigateToEdit(address),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: Text(ref.tr('edit')),
                    style: TextButton.styleFrom(foregroundColor: textSecondary),
                  ),
                  TextButton.icon(
                    onPressed: () => _deleteAddress(address.id),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: Text(ref.tr('delete')),
                    style: TextButton.styleFrom(
                      foregroundColor: JewelryColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToEdit(AddressModel? address) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddressEditScreen(address: address),
      ),
    );
    if (result == true) {
      await _loadAddresses();
    }
  }
}

class AddressEditScreen extends ConsumerStatefulWidget {
  final AddressModel? address;

  const AddressEditScreen({super.key, this.address});

  @override
  ConsumerState<AddressEditScreen> createState() => _AddressEditScreenState();
}

class _AddressEditScreenState extends ConsumerState<AddressEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final AddressService _addressService = AddressService();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _detailController;
  late TextEditingController _postalController;

  String _selectedProvince = '';
  String _selectedCity = '';
  String _selectedDistrict = '';
  String? _selectedTag;
  bool _isDefault = false;
  bool _isSaving = false;

  bool get _isEditing => widget.address != null;

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    _nameController =
        TextEditingController(text: address?.recipientName ?? '');
    _phoneController =
        TextEditingController(text: address?.phoneNumber ?? '');
    _detailController =
        TextEditingController(text: address?.detailAddress ?? '');
    _postalController = TextEditingController(text: address?.postalCode ?? '');

    if (address != null) {
      _selectedProvince = address.province;
      _selectedCity = address.city;
      _selectedDistrict = address.district;
      _selectedTag = address.tag;
      _isDefault = address.isDefault;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _detailController.dispose();
    _postalController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedProvince.isEmpty ||
        _selectedCity.isEmpty ||
        _selectedDistrict.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.tr('address_pick_region'))),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _addressService.init();

      final address = AddressModel(
        id: widget.address?.id ?? '',
        recipientName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        province: _selectedProvince,
        city: _selectedCity,
        district: _selectedDistrict,
        detailAddress: _detailController.text.trim(),
        postalCode:
            _postalController.text.isNotEmpty ? _postalController.text : null,
        isDefault: _isDefault,
        tag: _selectedTag,
        createdAt: widget.address?.createdAt ?? DateTime.now(),
      );

      if (_isEditing) {
        await _addressService.updateAddress(address);
      } else {
        await _addressService.addAddress(address);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        context.showError(error);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? JewelryColors.darkBackground : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          _isEditing
              ? ref.tr('address_edit_title')
              : ref.tr('address_add_title'),
        ),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCard([
              _buildTextField(
                controller: _nameController,
                label: ref.tr('address_recipient_name'),
                hint: ref.tr('address_recipient_name_hint'),
                validator: (value) => value == null || value.isEmpty
                    ? ref.tr('address_recipient_name_hint')
                    : null,
              ),
              const Divider(height: 1),
              _buildTextField(
                controller: _phoneController,
                label: ref.tr('address_phone'),
                hint: ref.tr('address_phone_hint'),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return ref.tr('address_phone_hint');
                  }
                  if (value.length != 11) {
                    return ref.tr('address_phone_invalid');
                  }
                  return null;
                },
              ),
            ]),
            const SizedBox(height: 16),
            _buildCard([
              _buildRegionSelector(),
              const Divider(height: 1),
              _buildTextField(
                controller: _detailController,
                label: ref.tr('address_detail'),
                hint: ref.tr('address_detail_hint'),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return ref.tr('address_detail_required');
                  }
                  if (value.length < 5) {
                    return ref.tr('address_detail_min_length');
                  }
                  return null;
                },
              ),
              const Divider(height: 1),
              _buildTextField(
                controller: _postalController,
                label: ref.tr('address_postal_code'),
                hint: ref.tr('address_optional'),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
              ),
            ]),
            const SizedBox(height: 16),
            _buildCard([
              _buildTagSelector(),
            ]),
            const SizedBox(height: 16),
            _buildCard([
              SwitchListTile(
                title: Text(ref.tr('address_set_default')),
                subtitle: Text(ref.tr('address_default_auto_use')),
                value: _isDefault,
                onChanged: (value) => setState(() => _isDefault = value),
                activeColor: JewelryColors.primaryGreen,
              ),
            ]),
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: JewelryColors.primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        ref.tr('address_save'),
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Padding(
              padding: EdgeInsets.only(top: maxLines > 1 ? 8 : 12),
              child: Text(label, style: const TextStyle(fontSize: 15)),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              maxLines: maxLines,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              validator: validator,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey[400]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionSelector() {
    return InkWell(
      onTap: _showRegionPicker,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(
                ref.tr('address_region'),
                style: const TextStyle(fontSize: 15),
              ),
            ),
            Expanded(
              child: Text(
                _selectedProvince.isNotEmpty
                    ? '$_selectedProvince $_selectedCity $_selectedDistrict'
                    : ref.tr('address_pick_region'),
                style: TextStyle(
                  color: _selectedProvince.isNotEmpty
                      ? Theme.of(context).textTheme.bodyLarge?.color
                      : Colors.grey[400],
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Future<void> _showRegionPicker() async {
    final result = await RegionPicker.show(
      context,
      province: _selectedProvince.isNotEmpty ? _selectedProvince : null,
      city: _selectedCity.isNotEmpty ? _selectedCity : null,
      district: _selectedDistrict.isNotEmpty ? _selectedDistrict : null,
    );
    if (result == null) {
      return;
    }

    setState(() {
      _selectedProvince = result.province;
      _selectedCity = result.city;
      _selectedDistrict = result.district;
    });
  }

  Widget _buildTagSelector() {
    final tags = [
      AddressTag.home,
      AddressTag.company,
      AddressTag.school,
      AddressTag.other,
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ref.tr('address_label'), style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: tags.map((tag) {
              final isSelected = _selectedTag == tag.label;
              return ChoiceChip(
                label: Text('${tag.emoji} ${_localizedAddressTag(tag.label)}'),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedTag = selected ? tag.label : null;
                  });
                },
                selectedColor: JewelryColors.primaryGreen.withAlpha(51),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
