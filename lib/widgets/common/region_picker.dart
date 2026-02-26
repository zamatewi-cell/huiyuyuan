import 'package:flutter/material.dart';
import '../../data/china_regions.dart';
import '../../themes/colors.dart';

/// Three-level cascading region picker (province -> city -> district)
class RegionPicker extends StatefulWidget {
  final String? initialProvince;
  final String? initialCity;
  final String? initialDistrict;
  final ValueChanged<RegionResult> onConfirm;

  const RegionPicker({
    super.key,
    this.initialProvince,
    this.initialCity,
    this.initialDistrict,
    required this.onConfirm,
  });

  /// Show as a bottom sheet
  static Future<RegionResult?> show(
    BuildContext context, {
    String? province,
    String? city,
    String? district,
  }) async {
    return showModalBottomSheet<RegionResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => RegionPicker(
        initialProvince: province,
        initialCity: city,
        initialDistrict: district,
        onConfirm: (result) => Navigator.of(ctx).pop(result),
      ),
    );
  }

  @override
  State<RegionPicker> createState() => _RegionPickerState();
}

class RegionResult {
  final String province;
  final String city;
  final String district;

  const RegionResult({
    required this.province,
    required this.city,
    required this.district,
  });

  String get fullAddress => '$province $city $district';

  @override
  String toString() => fullAddress;
}

class _RegionPickerState extends State<RegionPicker>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Current selections
  String? _selectedProvince;
  String? _selectedCity;
  String? _selectedDistrict;

  // Current tab level: 0=province, 1=city, 2=district
  int _currentLevel = 0;

  // Data lists for current display
  List<String> _provinces = [];
  List<String> _cities = [];
  List<String> _districts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _provinces = ChinaRegions.provinces;

    // Restore initial values
    if (widget.initialProvince != null &&
        _provinces.contains(widget.initialProvince)) {
      _selectedProvince = widget.initialProvince;
      _cities = ChinaRegions.getCities(_selectedProvince!);
      _currentLevel = 1;

      if (widget.initialCity != null && _cities.contains(widget.initialCity)) {
        _selectedCity = widget.initialCity;
        _districts =
            ChinaRegions.getDistricts(_selectedProvince!, _selectedCity!);
        _currentLevel = 2;

        if (widget.initialDistrict != null &&
            _districts.contains(widget.initialDistrict)) {
          _selectedDistrict = widget.initialDistrict;
        }
      }
    }

    _tabController.index = _currentLevel;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onProvinceSelected(String province) {
    setState(() {
      _selectedProvince = province;
      _selectedCity = null;
      _selectedDistrict = null;
      _cities = ChinaRegions.getCities(province);
      _districts = [];
      _currentLevel = 1;
      _tabController.animateTo(1);
    });
  }

  void _onCitySelected(String city) {
    setState(() {
      _selectedCity = city;
      _selectedDistrict = null;
      _districts = ChinaRegions.getDistricts(_selectedProvince!, city);
      if (_districts.isEmpty) {
        // No district data - auto-confirm with city as district
        _selectedDistrict = city;
        _confirm();
      } else {
        _currentLevel = 2;
        _tabController.animateTo(2);
      }
    });
  }

  void _onDistrictSelected(String district) {
    setState(() {
      _selectedDistrict = district;
    });
    _confirm();
  }

  void _confirm() {
    if (_selectedProvince != null && _selectedCity != null) {
      widget.onConfirm(RegionResult(
        province: _selectedProvince!,
        city: _selectedCity!,
        district: _selectedDistrict ?? _selectedCity!,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final hintColor = isDark ? const Color(0xFF8888AA) : const Color(0xFF6B7280);
    final selectedBg =
        isDark ? const Color(0xFF2A2A3A) : JewelryColors.primaryGreen.withAlpha(25);
    final dividerColor = isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE5E7EB);

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  '\u9009\u62E9\u5730\u533A', // Select Region
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(Icons.close, color: hintColor, size: 24),
                ),
              ],
            ),
          ),
          // Tab headers showing current selection breadcrumb
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: dividerColor, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                _buildTabItem(
                  0,
                  _selectedProvince ?? '\u8BF7\u9009\u62E9', // Please select
                  _selectedProvince != null,
                  textColor,
                  hintColor,
                ),
                if (_selectedProvince != null)
                  _buildTabItem(
                    1,
                    _selectedCity ?? '\u8BF7\u9009\u62E9',
                    _selectedCity != null,
                    textColor,
                    hintColor,
                  ),
                if (_selectedCity != null && _districts.isNotEmpty)
                  _buildTabItem(
                    2,
                    _selectedDistrict ?? '\u8BF7\u9009\u62E9',
                    _selectedDistrict != null,
                    textColor,
                    hintColor,
                  ),
              ],
            ),
          ),
          // List content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // Province list
                _buildList(
                  _provinces,
                  _selectedProvince,
                  _onProvinceSelected,
                  textColor,
                  hintColor,
                  selectedBg,
                  dividerColor,
                ),
                // City list
                _buildList(
                  _cities,
                  _selectedCity,
                  _onCitySelected,
                  textColor,
                  hintColor,
                  selectedBg,
                  dividerColor,
                ),
                // District list
                _buildList(
                  _districts,
                  _selectedDistrict,
                  _onDistrictSelected,
                  textColor,
                  hintColor,
                  selectedBg,
                  dividerColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(
    int level,
    String label,
    bool isCompleted,
    Color textColor,
    Color hintColor,
  ) {
    final isActive = _currentLevel == level;
    // Truncate long names
    final displayLabel =
        label.length > 6 ? '${label.substring(0, 5)}\u2026' : label;

    return GestureDetector(
      onTap: () {
        if (level <= _currentLevel) {
          setState(() {
            _currentLevel = level;
            _tabController.animateTo(level);
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive
                  ? JewelryColors.primaryGreen
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          displayLabel,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive
                ? JewelryColors.primaryGreen
                : isCompleted
                    ? textColor
                    : hintColor,
          ),
        ),
      ),
    );
  }

  Widget _buildList(
    List<String> items,
    String? selectedItem,
    ValueChanged<String> onSelect,
    Color textColor,
    Color hintColor,
    Color selectedBg,
    Color dividerColor,
  ) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          '\u8BF7\u5148\u9009\u62E9\u4E0A\u7EA7\u5730\u533A', // Please select parent
          style: TextStyle(color: hintColor, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = item == selectedItem;

        return InkWell(
          onTap: () => onSelect(item),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? selectedBg : null,
              border: Border(
                bottom: BorderSide(color: dividerColor, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 15,
                      color: isSelected
                          ? JewelryColors.primaryGreen
                          : textColor,
                      fontWeight:
                          isSelected ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check,
                    color: JewelryColors.primaryGreen,
                    size: 18,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
