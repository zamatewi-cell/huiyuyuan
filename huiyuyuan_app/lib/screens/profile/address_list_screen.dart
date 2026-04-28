import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huiyuyuan/l10n/string_extension.dart';

import '../../l10n/l10n_provider.dart';
import '../../models/address_model.dart';
import '../../services/address_service.dart';
import '../../themes/colors.dart';
import '../../widgets/common/glassmorphic_card.dart';
import '../../widgets/common/error_handler.dart';
import '../../widgets/common/region_picker.dart';

String _localizedAddressTag(String? tag) {
  if (tag == null || tag.isEmpty) {
    return '';
  }
  return tag.tr;
}

class _AddressBackdrop extends StatelessWidget {
  const _AddressBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: JewelryColors.jadeDepthGradient,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -140,
            right: -120,
            child: _AddressGlowOrb(
              size: 320,
              color: JewelryColors.emeraldGlow.withOpacity(0.1),
            ),
          ),
          Positioned(
            left: -130,
            bottom: 40,
            child: _AddressGlowOrb(
              size: 280,
              color: JewelryColors.champagneGold.withOpacity(0.08),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(painter: _AddressTracePainter()),
          ),
        ],
      ),
    );
  }
}

class _AddressGlowOrb extends StatelessWidget {
  const _AddressGlowOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(color: color, blurRadius: 90, spreadRadius: 24),
        ],
      ),
    );
  }
}

