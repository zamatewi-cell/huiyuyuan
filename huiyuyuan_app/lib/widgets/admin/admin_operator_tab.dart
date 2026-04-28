library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n_provider.dart';
import '../../l10n/string_extension.dart';
import '../../services/admin_service.dart';
import '../../themes/colors.dart';

class AdminOperatorTab extends ConsumerStatefulWidget {
  const AdminOperatorTab({super.key});

  @override
  ConsumerState<AdminOperatorTab> createState() => _AdminOperatorTabState();
}

class _AdminOperatorTabState extends ConsumerState<AdminOperatorTab> {
  final AdminService _adminService = AdminService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  int _selectedIndex = 0;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  bool _draftActive = true;
  List<String> _draftPermissions = <String>[];
  String? _lastAppliedTemplateKey;
  List<_SavedRoleTemplate> _savedTemplates = const <_SavedRoleTemplate>[];
  List<OperatorAccount> _operators = _fallbackOperatorAccounts;

  OperatorAccount get _selectedOperator => _operators[_selectedIndex];

  @override
  void initState() {
    super.initState();
    _syncDraft(_selectedOperator);
    _loadSavedTemplates();
    _loadOperators();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadOperators() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final accounts = await _adminService.getOperatorAccounts();
    if (!mounted) {
      return;
    }

    setState(() {
      if (accounts.isNotEmpty) {
        _operators = accounts;
        if (_selectedIndex >= _operators.length) {
          _selectedIndex = 0;
        }
        _syncDraft(_selectedOperator);
      }
      _isLoading = false;
    });
  }

  void _syncDraft(OperatorAccount operator) {
    _nameController.text = _operatorName(operator);
    _phoneController.text = operator.phone ?? '';
    _passwordController.clear();
    _draftActive = operator.isActive;
    _draftPermissions = _normalizePermissions(operator.permissions);
    _lastAppliedTemplateKey = _detectActiveTemplateKey(_draftPermissions);
  }

  List<String> _normalizePermissions(Iterable<String> permissions) {
    final selected = permissions.toSet();
    return [
      for (final spec in _permissionSpecs)
        if (selected.contains(spec.key)) spec.key,
    ];
  }

  bool _matchesPermissions(
    Iterable<String> left,
    Iterable<String> right,
  ) {
    final leftSet = left.toSet();
    final rightSet = right.toSet();
    return leftSet.length == rightSet.length && leftSet.containsAll(rightSet);
  }

  String? _detectActiveTemplateKey(Iterable<String> permissions) {
    for (final template in _savedTemplates) {
      if (_matchesPermissions(permissions, template.permissions)) {
        return template.templateKey;
      }
    }
    for (final template in _roleTemplateSpecs) {
      if (_matchesPermissions(permissions, template.permissions)) {
        return template.templateKey;
      }
    }
    return null;
  }

  _RoleTemplateSpec? get _activeRoleTemplate {
    for (final template in _roleTemplateSpecs) {
      if (_lastAppliedTemplateKey == template.templateKey &&
          _matchesPermissions(_draftPermissions, template.permissions)) {
        return template;
      }
    }
    final draft = _draftPermissions.toSet();
    for (final template in _roleTemplateSpecs) {
      final templatePermissions = template.permissions.toSet();
      if (draft.length == templatePermissions.length &&
          draft.containsAll(templatePermissions)) {
        return template;
      }
    }
    return null;
  }

  _SavedRoleTemplate? get _activeSavedTemplate {
    for (final template in _savedTemplates) {
      if (_lastAppliedTemplateKey == template.templateKey &&
          _matchesPermissions(_draftPermissions, template.permissions)) {
        return template;
      }
    }
    for (final template in _savedTemplates) {
      if (_matchesPermissions(_draftPermissions, template.permissions)) {
        return template;
      }
    }
    return null;
  }

  String _activeTemplateLabel() {
    final saved = _activeSavedTemplate;
    if (saved != null) {
      return saved.name;
    }
    final builtIn = _activeRoleTemplate;
    if (builtIn != null) {
      return ref.tr(builtIn.labelKey);
    }
    return ref.tr('admin_operator_template_custom');
  }

