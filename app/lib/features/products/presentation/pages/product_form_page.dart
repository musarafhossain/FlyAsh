import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import '../../../../core/widgets/status_pill.dart';
import '../../data/products_repository_impl.dart';
import '../../domain/product.dart';
import '../product_actions.dart';
import '../../../../core/widgets/skeletons.dart';

/// Add a product, or edit one (with Activate/Deactivate and Delete).
/// Form: name, default price and notes.
class ProductFormPage extends ConsumerStatefulWidget {
  const ProductFormPage({super.key, this.productId});

  /// Null = add a new product.
  final String? productId;

  @override
  ConsumerState<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends ConsumerState<ProductFormPage>
    with FormSubmit {
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _notes = TextEditingController();

  Product? _product; // the saved product when editing
  bool _loaded = false;
  Object? _loadError;
  bool _acting = false; // activate / delete in progress

  bool get _isEdit => widget.productId != null;

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
    for (final c in [_name, _price, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final p = await ref
          .read(productsRepositoryProvider)
          .get(widget.productId!);
      if (!mounted) return;
      setState(() {
        _product = p;
        _name.text = p.name;
        _price.text = _plain(p.defaultPrice);
        _notes.text = p.notes ?? '';
        _loaded = true;
      });
    } on Failure catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  /// "4.50" → "4.5", "7.00" → "7" (easier to edit; same value).
  static String _plain(String v) =>
      (Decimal.tryParse(v) ?? Decimal.zero).toString();

  Future<void> _save() async {
    final repo = ref.read(productsRepositoryProvider);
    final input = ProductInput(
      name: _name.text,
      defaultPrice: _price.text.trim(),
      notes: textOrNull(_notes),
    );
    final ok = await submit(() async {
      _product = _isEdit
          ? await repo.update(widget.productId!, input)
          : await repo.create(input);
    });
    if (!ok || !mounted) return;
    final l = context.l10n;
    showMessage(context, _isEdit ? l.productUpdated : l.productCreated);
    Navigator.of(context).pop(_product);
  }

  void _busy(bool v) {
    if (mounted) setState(() => _acting = v);
  }

  Future<void> _toggleActive() async {
    final updated = await toggleProductActive(
      context,
      ref,
      _product!,
      onBusy: _busy,
    );
    if (updated != null && mounted) setState(() => _product = updated);
  }

  Future<void> _delete() async {
    final deleted = await deleteProduct(context, ref, _product!, onBusy: _busy);
    if (deleted && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? l.editProduct : l.addProduct)),
      body: !_loaded
          ? (_loadError != null
                ? ErrorState(
                    message: failureText(context, _loadError!),
                    onRetry: _load,
                  )
                : const FormSkeleton(fields: 5, big: {4}))
          : Form(
              key: formKey,
              child: PageBody(children: _fields(context)),
            ),
    );
  }

  List<Widget> _fields(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final v = Validators.of(context);
    final p = _product;

    return [
      if (p != null && !p.isActive) ...[
        Row(
          children: [
            StatusPill(l.inactive),
            const SizedBox(width: Space.s2),
            Expanded(
              child: Text(
                l.inactiveProductHint,
                style: AppTypography.caption.copyWith(color: t.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.s4),
      ],
      TextFormField(
        controller: _name,
        textInputAction: TextInputAction.next,
        textCapitalization: TextCapitalization.words,
        maxLength: 100,
        validator: v.required,
        decoration: InputDecoration(
          labelText: l.productName,
          hintText: l.productNameHint,
          prefixIcon: const Icon(Icons.view_module_outlined),
          errorText: fieldErrors['name'],
          counterText: '',
        ),
      ),
      const SizedBox(height: Space.s4),
      MoneyField(
        controller: _price,
        label: l.defaultPrice,
        validator: v.money,
        errorText: fieldErrors['default_price'],
      ),
      const SizedBox(height: Space.s4),
      TextFormField(
        controller: _notes,
        minLines: 2,
        maxLines: 4,
        maxLength: 500,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: l.notesOptional,
          errorText: fieldErrors['notes'],
        ),
      ),
      const SizedBox(height: Space.s4),
      if (error != null) ...[
        FormErrorBanner(error!),
        const SizedBox(height: Space.s3),
      ],
      BusyButton(
        label: _isEdit ? l.save : l.addProduct,
        busy: busy,
        onPressed: _save,
      ),
      if (p != null) ...[
        const SizedBox(height: Space.s6),
        MenuGroup(
          children: [
            MenuRow(
              icon: p.isActive ? Icons.block : Icons.check_circle_outline,
              title: p.isActive ? l.deactivate : l.activate,
              subtitle: p.isActive ? l.deactivateProductMessage : null,
              showChevron: false,
              onTap: _acting ? null : _toggleActive,
            ),
            MenuRow(
              icon: Icons.delete_outline,
              title: l.delete,
              subtitle: l.deleteProductMessage,
              color: t.error,
              showChevron: false,
              onTap: _acting ? null : _delete,
            ),
          ],
        ),
      ],
    ];
  }
}