class _AddressTracePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75
      ..color = JewelryColors.champagneGold.withOpacity(0.035);

    for (var i = 0; i < 7; i++) {
      final y = size.height * (0.08 + i * 0.14);
      final path = Path()..moveTo(-28, y);
      path.cubicTo(
        size.width * 0.18,
        y - 28,
        size.width * 0.78,
        y + 34,
        size.width + 28,
        y,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AddressTracePainter oldDelegate) => false;
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
        backgroundColor: JewelryColors.deepJade,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          ref.tr('delete'),
          style: const TextStyle(
            color: JewelryColors.jadeMist,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          ref.tr('address_delete_confirm'),
          style: TextStyle(
            color: JewelryColors.jadeMist.withOpacity(0.66),
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              ref.tr('cancel'),
              style: TextStyle(color: JewelryColors.jadeMist.withOpacity(0.58)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: JewelryColors.error),
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
      SnackBar(
        content: Text(ref.tr('address_deleted')),
        backgroundColor: JewelryColors.emeraldShadow,
        behavior: SnackBarBehavior.floating,
      ),
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
    return Scaffold(
      backgroundColor: JewelryColors.jadeBlack,
      appBar: AppBar(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: JewelryColors.deepJade.withOpacity(0.62),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: JewelryColors.champagneGold.withOpacity(0.14),
            ),
          ),
          child: Text(
            widget.isSelectMode
                ? ref.tr('address_select_title')
                : ref.tr('address_management_title'),
            style: const TextStyle(
              color: JewelryColors.jadeMist,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.35,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: JewelryColors.jadeBlack.withOpacity(0.84),
        foregroundColor: JewelryColors.jadeMist,
        elevation: 0,
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: _AddressBackdrop()),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: JewelryColors.emeraldGlow,
              ),
            )
          else if (_addresses.isEmpty)
            _buildEmptyState()
          else
            _buildAddressList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToEdit(null),
        backgroundColor: JewelryColors.emeraldLuster,
        foregroundColor: JewelryColors.jadeBlack,
        icon: const Icon(Icons.add),
        label: Text(
          ref.tr('address_add'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: GlassmorphicCard(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        borderRadius: 26,
        blur: 16,
        opacity: 0.18,
        borderColor: JewelryColors.champagneGold.withOpacity(0.14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: JewelryColors.emeraldGlow.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: JewelryColors.emeraldGlow.withOpacity(0.18),
                ),
              ),
              child: const Icon(
                Icons.location_off_outlined,
                size: 40,
                color: JewelryColors.emeraldGlow,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              ref.tr('address_empty_title'),
              style: const TextStyle(
                color: JewelryColors.jadeMist,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ref.tr('address_empty_subtitle'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: JewelryColors.jadeMist.withOpacity(0.58),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
      itemCount: _addresses.length,
      itemBuilder: (context, index) {
        final address = _addresses[index];
        return _buildAddressCard(address);
      },
    );
  }

  Widget _buildAddressCard(AddressModel address) {
    return GlassmorphicCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      borderRadius: 24,
      blur: 16,
      opacity: 0.18,
      borderColor: address.isDefault
          ? JewelryColors.emeraldGlow.withOpacity(0.24)
          : JewelryColors.champagneGold.withOpacity(0.12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isSelectMode ? () => _selectAddress(address) : null,
          borderRadius: BorderRadius.circular(24),
          splashColor: JewelryColors.emeraldGlow.withOpacity(0.08),
          highlightColor: JewelryColors.emeraldGlow.withOpacity(0.04),
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
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: JewelryColors.emeraldGlow.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: JewelryColors.emeraldGlow.withOpacity(0.18),
                          ),
                        ),
                        child: Text(
                          ref.tr('address_default'),
                          style: const TextStyle(
                            fontSize: 10,
                            color: JewelryColors.emeraldGlow,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        address.recipientName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: JewelryColors.jadeMist,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      address.maskedPhone,
                      style: TextStyle(
                        fontSize: 14,
                        color: JewelryColors.jadeMist.withOpacity(0.6),
                      ),
                    ),
                    if (address.tag != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: JewelryColors.champagneGold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color:
                                JewelryColors.champagneGold.withOpacity(0.16),
                          ),
                        ),
                        child: Text(
                          _localizedAddressTag(address.tag),
                          style: const TextStyle(
                            fontSize: 12,
                            color: JewelryColors.champagneGold,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  address.fullAddress,
                  style: TextStyle(
                    fontSize: 14,
                    color: JewelryColors.jadeMist.withOpacity(0.68),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                Divider(
                  height: 1,
                  color: JewelryColors.champagneGold.withOpacity(0.12),
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
                                ? JewelryColors.emeraldGlow
                                : JewelryColors.jadeMist.withOpacity(0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ref.tr('address_set_default'),
                            style: TextStyle(
                              fontSize: 13,
                              color: address.isDefault
                                  ? JewelryColors.emeraldGlow
                                  : JewelryColors.jadeMist.withOpacity(0.58),
                              fontWeight: FontWeight.w700,
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
                      style: TextButton.styleFrom(
                        foregroundColor:
                            JewelryColors.jadeMist.withOpacity(0.72),
                      ),
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
    _nameController = TextEditingController(text: address?.recipientName ?? '');
    _phoneController = TextEditingController(text: address?.phoneNumber ?? '');
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
        SnackBar(
          content: Text(ref.tr('address_pick_region')),
          backgroundColor: JewelryColors.error,
          behavior: SnackBarBehavior.floating,
        ),
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
    return Scaffold(
      backgroundColor: JewelryColors.jadeBlack,
      appBar: AppBar(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: JewelryColors.deepJade.withOpacity(0.62),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: JewelryColors.champagneGold.withOpacity(0.14),
            ),
          ),
          child: Text(
            _isEditing
                ? ref.tr('address_edit_title')
                : ref.tr('address_add_title'),
            style: const TextStyle(
              color: JewelryColors.jadeMist,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.35,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: JewelryColors.jadeBlack.withOpacity(0.84),
        foregroundColor: JewelryColors.jadeMist,
        elevation: 0,
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: _AddressBackdrop()),
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
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
                  _buildGlassDivider(),
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
                  _buildGlassDivider(),
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
                  _buildGlassDivider(),
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
                    title: Text(
                      ref.tr('address_set_default'),
                      style: const TextStyle(
                        color: JewelryColors.jadeMist,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    subtitle: Text(
                      ref.tr('address_default_auto_use'),
                      style: TextStyle(
                        color: JewelryColors.jadeMist.withOpacity(0.56),
                      ),
                    ),
                    value: _isDefault,
                    onChanged: (value) => setState(() => _isDefault = value),
                    activeColor: JewelryColors.emeraldGlow,
                    activeTrackColor:
                        JewelryColors.emeraldGlow.withOpacity(0.3),
                  ),
                ]),
                const SizedBox(height: 32),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveAddress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: JewelryColors.emeraldLuster,
                      foregroundColor: JewelryColors.jadeBlack,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: JewelryColors.jadeBlack,
                            ),
                          )
                        : Text(
                            ref.tr('address_save'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
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

  Widget _buildCard(List<Widget> children) {
    return GlassmorphicCard(
      padding: EdgeInsets.zero,
      borderRadius: 24,
      blur: 16,
      opacity: 0.18,
      borderColor: JewelryColors.champagneGold.withOpacity(0.12),
      child: Column(children: children),
    );
  }

  Widget _buildGlassDivider() {
    return Divider(
      height: 1,
      color: JewelryColors.champagneGold.withOpacity(0.1),
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
              child: Text(
                label,
                style: const TextStyle(
                  color: JewelryColors.jadeMist,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              cursorColor: JewelryColors.emeraldGlow,
              style: const TextStyle(color: JewelryColors.jadeMist),
              maxLines: maxLines,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              validator: validator,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: JewelryColors.jadeMist.withOpacity(0.36),
                ),
                errorStyle: const TextStyle(color: JewelryColors.error),
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
                style: const TextStyle(
                  color: JewelryColors.jadeMist,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child: Text(
                _selectedProvince.isNotEmpty
                    ? '$_selectedProvince $_selectedCity $_selectedDistrict'
                    : ref.tr('address_pick_region'),
                style: TextStyle(
                  color: _selectedProvince.isNotEmpty
                      ? JewelryColors.jadeMist
                      : JewelryColors.jadeMist.withOpacity(0.36),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: JewelryColors.champagneGold.withOpacity(0.58),
            ),
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
          Text(
            ref.tr('address_label'),
            style: const TextStyle(
              color: JewelryColors.jadeMist,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: tags.map((tag) {
              final isSelected = _selectedTag == tag.label;
              return ChoiceChip(
                label: Text(
                  '${tag.emoji} ${_localizedAddressTag(tag.label)}',
                  style: TextStyle(
                    color: isSelected
                        ? JewelryColors.jadeBlack
                        : JewelryColors.jadeMist.withOpacity(0.78),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedTag = selected ? tag.label : null;
                  });
                },
                backgroundColor: JewelryColors.jadeBlack.withOpacity(0.22),
                selectedColor: JewelryColors.champagneGold,
                side: BorderSide(
                  color: isSelected
                      ? JewelryColors.champagneGold
                      : JewelryColors.champagneGold.withOpacity(0.16),
                ),
                showCheckmark: false,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
