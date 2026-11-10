import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/network/session.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/controls.dart';
import '../../../../core/widgets/date_field.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../../core/widgets/form_submit.dart';
import '../../../../core/widgets/page_layout.dart';
import '../../../../core/widgets/state_views.dart';
import '../../data/labours_repository_impl.dart';
import '../../domain/labour.dart';
import '../../../../core/widgets/skeletons.dart';

/// Add or edit a labour (03-AppFlow §7.1): name, phone (optional),
/// address, wage type Daily / Monthly + wage amount (both required),
/// joining date. Pops with the saved [Labour].
class LabourFormPage extends ConsumerStatefulWidget {
  const LabourFormPage({super.key, this.labourId});

  /// Null = add a new labour.
  final String? labourId;

  @override
  ConsumerState<LabourFormPage> createState() => _LabourFormPageState();
}

class _LabourFormPageState extends ConsumerState<LabourFormPage>
    with FormSubmit {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _wage = TextEditingController();
  String _wageType = 'daily';
  late String _joiningDate = ref.read(businessDateProvider);
  String? _oldWage; // to explain that a change applies from now on
  bool _loaded = false;
  Object? _loadError;

  bool get _isEdit => widget.labourId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _load();
    } else {
      _loaded = true;
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _address, _wage]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final lb = await ref
          .read(laboursRepositoryProvider)
          .get(widget.labourId!);
      if (!mounted) return;
      setState(() {
        _name.text = lb.name;
        _phone.text = lb.phone ?? '';
        _address.text = lb.address ?? '';
        _wageType = lb.wageType;
        _wage.text = (Decimal.tryParse(lb.wageAmount) ?? Decimal.zero)
            .toString();
        _oldWage = _wage.text;
        _joiningDate = lb.joiningDate;
        _loaded = true;
      });
    } on Failure catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  Future<void> _save() async {
    final repo = ref.read(laboursRepositoryProvider);
    final input = LabourInput(
      name: _name.text,
      phone: textOrNull(_phone),
      address: textOrNull(_address),
      wageType: _wageType,
      wageAmount: _wage.text.trim(),
      joiningDate: _joiningDate,
    );
    late Labour saved;
    final ok = await submit(() async {
      saved = _isEdit
          ? await repo.update(widget.labourId!, input)
          : await repo.create(input);
    });
    if (!ok || !mounted) return;
    final l = context.l10n;
    showMessage(context, _isEdit ? l.labourUpdated : l.labourCreated);
    context.pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final v = Validators.of(context);
    final today = ref.read(businessDateProvider);
    final wageChanged = _isEdit && _oldWage != null && _wage.text != _oldWage;

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? l.editLabour : l.addLabour)),
      body: !_loaded
          ? (_loadError != null
                ? ErrorState(
                    message: failureText(context, _loadError!),
                    onRetry: _load,
                  )
                : const FormSkeleton(fields: 6, big: {2}))
          : Form(
              key: formKey,
              child: PageBody(
                children: [
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    maxLength: 100,
                    validator: v.required,
                    decoration: InputDecoration(
                      labelText: l.nameField,
                      prefixIcon: const Icon(Icons.person_outline),
                      errorText: fieldErrors['name'],
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: Space.s3),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: v.optionalPhone,
                    decoration: InputDecoration(
                      labelText: l.phoneOptional,
                      prefixText: '+91 ',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      errorText: fieldErrors['phone'],
                    ),
                  ),
                  const SizedBox(height: Space.s3),
                  TextFormField(
                    controller: _address,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l.addressOptional,
                      prefixIcon: const Icon(Icons.place_outlined),
                      errorText: fieldErrors['address'],
                    ),
                  ),
                  const SizedBox(height: Space.s5),
                  Text(
                    l.wage,
                    style: AppTypography.label.copyWith(color: t.textSecondary),
                  ),
                  const SizedBox(height: Space.s2),
                  SegmentedTabs<String>(
                    segments: {'daily': l.wageDaily, 'monthly': l.wageMonthly},
                    selected: _wageType,
                    onChanged: (type) => setState(() => _wageType = type),
                  ),
                  const SizedBox(height: Space.s3),
                  MoneyField(
                    controller: _wage,
                    label: _wageType == 'monthly'
                        ? l.wagePerMonth
                        : l.wagePerDay,
                    helperText: _wageType == 'monthly'
                        ? l.monthlyWageHint
                        : l.dailyWageHint,
                    validator: (x) {
                      final e = v.money(x);
                      if (e != null) return e;
                      return Decimal.parse(x!.trim()) > Decimal.zero
                          ? null
                          : l.invalidAmount;
                    },
                    errorText:
                        fieldErrors['wage_amount'] ?? fieldErrors['wage_type'],
                    onChanged: (_) => setState(() {}),
                  ),
                  if (wageChanged) ...[
                    const SizedBox(height: Space.s2),
                    Text(
                      l.wageChangeHint,
                      style: AppTypography.caption.copyWith(color: t.warning),
                    ),
                  ],
                  const SizedBox(height: Space.s4),
                  DateField(
                    label: l.joiningDate,
                    value: _joiningDate,
                    first: '2015-01-01',
                    last: today,
                    errorText: fieldErrors['joining_date'],
                    onChanged: (d) => setState(() => _joiningDate = d),
                  ),
                  const SizedBox(height: Space.s5),
                  if (error != null) ...[
                    FormErrorBanner(error!),
                    const SizedBox(height: Space.s3),
                  ],
                  BusyButton(
                    label: _isEdit ? l.save : l.addLabour,
                    busy: busy,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
    );
  }
}