  Future<void> _loadSavedTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_savedRoleTemplatesPrefsKey);
    if (raw == null || raw.trim().isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return;
      }
      final templates = decoded
          .whereType<Map<dynamic, dynamic>>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(_SavedRoleTemplate.fromJson)
          .where((template) => template.name.trim().isNotEmpty)
          .map(
            (template) => template.copyWith(
              permissions: _normalizePermissions(template.permissions),
            ),
          )
          .where((template) => template.permissions.isNotEmpty)
          .toList(growable: false);
      if (!mounted) {
        return;
      }
      setState(() {
        _savedTemplates = templates;
        _lastAppliedTemplateKey ??= _detectActiveTemplateKey(_draftPermissions);
      });
    } catch (_) {}
  }

  Future<void> _persistSavedTemplates(
    List<_SavedRoleTemplate> templates,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _savedRoleTemplatesPrefsKey,
      jsonEncode([
        for (final template in templates) template.toJson(),
      ]),
    );
  }

  void _applyRoleTemplate(_RoleTemplateSpec template) {
    setState(() {
      _draftPermissions = _normalizePermissions(template.permissions);
      _lastAppliedTemplateKey = template.templateKey;
    });
  }

  void _applySavedRoleTemplate(_SavedRoleTemplate template) {
    setState(() {
      _draftPermissions = _normalizePermissions(template.permissions);
      _lastAppliedTemplateKey = template.templateKey;
    });
  }

  Future<void> _saveCurrentAsTemplate() async {
    final name = await _promptTemplateName(
      titleKey: 'admin_operator_template_save_title',
    );
    if (!mounted || name == null) {
      return;
    }

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      _showSnackBar(
        ref.tr('admin_operator_template_name_required'),
        backgroundColor: JewelryColors.error,
      );
      return;
    }

    final existing = _savedTemplates.where((item) => item.name == trimmedName);
    final existingTemplate = existing.isEmpty ? null : existing.first;
    final savedTemplate = _SavedRoleTemplate(
      id: existingTemplate?.id ??
          'tpl_${DateTime.now().microsecondsSinceEpoch.toString()}',
      name: trimmedName,
      permissions: _draftPermissions,
    );
    final updatedTemplates = [
      savedTemplate,
      for (final template in _savedTemplates)
        if (template.name != trimmedName) template,
    ];

    await _persistSavedTemplates(updatedTemplates);
    if (!mounted) {
      return;
    }

    setState(() {
      _savedTemplates = updatedTemplates;
      _lastAppliedTemplateKey = savedTemplate.templateKey;
    });
    _showSnackBar(ref.tr('admin_operator_template_save_success'));
  }

  Future<void> _renameSavedTemplate(_SavedRoleTemplate template) async {
    final name = await _promptTemplateName(
      titleKey: 'admin_operator_template_rename_title',
      initialName: template.name,
    );
    if (!mounted || name == null) {
      return;
    }

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      _showSnackBar(
        ref.tr('admin_operator_template_name_required'),
        backgroundColor: JewelryColors.error,
      );
      return;
    }

    final renamed = template.copyWith(name: trimmedName);
    final updatedTemplates = [
      renamed,
      for (final item in _savedTemplates)
        if (item.id != template.id && item.name != trimmedName) item,
    ];

    await _persistSavedTemplates(updatedTemplates);
    if (!mounted) {
      return;
    }

    setState(() {
      _savedTemplates = updatedTemplates;
      if (_lastAppliedTemplateKey == template.templateKey) {
        _lastAppliedTemplateKey = renamed.templateKey;
      }
    });
    _showSnackBar(ref.tr('admin_operator_template_rename_success'));
  }

  Future<void> _deleteSavedTemplate(_SavedRoleTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(ref.tr('admin_operator_template_delete_title')),
        content: Text(
          ref.tr(
            'admin_operator_template_delete_confirm',
            params: {'name': template.name},
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(ref.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: JewelryColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(ref.tr('delete')),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) {
      return;
    }

    final updatedTemplates = [
      for (final item in _savedTemplates)
        if (item.id != template.id) item,
    ];
    await _persistSavedTemplates(updatedTemplates);
    if (!mounted) {
      return;
    }

    setState(() {
      _savedTemplates = updatedTemplates;
      if (_lastAppliedTemplateKey == template.templateKey) {
        _lastAppliedTemplateKey = _detectActiveTemplateKey(_draftPermissions);
      }
    });
    _showSnackBar(ref.tr('admin_operator_template_delete_success'));
  }

  Future<String?> _promptTemplateName({
    required String titleKey,
    String? initialName,
  }) async {
    final controller = TextEditingController(text: initialName ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(ref.tr(titleKey)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: ref.tr('admin_operator_template_name_label'),
            hintText: ref.tr('admin_operator_template_name_hint'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(ref.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(ref.tr('confirm')),
          ),
        ],
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });
    return result;
  }

  Future<void> _saveSelectedOperator() async {
    final selected = _selectedOperator;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final request = OperatorAccountUpdateRequest(
      username: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      isActive: _draftActive,
      password: _passwordController.text.trim(),
      permissions: _draftPermissions,
    );
    final updated = await _adminService.updateOperatorAccount(
      selected.id,
      request,
    );

    if (!mounted) {
      return;
    }

    if (updated == null) {
      setState(() {
        _isSaving = false;
        _errorMessage = ref.tr('admin_operator_save_failed');
      });
      return;
    }

    setState(() {
      _operators = [
        for (final item in _operators) item.id == updated.id ? updated : item,
      ];
      _selectedIndex = _operators.indexWhere((item) => item.id == updated.id);
      if (_selectedIndex < 0) {
        _selectedIndex = 0;
      }
      _syncDraft(_selectedOperator);
      _isSaving = false;
    });

    _showSnackBar(ref.tr('admin_operator_saved'));
  }

  void _showSnackBar(
    String message, {
    Color backgroundColor = JewelryColors.success,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedOperator = _selectedOperator;
    final snapshot = _snapshotFor(selectedOperator);
    final report = selectedOperator.report ?? snapshot.report;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoading) const LinearProgressIndicator(minHeight: 2),
          if (_errorMessage != null) ...[
            _ErrorBanner(message: _errorMessage!),
            const SizedBox(height: 12),
          ],
          _buildPerformancePanel(selectedOperator, snapshot, report),
          const SizedBox(height: 16),
          _buildAccountPanel(selectedOperator),
        ],
      ),
    );
  }

  Widget _buildPerformancePanel(
    OperatorAccount selectedOperator,
    _OperatorSnapshot snapshot,
    OperatorReport report,
  ) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: JewelryColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.people_alt_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ref.tr('admin_operator_performance_title'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ref.tr('admin_operator_performance_subtitle'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List<Widget>.generate(_operators.length, (index) {
              final operator = _operators[index];
              final isSelected = index == _selectedIndex;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIndex = index;
                    _syncDraft(operator);
                    _errorMessage = null;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 84,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected ? JewelryColors.primaryGradient : null,
                    color: isSelected ? null : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: isSelected
                        ? null
                        : Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _operatorCode(operator),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _operatorName(operator),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _operatorName(selectedOperator),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ref.tr(snapshot.focusKey),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.72),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              _StageChip(
                label: ref.tr(
                  selectedOperator.isActive
                      ? snapshot.stageKey
                      : 'admin_operator_status_disabled',
                ),
                active: selectedOperator.isActive,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricCard(
                label: ref.tr('admin_operator_metric_contacted'),
                value: '${report.contactShops}',
                color: JewelryColors.primary,
                icon: Icons.store_mall_directory_outlined,
              ),
              _MetricCard(
                label: ref.tr('admin_operator_metric_intentions'),
                value: '${report.intentionCount}',
                color: JewelryColors.gold,
                icon: Icons.trending_up_rounded,
              ),
              _MetricCard(
                label: ref.tr('admin_operator_metric_wins'),
                value: '${report.successCount}',
                color: JewelryColors.success,
                icon: Icons.handshake_outlined,
              ),
              _MetricCard(
                label: ref.tr('admin_operator_metric_ai_sessions'),
                value: '${report.aiUsageCount}',
                color: const Color(0xFF667EEA),
                icon: Icons.auto_awesome_rounded,
              ),
              _MetricCard(
                label: ref.tr('admin_operator_metric_order_amount'),
                value: _formatCurrency(report.orderAmount),
                color: JewelryColors.primary,
                icon: Icons.payments_outlined,
              ),
              _MetricCard(
                label: ref.tr('admin_operator_metric_response_sla'),
                value: ref.tr(snapshot.responseSlaKey),
                color: const Color(0xFF14B8A6),
                icon: Icons.schedule_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountPanel(OperatorAccount selectedOperator) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.admin_panel_settings_outlined,
                  color: JewelryColors.gold),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ref.tr('admin_operator_account_title'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ref.tr('admin_operator_account_subtitle'),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.62),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusSwitch(
                value: _draftActive,
                onChanged: (value) => setState(() => _draftActive = value),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _OperatorTextField(
            label: ref.tr('admin_operator_name_label'),
            controller: _nameController,
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 12),
          _OperatorTextField(
            label: ref.tr('admin_operator_phone_label'),
            controller: _phoneController,
            icon: Icons.phone_android_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          _OperatorTextField(
            label: ref.tr('admin_operator_password_label'),
            hint: ref.tr('admin_operator_password_hint'),
            controller: _passwordController,
            icon: Icons.lock_reset_outlined,
            obscureText: true,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  ref.tr('admin_operator_permissions_title'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _saveCurrentAsTemplate,
                icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                label: Text(ref.tr('admin_operator_template_save')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.16)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            ref.tr('admin_operator_templates_subtitle'),
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final template in _roleTemplateSpecs)
                _RoleTemplateCard(
                  label: ref.tr(template.labelKey),
                  description: ref.tr(template.descriptionKey),
                  selected:
                      _activeRoleTemplate?.templateKey == template.templateKey,
                  onTap: () => _applyRoleTemplate(template),
                ),
            ],
          ),
          if (_savedTemplates.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              ref.tr('admin_operator_templates_custom_title'),
              style: TextStyle(
                color: Colors.white.withOpacity(0.72),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final template in _savedTemplates)
                  _RoleTemplateCard(
                    label: template.name,
                    description:
                        template.permissions.map(_permissionLabel).join(' / '),
                    selected: _activeSavedTemplate?.id == template.id,
                    onTap: () => _applySavedRoleTemplate(template),
                    onRename: () => _renameSavedTemplate(template),
                    onDelete: () => _deleteSavedTemplate(template),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Text(
            ref.tr(
              'admin_operator_template_applied',
              params: {
                'name': _activeTemplateLabel(),
              },
            ),
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final spec in _permissionSpecs)
                _PermissionChip(
                  label: ref.tr(spec.labelKey),
                  selected: _draftPermissions.contains(spec.key),
                  onTap: () {
                    setState(() {
                      if (_draftPermissions.contains(spec.key)) {
                        _draftPermissions.remove(spec.key);
                      } else {
                        _draftPermissions.add(spec.key);
                      }
                      _lastAppliedTemplateKey = null;
                      _draftPermissions =
                          _normalizePermissions(_draftPermissions);
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveSelectedOperator,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined, size: 18),
              label: Text(
                ref.tr('admin_operator_save_account'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: JewelryColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ref.tr(
              'admin_operator_selected_hint',
              params: {'code': _operatorCode(selectedOperator)},
            ),
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _operatorCode(OperatorAccount operator) {
    final number = operator.operatorNumber;
    if (number == null) {
      return operator.id.toUpperCase();
    }
    return 'OP-${number.toString().padLeft(2, '0')}';
  }

  String _permissionLabel(String key) {
    for (final spec in _permissionSpecs) {
      if (spec.key == key) {
        return ref.tr(spec.labelKey);
      }
    }
    return key;
  }

  String _operatorName(OperatorAccount operator) {
    if (operator.username.startsWith('admin_operator_default_name_')) {
      return ref.read(tProvider)(operator.username);
    }
    return operator.username;
  }

  String _formatCurrency(double amount) {
    final whole = amount.round().toString();
    final buffer = StringBuffer();
    for (var index = 0; index < whole.length; index++) {
      final reverseIndex = whole.length - index;
      buffer.write(whole[index]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write(',');
      }
    }
    return '¥$buffer';
  }

  _OperatorSnapshot _snapshotFor(OperatorAccount operator) {
    final number = operator.operatorNumber;
    return _operatorSnapshots.firstWhere(
      (item) => item.operatorNumber == number,
      orElse: () => _operatorSnapshots.first,
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: child,
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OperatorTextField extends StatelessWidget {
  const _OperatorTextField({
    required this.label,
    required this.controller,
    required this.icon,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
  });

  final String label;
  final String? hint;
  final TextEditingController controller;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.white54),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: JewelryColors.primary),
        ),
      ),
    );
  }
}

class _PermissionChip extends StatelessWidget {
  const _PermissionChip({
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? JewelryColors.primary.withOpacity(0.22)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? JewelryColors.primary
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? JewelryColors.primary : Colors.white38,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleTemplateCard extends StatelessWidget {
  const _RoleTemplateCard({
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
    this.onRename,
    this.onDelete,
  });

  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final hasActions = onRename != null || onDelete != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 168,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? JewelryColors.primary.withOpacity(0.18)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? JewelryColors.primary
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  selected ? Icons.task_alt_rounded : Icons.layers_outlined,
                  color: selected ? JewelryColors.primary : Colors.white60,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
                if (hasActions)
                  PopupMenuButton<_SavedTemplateAction>(
                    tooltip: 'admin_operator_template_more_actions'.tr,
                    icon: Icon(
                      Icons.more_horiz_rounded,
                      color: Colors.white.withOpacity(0.72),
                      size: 18,
                    ),
                    color: const Color(0xFF132235),
                    onSelected: (action) {
                      switch (action) {
                        case _SavedTemplateAction.rename:
                          onRename?.call();
                          break;
                        case _SavedTemplateAction.delete:
                          onDelete?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: _SavedTemplateAction.rename,
                        child: Row(
                          children: [
                            const Icon(Icons.edit_outlined, size: 18),
                            const SizedBox(width: 8),
                            Text('admin_operator_template_rename'.tr),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: _SavedTemplateAction.delete,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: JewelryColors.error,
                            ),
                            const SizedBox(width: 8),
                            Text('admin_operator_template_delete'.tr),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusSwitch extends StatelessWidget {
  const _StatusSwitch({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      activeColor: JewelryColors.primary,
      onChanged: onChanged,
    );
  }
}

class _StageChip extends StatelessWidget {
  const _StageChip({
    required this.label,
    required this.active,
  });

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? JewelryColors.gold : Colors.white54;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: JewelryColors.error.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: JewelryColors.error.withOpacity(0.35)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: JewelryColors.error, fontSize: 12),
      ),
    );
  }
}

class _PermissionSpec {
  const _PermissionSpec(this.key, this.labelKey);

  final String key;
  final String labelKey;
}

class _RoleTemplateSpec {
  const _RoleTemplateSpec(
    this.id,
    this.labelKey,
    this.descriptionKey,
    this.permissions,
  );

  final String id;
  final String labelKey;
  final String descriptionKey;
  final List<String> permissions;

  String get templateKey => 'builtin:$id';
}

class _SavedRoleTemplate {
  const _SavedRoleTemplate({
    required this.id,
    required this.name,
    required this.permissions,
  });

  final String id;
  final String name;
  final List<String> permissions;

  String get templateKey => 'saved:$id';

  factory _SavedRoleTemplate.fromJson(Map<String, dynamic> json) {
    return _SavedRoleTemplate(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      permissions: [
        if (json['permissions'] is List)
          for (final item in json['permissions'] as List<dynamic>)
            item.toString(),
      ],
    );
  }

  _SavedRoleTemplate copyWith({
    String? id,
    String? name,
    List<String>? permissions,
  }) {
    return _SavedRoleTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      permissions: permissions ?? this.permissions,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'permissions': permissions,
      };
}

enum _SavedTemplateAction {
  rename,
  delete,
}

class _OperatorSnapshot {
  const _OperatorSnapshot({
    required this.operatorNumber,
    required this.focusKey,
    required this.stageKey,
    required this.responseSlaKey,
    required this.report,
  });

  final int operatorNumber;
  final String focusKey;
  final String stageKey;
  final String responseSlaKey;
  final OperatorReport report;
}

const List<String> _defaultPermissionKeys = <String>[
  'shop_radar',
  'ai_assistant',
  'orders',
  'inventory_read',
];

const String _savedRoleTemplatesPrefsKey =
    'admin.operator.saved_role_templates.v1';

const List<String> _orderSpecialistPermissionKeys = <String>[
  'orders',
  'payment_reconcile',
  'payment_exception_mark',
  'order_manage',
];

const List<String> _supervisorPermissionKeys = <String>[
  'shop_radar',
  'ai_assistant',
  'orders',
  'payment_reconcile',
  'payment_exception_mark',
  'order_manage',
  'inventory_read',
  'inventory_write',
];

const List<_PermissionSpec> _permissionSpecs = <_PermissionSpec>[
  _PermissionSpec('shop_radar', 'admin_operator_permission_shop_radar'),
  _PermissionSpec('ai_assistant', 'admin_operator_permission_ai_assistant'),
  _PermissionSpec('orders', 'admin_operator_permission_orders'),
  _PermissionSpec(
    'payment_reconcile',
    'admin_operator_permission_payment_reconcile',
  ),
  _PermissionSpec(
    'payment_exception_mark',
    'admin_operator_permission_payment_exception_mark',
  ),
  _PermissionSpec('order_manage', 'admin_operator_permission_order_manage'),
  _PermissionSpec('inventory_read', 'admin_operator_permission_inventory_read'),
  _PermissionSpec(
      'inventory_write', 'admin_operator_permission_inventory_write'),
];

const List<_RoleTemplateSpec> _roleTemplateSpecs = <_RoleTemplateSpec>[
  _RoleTemplateSpec(
    'standard',
    'admin_operator_template_standard',
    'admin_operator_template_standard_desc',
    _defaultPermissionKeys,
  ),
  _RoleTemplateSpec(
    'patrol',
    'admin_operator_template_patrol',
    'admin_operator_template_patrol_desc',
    <String>['shop_radar', 'ai_assistant'],
  ),
  _RoleTemplateSpec(
    'order',
    'admin_operator_template_order',
    'admin_operator_template_order_desc',
    _orderSpecialistPermissionKeys,
  ),
  _RoleTemplateSpec(
    'inventory',
    'admin_operator_template_inventory',
    'admin_operator_template_inventory_desc',
    <String>['inventory_read', 'inventory_write'],
  ),
  _RoleTemplateSpec(
    'supervisor',
    'admin_operator_template_supervisor',
    'admin_operator_template_supervisor_desc',
    _supervisorPermissionKeys,
  ),
];

const List<OperatorAccount> _fallbackOperatorAccounts = <OperatorAccount>[
  OperatorAccount(
    id: 'operator_1',
    username: 'admin_operator_default_name_1',
    phone: '13800000001',
    operatorNumber: 1,
    permissions: _defaultPermissionKeys,
  ),
  OperatorAccount(
    id: 'operator_2',
    username: 'admin_operator_default_name_2',
    phone: '13800000002',
    operatorNumber: 2,
    permissions: _defaultPermissionKeys,
  ),
  OperatorAccount(
    id: 'operator_3',
    username: 'admin_operator_default_name_3',
    phone: '13800000003',
    operatorNumber: 3,
    permissions: _defaultPermissionKeys,
  ),
  OperatorAccount(
    id: 'operator_4',
    username: 'admin_operator_default_name_4',
    phone: '13800000004',
    operatorNumber: 4,
    permissions: _defaultPermissionKeys,
  ),
];

const List<_OperatorSnapshot> _operatorSnapshots = <_OperatorSnapshot>[
  _OperatorSnapshot(
    operatorNumber: 1,
    focusKey: 'admin_operator_focus_recovery',
    stageKey: 'admin_operator_stage_stable',
    responseSlaKey: 'admin_operator_sla_15',
    report: OperatorReport(
      operatorId: 1,
      operatorName: 'OP-01',
      contactShops: 23,
      intentionCount: 8,
      successCount: 3,
      aiUsageCount: 156,
      orderAmount: 8560,
    ),
  ),
  _OperatorSnapshot(
    operatorNumber: 2,
    focusKey: 'admin_operator_focus_onboarding',
    stageKey: 'admin_operator_stage_growing',
    responseSlaKey: 'admin_operator_sla_12',
    report: OperatorReport(
      operatorId: 2,
      operatorName: 'OP-02',
      contactShops: 31,
      intentionCount: 12,
      successCount: 5,
      aiUsageCount: 184,
      orderAmount: 12680,
    ),
  ),
  _OperatorSnapshot(
    operatorNumber: 3,
    focusKey: 'admin_operator_focus_vip',
    stageKey: 'admin_operator_stage_top',
    responseSlaKey: 'admin_operator_sla_10',
    report: OperatorReport(
      operatorId: 3,
      operatorName: 'OP-03',
      contactShops: 19,
      intentionCount: 11,
      successCount: 6,
      aiUsageCount: 143,
      orderAmount: 18900,
    ),
  ),
  _OperatorSnapshot(
    operatorNumber: 4,
    focusKey: 'admin_operator_focus_reactivation',
    stageKey: 'admin_operator_stage_recovering',
    responseSlaKey: 'admin_operator_sla_18',
    report: OperatorReport(
      operatorId: 4,
      operatorName: 'OP-04',
      contactShops: 27,
      intentionCount: 9,
      successCount: 4,
      aiUsageCount: 132,
      orderAmount: 9740,
    ),
  ),
];
