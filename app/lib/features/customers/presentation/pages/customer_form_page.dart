import '../../../../core/network/api_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../../core/widgets/form_submit.dart';
import '../../../../core/widgets/page_layout.dart';
import '../../../../core/widgets/state_views.dart';
import '../../data/customers_repository_impl.dart';
import '../../domain/customer.dart';
import '../../../../core/widgets/skeletons.dart';

/// Add or edit a customer; pops with the saved [Customer] (the list then
/// opens a new customer's detail page).
/// A phone that already belongs to a customer is blocked and the form
/// offers to open that customer (PRD CUST-4).
class CustomerFormPage extends ConsumerStatefulWidget {
  const CustomerFormPage({super.key, this.customerId});

  /// Null = add a new customer.
  final String? customerId;

  @override
  ConsumerState<CustomerFormPage> createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends ConsumerState<CustomerFormPage>
    with FormSubmit {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  bool _loaded = false;
  Object? _loadError;

  bool get _isEdit => widget.customerId != null;

  /// From a 422 "This phone belongs to …".
  String? get _existingId => idOrNull(errorData?['existing_customer_id']);

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
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final c = await ref
          .read(customersRepositoryProvider)
          .get(widget.customerId!);
      if (!mounted) return;
      setState(() {
        _name.text = c.name;
        _phone.text = c.phone;
        _address.text = c.address ?? '';
        _loaded = true;
      });
    } on Failure catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  Future<void> _save() async {
    final repo = ref.read(customersRepositoryProvider);
    final input = CustomerInput(
      name: _name.text,
      phone: _phone.text,
      address: textOrNull(_address),
    );
    late Customer saved;
    final ok = await submit(() async {
      saved = _isEdit
          ? await repo.update(widget.customerId!, input)
          : await repo.create(input);
    });
    if (!ok || !mounted) return;
    final l = context.l10n;
    showMessage(context, _isEdit ? l.customerUpdated : l.customerCreated);
    context.pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final v = Validators.of(context);
    final t = context.tokens;

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? l.editCustomer : l.addCustomer)),
      body: !_loaded
          ? (_loadError != null
                ? ErrorState(
                    message: failureText(context, _loadError!),
                    onRetry: _load,
                  )
                : const FormSkeleton(fields: 3, big: {2}))
          : Form(
              key: formKey,
              child: PageBody(
                children: [
                  TextFormField(
                    controller: _name,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 100,
                    validator: v.required,
                    decoration: InputDecoration(
                      labelText: l.nameField,
                      hintText: l.customerNameHint,
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
                      prefixIcon: const Icon(Icons.phone_outlined),
                      prefixText: '+91 ',
                      errorText: fieldErrors['phone'],
                    ),
                  ),
                  if (_existingId != null && _existingId != widget.customerId)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () =>
                            context.pushReplacement('/customers/$_existingId'),
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: Text(l.openExistingCustomer),
                      ),
                    ),
                  const SizedBox(height: Space.s3),
                  TextFormField(
                    controller: _address,
                    minLines: 2,
                    maxLines: 4,
                    maxLength: 500,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: l.addressOptional,
                      prefixIcon: const Icon(Icons.place_outlined),
                      errorText: fieldErrors['address'],
                    ),
                  ),
                  const SizedBox(height: Space.s2),
                  Text(
                    l.customerPhoneHint,
                    style: AppTypography.caption.copyWith(
                      color: t.textTertiary,
                    ),
                  ),
                  const SizedBox(height: Space.s5),
                  if (error != null) ...[
                    FormErrorBanner(error!),
                    const SizedBox(height: Space.s3),
                  ],
                  BusyButton(
                    label: _isEdit ? l.save : l.addCustomer,
                    busy: busy,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
    );
  }
}
