/// 汇玉源 - 收货地址管理页面
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/address_model.dart';
import '../../services/address_service.dart';

/// 收货地址列表页面
class AddressListScreen extends StatefulWidget {
  /// 是否为选择模式（从结算页跳转）
  final bool isSelectMode;

  const AddressListScreen({super.key, this.isSelectMode = false});

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
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
    setState(() {
      _addresses = addresses;
      _isLoading = false;
    });
  }

  Future<void> _deleteAddress(String addressId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个地址吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _addressService.deleteAddress(addressId);
      _loadAddresses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('地址已删除')),
        );
      }
    }
  }

  Future<void> _setDefault(String addressId) async {
    await _addressService.setDefaultAddress(addressId);
    _loadAddresses();
  }

  void _selectAddress(AddressModel address) {
    Navigator.pop(context, address);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(widget.isSelectMode ? '选择收货地址' : '收货地址管理'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
              ? _buildEmptyState()
              : _buildAddressList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToEdit(null),
        backgroundColor: const Color(0xFF2E8B57),
        icon: const Icon(Icons.add),
        label: const Text('新增地址'),
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
            '还没有收货地址',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            '点击下方按钮添加地址',
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
              // 姓名和电话
              Row(
                children: [
                  Text(
                    address.recipientName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    address.maskedPhone,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  if (address.tag != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E8B57).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        address.tag!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2E8B57),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // 完整地址
              Text(
                address.fullAddress,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
              // 操作栏
              Row(
                children: [
                  // 默认地址标记
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
                              ? const Color(0xFF2E8B57)
                              : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '默认地址',
                          style: TextStyle(
                            fontSize: 13,
                            color: address.isDefault
                                ? const Color(0xFF2E8B57)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // 编辑按钮
                  TextButton.icon(
                    onPressed: () => _navigateToEdit(address),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('编辑'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                    ),
                  ),
                  // 删除按钮
                  TextButton.icon(
                    onPressed: () => _deleteAddress(address.id),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('删除'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
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
      _loadAddresses();
    }
  }
}

/// 地址编辑页面
class AddressEditScreen extends StatefulWidget {
  final AddressModel? address;

  const AddressEditScreen({super.key, this.address});

  @override
  State<AddressEditScreen> createState() => _AddressEditScreenState();
}

class _AddressEditScreenState extends State<AddressEditScreen> {
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
    final addr = widget.address;
    _nameController = TextEditingController(text: addr?.recipientName ?? '');
    _phoneController = TextEditingController(text: addr?.phoneNumber ?? '');
    _detailController = TextEditingController(text: addr?.detailAddress ?? '');
    _postalController = TextEditingController(text: addr?.postalCode ?? '');

    if (addr != null) {
      _selectedProvince = addr.province;
      _selectedCity = addr.city;
      _selectedDistrict = addr.district;
      _selectedTag = addr.tag;
      _isDefault = addr.isDefault;
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
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProvince.isEmpty ||
        _selectedCity.isEmpty ||
        _selectedDistrict.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择省市区')),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(_isEditing ? '编辑收货地址' : '新增收货地址'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 收件人信息卡片
            _buildCard([
              _buildTextField(
                controller: _nameController,
                label: '收件人姓名',
                hint: '请输入收件人姓名',
                validator: (v) => v!.isEmpty ? '请输入收件人姓名' : null,
              ),
              const Divider(height: 1),
              _buildTextField(
                controller: _phoneController,
                label: '手机号码',
                hint: '请输入手机号码',
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                validator: (v) {
                  if (v!.isEmpty) return '请输入手机号码';
                  if (v.length != 11) return '请输入正确的手机号码';
                  return null;
                },
              ),
            ]),
            const SizedBox(height: 16),

            // 地址信息卡片
            _buildCard([
              _buildRegionSelector(),
              const Divider(height: 1),
              _buildTextField(
                controller: _detailController,
                label: '详细地址',
                hint: '请输入详细地址（楼栋门牌号等）',
                maxLines: 2,
                validator: (v) {
                  if (v!.isEmpty) return '请输入详细地址';
                  if (v.length < 5) return '详细地址至少5个字符';
                  return null;
                },
              ),
              const Divider(height: 1),
              _buildTextField(
                controller: _postalController,
                label: '邮政编码',
                hint: '选填',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
              ),
            ]),
            const SizedBox(height: 16),

            // 标签选择
            _buildCard([
              _buildTagSelector(),
            ]),
            const SizedBox(height: 16),

            // 默认地址开关
            _buildCard([
              SwitchListTile(
                title: const Text('设为默认地址'),
                subtitle: const Text('下单时自动使用此地址'),
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v),
                activeColor: const Color(0xFF2E8B57),
              ),
            ]),
            const SizedBox(height: 32),

            // 保存按钮
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E8B57),
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
                    : const Text('保存地址', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontSize: 15)),
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
            const SizedBox(
              width: 80,
              child: Text('所在地区', style: TextStyle(fontSize: 15)),
            ),
            Expanded(
              child: Text(
                _selectedProvince.isNotEmpty
                    ? '$_selectedProvince $_selectedCity $_selectedDistrict'
                    : '请选择省市区',
                style: TextStyle(
                  color: _selectedProvince.isNotEmpty
                      ? Colors.black
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

  void _showRegionPicker() {
    // 简化版地区选择（实际项目应使用完整的三级联动选择器）
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '选择地区',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildRegionItem('广东省', '广州市', '天河区'),
                  _buildRegionItem('广东省', '深圳市', '南山区'),
                  _buildRegionItem('广东省', '深圳市', '福田区'),
                  _buildRegionItem('北京市', '北京市', '朝阳区'),
                  _buildRegionItem('上海市', '上海市', '浦东新区'),
                  _buildRegionItem('浙江省', '杭州市', '西湖区'),
                  _buildRegionItem('江苏省', '南京市', '鼓楼区'),
                  _buildRegionItem('四川省', '成都市', '武侯区'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionItem(String province, String city, String district) {
    return ListTile(
      title: Text('$province $city $district'),
      onTap: () {
        setState(() {
          _selectedProvince = province;
          _selectedCity = city;
          _selectedDistrict = district;
        });
        Navigator.pop(context);
      },
    );
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
          const Text('地址标签', style: TextStyle(fontSize: 15)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: tags.map((tag) {
              final isSelected = _selectedTag == tag.label;
              return ChoiceChip(
                label: Text('${tag.emoji} ${tag.label}'),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedTag = selected ? tag.label : null;
                  });
                },
                selectedColor: const Color(0xFF2E8B57).withOpacity(0.2),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
