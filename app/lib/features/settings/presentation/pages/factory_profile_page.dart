import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../../core/widgets/form_submit.dart';
import '../../../../core/widgets/page_layout.dart';
import '../../../../core/widgets/state_views.dart';
import '../../data/settings_repository_impl.dart';
import '../../domain/factory_settings.dart';

/// Settings → Factory profile (PUT /settings/factory). Shown on receipts.
class FactoryProfilePage extends ConsumerWidget {
  const FactoryProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final async = ref.watch(factorySettingsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.factoryProfile)),
      body: async.when(
        data: (settings) => _FactoryForm(initial: settings),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: failureText(context, e),
          onRetry: () => ref.invalidate(factorySettingsProvider),
        ),
      ),
    );
  }
}

class _FactoryForm extends ConsumerStatefulWidget {
  const _FactoryForm({required this.initial});

  final FactorySettings initial;

  @override
  ConsumerState<_FactoryForm> createState() => _FactoryFormState();
}

class _FactoryFormState extends ConsumerState<_FactoryForm> with FormSubmit {
  late final _name = TextEditingController(text: widget.initial.factoryName);
  late final _owner = TextEditingController(text: widget.initial.ownerName);
  late final _phone = TextEditingController(text: widget.initial.phone);
  late final _email = TextEditingController(text: widget.initial.email);
  late final _address = TextEditingController(text: widget.initial.address);
  late final _prefix = TextEditingController(
    text: widget.initial.invoicePrefix,
  );

  static final _prefixPattern = RegExp(r'^[A-Z0-9-]{1,10}$');

  @override
  void dispose() {
    for (final c in [_name, _owner, _phone, _email, _address, _prefix]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    late String message;
    final ok = await submit(() async {
      final (_, msg) = await ref
          .read(settingsRepositoryProvider)
          .saveFactory(
            FactorySettings(
              factoryName: _name.text.trim(),
              ownerName: textOrNull(_owner),
              phone: textOrNull(_phone),
              email: textOrNull(_email),
              address: textOrNull(_address),
              invoicePrefix: _prefix.text.trim().toUpperCase(),
            ),
          );
      message = msg;
      ref.invalidate(factorySettingsProvider);
    });
    if (!ok || !mounted) return;
    showMessage(context, message);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final v = Validators.of(context);

    InputDecoration deco(String label, IconData icon, String field) =>
        InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          errorText: fieldErrors[field],
          counterText: '',
        );

    return Form(
      key: formKey,
      child: PageBody(
        children: [
          TextFormField(
            controller: _name,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            maxLength: 150,
            validator: v.required,
            decoration: deco(
              l.factoryName,
              Icons.factory_outlined,
              'factory_name',
            ),
          ),
          const SizedBox(height: Space.s3),
          TextFormField(
            controller: _owner,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            maxLength: 100,
            decoration: deco(l.ownerName, Icons.person_outline, 'owner_name'),
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
            decoration: deco(l.phoneField, Icons.phone_outlined, 'phone'),
          ),
          const SizedBox(height: Space.s3),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: v.optionalEmail,
            decoration: deco(l.emailField, Icons.mail_outline, 'email'),
          ),
          const SizedBox(height: Space.s3),
          TextFormField(
            controller: _address,
            minLines: 2,
            maxLines: 4,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: deco(l.addressField, Icons.place_outlined, 'address'),
          ),
          const SizedBox(height: Space.s3),
          TextFormField(
            controller: _prefix,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              LengthLimitingTextInputFormatter(10),
              _UpperCase(),
            ],
            validator: (value) =>
                v.required(value) ??
                (_prefixPattern.hasMatch(value!.trim())
                    ? null
                    : l.invoicePrefixRule),
            decoration: deco(
              l.invoicePrefix,
              Icons.tag,
              'invoice_prefix',
            ).copyWith(helperText: l.invoicePrefixHint, helperMaxLines: 2),
          ),
          const SizedBox(height: Space.s5),
          if (error != null) ...[
            FormErrorBanner(error!),
            const SizedBox(height: Space.s3),
          ],
          BusyButton(label: l.save, busy: busy, onPressed: _save),
        ],
      ),
    );
  }
}

class _UpperCase extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue _, TextEditingValue v) =>
      v.copyWith(text: v.text.toUpperCase());
}
