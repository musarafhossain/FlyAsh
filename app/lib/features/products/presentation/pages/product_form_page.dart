import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../../core/widgets/form_submit.dart';
import '../../../../core/widgets/page_layout.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../data/products_repository_impl.dart';
import '../../domain/product.dart';
import 'products_list_page.dart';

/// Add a product, or edit one (with Activate/Deactivate and Delete).
/// Form: name, unit (+ label for "Other"), default cost, default price,
/// notes, and the margin per unit worked out while typing.
class ProductFormPage extends ConsumerStatefulWidget {
  const ProductFormPage({super.key, this.productId});

  /// Null = add a new product.
  final int? productId;

  @override
  ConsumerState<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends ConsumerState<ProductFormPage>
    with FormSubmit {
  final _name = TextEditingController();
  final _unitLabel = TextEditingController();
  final _cost = TextEditingController();
  final _price = TextEditingController();
  final _notes = TextEditingController();
  ProductUnit _unit = ProductUnit.piece;

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
    for (final c in [_name, _unitLabel, _cost, _price, _notes]) {
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
        _unit = p.unit;
        _unitLabel.text = p.unitLabel ?? '';
        _cost.text = _plain(p.defaultCost);
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

  /// price − cost while typing; null until both are valid numbers.
  Decimal? get _margin {
    final cost = Decimal.tryParse(_cost.text.trim());
    final price = Decimal.tryParse(_price.text.trim());
    return (cost == null || price == null) ? null : price - cost;
  }

  Future<void> _save() async {
    final repo = ref.read(productsRepositoryProvider);
    final input = ProductInput(
      name: _name.text,
      unit: _unit,
      unitLabel: _unitLabel.text,
      defaultCost: _cost.text.trim(),
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

  Future<void> _toggleActive() async {
    final p = _product!;
    final l = context.l10n;
    final deactivate = p.isActive;
    final ok = await showConfirmDialog(
      context,
      title: deactivate
          ? l.deactivateProductTitle(p.name)
          : l.activateProductTitle(p.name),
      message: deactivate
          ? l.deactivateProductMessage
          : l.activateProductMessage,
      confirmLabel: deactivate ? l.deactivate : l.activate,
      destructive: deactivate,
    );
    if (!ok || !mounted) return;
    setState(() => _acting = true);
    try {
      final (updated, message) = await ref
          .read(productsRepositoryProvider)
          .setActive(p.id, !deactivate);
      if (!mounted) return;
      setState(() => _product = updated);
      showMessage(context, message);
    } on Failure catch (f) {
      if (mounted) showMessage(context, failureText(context, f));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _delete() async {
    final p = _product!;
    final l = context.l10n;
    final ok = await showConfirmDialog(
      context,
      title: l.deleteProductTitle(p.name),
      message: l.deleteProductMessage,
      confirmLabel: l.delete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _acting = true);
    try {
      final message = await ref.read(productsRepositoryProvider).delete(p.id);
      if (!mounted) return;
      showMessage(context, message);
      Navigator.of(context).pop();
    } on Failure catch (f) {
      // 409: used in sales → the server says to deactivate instead.
      if (mounted) showMessage(context, failureText(context, f));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
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
                : const Center(child: CircularProgressIndicator()))
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
      Text(
        l.unitField,
        style: AppTypography.label.copyWith(color: t.textSecondary),
      ),
      const SizedBox(height: Space.s2),
      Wrap(
        spacing: Space.s2,
        runSpacing: Space.s2,
        children: [
          for (final unit in ProductUnit.values)
            ChoiceChip(
              label: Text(unitText(l, unit)),
              selected: _unit == unit,
              onSelected: (_) => setState(() => _unit = unit),
            ),
        ],
      ),
      if (_unit == ProductUnit.other) ...[
        const SizedBox(height: Space.s3),
        TextFormField(
          controller: _unitLabel,
          textInputAction: TextInputAction.next,
          maxLength: 30,
          validator: v.required,
          decoration: InputDecoration(
            labelText: l.unitLabel,
            hintText: l.unitLabelHint,
            errorText: fieldErrors['unit_label'],
            counterText: '',
          ),
        ),
      ],
      const SizedBox(height: Space.s4),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: MoneyField(
              controller: _cost,
              label: l.defaultCost,
              helperText: l.perUnit(unitText(l, _unit, _unitLabel.text)),
              validator: v.money,
              errorText: fieldErrors['default_cost'],
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: Space.s3),
          Expanded(
            child: MoneyField(
              controller: _price,
              label: l.defaultPrice,
              helperText: l.perUnit(unitText(l, _unit, _unitLabel.text)),
              validator: v.money,
              errorText: fieldErrors['default_price'],
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
      const SizedBox(height: Space.s3),
      _MarginPreview(margin: _margin),
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

/// "Margin per unit ₹2.50" (green) or "Loss per unit ₹1.00" (red).
class _MarginPreview extends StatelessWidget {
  const _MarginPreview({required this.margin});

  final Decimal? margin;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final m = margin;
    final loss = m != null && m < Decimal.zero;
    final fg = m == null ? t.textTertiary : (loss ? t.error : t.success);
    final bg = m == null ? t.surfaceVariant : (loss ? t.errorBg : t.successBg);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.s4,
        vertical: Space.s3,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: Radii.mdAll),
      child: Row(
        children: [
          Icon(loss ? Icons.trending_down : Icons.trending_up, color: fg),
          const SizedBox(width: Space.s3),
          Expanded(
            child: Text(
              loss ? l.lossPerUnit : l.marginPerUnit,
              style: AppTypography.body.copyWith(color: fg),
            ),
          ),
          Text(
            m == null
                ? '—'
                : Fmt.money((loss ? -m : m).toString(), decimals: true),
            style: AppTypography.title.copyWith(
              color: fg,
              fontFeatures: AppTypography.tabular,
            ),
          ),
        ],
      ),
    );
  }
}
