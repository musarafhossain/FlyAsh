import '../../../../core/network/api_response.dart';
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
import '../../../../core/utils/dates.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/cards.dart';
import '../../../../core/widgets/controls.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../../core/widgets/form_submit.dart';
import '../../../../core/widgets/list_items.dart';
import '../../../../core/widgets/page_layout.dart';
import '../../../../core/widgets/search_picker_sheet.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../customers/data/customers_repository_impl.dart';
import '../../../customers/domain/customer.dart';
import '../../../products/data/products_repository_impl.dart';
import '../../../products/domain/product.dart';
import '../../../products/presentation/pages/products_list_page.dart';
import '../../data/sales_repository_impl.dart';
import '../../domain/sale.dart';
import '../sale_labels.dart';
import '../../../../core/widgets/skeletons.dart';

/// Payment methods the API accepts.
const kPaymentMethods = ['cash', 'upi', 'bank', 'other'];

Decimal _dec(String text) => Decimal.tryParse(text.trim()) ?? Decimal.zero;

/// One item card in the form.
class _ItemRow {
  _ItemRow({
    this.productId,
    this.productName,
    this.unit = ProductUnit.piece,
    String quantity = '',
    String price = '',
    String cost = '',
  }) : quantity = TextEditingController(text: quantity),
       price = TextEditingController(text: price),
       cost = TextEditingController(text: cost);

  final key = UniqueKey();
  String? productId;
  String? productName;
  ProductUnit unit;
  String? unitLabel;
  final TextEditingController quantity;
  final TextEditingController price;
  final TextEditingController cost;

  Decimal get lineTotal => _dec(quantity.text) * _dec(price.text);
  Decimal get lineCost => _dec(quantity.text) * _dec(cost.text);

  void dispose() {
    quantity.dispose();
    price.dispose();
    cost.dispose();
  }
}

/// New sale or booking, or edit a sale (03-AppFlow §5.1):
/// type → customer (pick, or add a new one inline) → dates → items
/// (product fills cost and price, both editable) → transport, discount →
/// payment received now (new sales only) → notes. The summary bar shows
/// Total · Profit · Due live; the server's numbers are final after save.
/// Leaving with unsaved changes asks first. Pops with the saved [Sale].
class SaleFormPage extends ConsumerStatefulWidget {
  const SaleFormPage({
    super.key,
    this.saleId,
    this.initialType = 'instant',
    this.customerId,
  });

  /// Null = new sale.
  final String? saleId;

  /// instant | booking (new sales; from `?type=`).
  final String initialType;

  /// Start with this customer selected (from `?customer=`).
  final String? customerId;

  @override
  ConsumerState<SaleFormPage> createState() => _SaleFormPageState();
}

class _SaleFormPageState extends ConsumerState<SaleFormPage> with FormSubmit {
  late String _type = widget.initialType == 'booking' ? 'booking' : 'instant';
  Customer? _customer;
  bool _newCustomer = false;
  final _ncName = TextEditingController();
  final _ncPhone = TextEditingController();
  final _ncAddress = TextEditingController();

  late String _saleDate = ref.read(businessDateProvider);

  /// A booking needs a delivery date; it starts at the sale date.
  late String? _deliveryDate = _type == 'booking' ? _saleDate : null;
  final _deliveryAddress = TextEditingController();
  final List<_ItemRow> _items = [_ItemRow()];
  final _transport = TextEditingController();
  final _discount = TextEditingController();
  final _payAmount = TextEditingController();
  final _payNote = TextEditingController();
  String _payMethod = 'cash';
  final _notes = TextEditingController();

  /// Already paid (edit): the new total cannot be below it.
  String _paidBefore = '0';

  bool _loaded = false;
  Object? _loadError;
  bool _dirty = false;
  String? _customerError;

  /// After the first Save tap: empty item cards say "Select a product".
  bool _triedSave = false;

  bool get _isEdit => widget.saleId != null;
  String get _today => ref.read(businessDateProvider);

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _loadSale();
    } else if (widget.customerId != null) {
      _loadCustomer(widget.customerId!);
    } else {
      _loaded = true;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _ncName,
      _ncPhone,
      _ncAddress,
      _deliveryAddress,
      _transport,
      _discount,
      _payAmount,
      _payNote,
      _notes,
    ]) {
      c.dispose();
    }
    for (final i in _items) {
      i.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------- load

  Future<void> _loadCustomer(String id) async {
    try {
      final c = await ref.read(customersRepositoryProvider).get(id);
      if (mounted) setState(() => _customer = c);
    } on Failure {
      // Still usable: the user picks a customer.
    } finally {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _loadSale() async {
    setState(() => _loadError = null);
    try {
      final sale = await ref.read(salesRepositoryProvider).get(widget.saleId!);
      if (!mounted) return;
      final s = sale.summary;
      String plain(String v) => _dec(v).toString();
      setState(() {
        _type = s.type;
        _customer = Customer(
          id: s.customerId ?? '',
          name: s.customerName ?? '',
          phone: s.customerPhone ?? '',
          address: sale.customerAddress,
        );
        _saleDate = s.saleDate;
        _deliveryDate = s.deliveryDate;
        _deliveryAddress.text = sale.deliveryAddress ?? '';
        for (final i in _items) {
          i.dispose();
        }
        _items
          ..clear()
          ..addAll([
            for (final item in sale.items)
              _ItemRow(
                productId: item.productId,
                productName: item.productName,
                unit: item.unit,
                quantity: plain(item.quantity),
                price: plain(item.unitPrice),
                cost: plain(item.unitCost),
              ),
          ]);
        if (_items.isEmpty) _items.add(_ItemRow());
        _transport.text = Sale.isZeroAmount(sale.transportCharge)
            ? ''
            : plain(sale.transportCharge);
        _discount.text = Sale.isZeroAmount(sale.discount)
            ? ''
            : plain(sale.discount);
        _notes.text = sale.notes ?? '';
        _paidBefore = s.paidAmount;
        _loaded = true;
      });
    } on Failure catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  // -------------------------------------------------------------- totals

  Decimal get _subtotal =>
      _items.fold(Decimal.zero, (sum, i) => sum + i.lineTotal);
  Decimal get _cost => _items.fold(Decimal.zero, (sum, i) => sum + i.lineCost);
  Decimal get _total =>
      _subtotal + _dec(_transport.text) - _dec(_discount.text);
  Decimal get _paid => _isEdit ? _dec(_paidBefore) : _dec(_payAmount.text);

  void _changed() => setState(() => _dirty = true);

  // ------------------------------------------------------------- pickers

  Future<void> _pickCustomer() async {
    final l = context.l10n;
    final repo = ref.read(customersRepositoryProvider);
    final picked = await showSearchPicker<Customer>(
      context,
      title: l.selectCustomer,
      searchHint: l.searchNamePhone,
      fetch: (page, search) =>
          repo.list(page: page, search: search, active: true),
      header: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            setState(() {
              _newCustomer = true;
              _customer = null;
              _customerError = null;
              _dirty = true;
            });
          },
          icon: const Icon(Icons.person_add_alt_1),
          label: Text(l.newCustomer),
        ),
      ),
      itemBuilder: (context, c) => _PickTile(
        leading: InitialsAvatar(c.name),
        title: c.name,
        subtitle: c.phone,
        trailing: c.hasDue ? l.dueAmount(Fmt.money(c.totalDue)) : null,
        onTap: () => Navigator.of(context).pop(c),
      ),
    );
    if (picked != null) {
      setState(() {
        _customer = picked;
        _newCustomer = false;
        _customerError = null;
        _dirty = true;
      });
    }
  }

  Future<void> _pickProduct(_ItemRow row) async {
    final l = context.l10n;
    final repo = ref.read(productsRepositoryProvider);
    final picked = await showSearchPicker<Product>(
      context,
      title: l.selectProduct,
      searchHint: l.searchProducts,
      fetch: (page, search) =>
          repo.list(page: page, search: search, active: true),
      itemBuilder: (context, p) => _PickTile(
        leading: const ProductIcon(size: 40),
        title: p.name,
        subtitle:
            '${Fmt.money(p.defaultPrice, decimals: true)} '
            '${l.perUnit(unitText(l, p.unit, p.unitLabel))}',
        onTap: () => Navigator.of(context).pop(p),
      ),
    );
    if (picked == null) return;
    String plain(String v) => _dec(v).toString();
    setState(() {
      row
        ..productId = picked.id
        ..productName = picked.name
        ..unit = picked.unit
        ..unitLabel = picked.unitLabel;
      row.price.text = plain(picked.defaultPrice);
      row.cost.text = plain(picked.defaultCost);
      _dirty = true;
    });
  }

  Future<void> _pickDate({
    required String current,
    required String first,
    required String last,
    required ValueChanged<String> onPicked,
  }) async {
    DateTime local(String ymd) {
      final d = Ymd.parse(ymd);
      return DateTime(d.year, d.month, d.day);
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: local(current),
      firstDate: local(first),
      lastDate: local(last),
    );
    if (picked != null) {
      onPicked(Ymd.format(DateTime.utc(picked.year, picked.month, picked.day)));
      _changed();
    }
  }

  // ---------------------------------------------------------------- save

  Future<void> _save() async {
    final l = context.l10n;
    // Checks the form fields cannot express.
    setState(() {
      _triedSave = true;
      _customerError = (_customer == null && !_newCustomer)
          ? l.selectCustomerError
          : null;
    });
    final missingProduct = _items.any((i) => i.productId == null);
    if (_customerError != null || missingProduct) {
      formKey.currentState?.validate();
      setState(() {}); // shows "Select a product" on empty item cards
      return;
    }

    final input = SaleInput(
      type: _type,
      customerId: _newCustomer ? null : _customer!.id,
      newCustomer: _newCustomer
          ? NewCustomerInput(
              name: _ncName.text,
              phone: _ncPhone.text,
              address: textOrNull(_ncAddress),
            )
          : null,
      saleDate: _saleDate,
      deliveryDate: _deliveryDate,
      deliveryAddress: textOrNull(_deliveryAddress),
      items: [
        for (final i in _items)
          SaleItemInput(
            productId: i.productId!,
            quantity: i.quantity.text.trim(),
            unitCost: i.cost.text.trim(),
            unitPrice: i.price.text.trim(),
          ),
      ],
      transportCharge: _transport.text.trim().isEmpty
          ? '0'
          : _transport.text.trim(),
      discount: _discount.text.trim().isEmpty ? '0' : _discount.text.trim(),
      payment: !_isEdit && _dec(_payAmount.text) > Decimal.zero
          ? PaymentInput(
              amount: _payAmount.text.trim(),
              method: _payMethod,
              note: textOrNull(_payNote),
            )
          : null,
      notes: textOrNull(_notes),
    );

    final repo = ref.read(salesRepositoryProvider);
    late (Sale, String) result;
    final ok = await submit(() async {
      result = _isEdit
          ? await repo.update(widget.saleId!, input)
          : await repo.create(input);
    });
    if (!ok || !mounted) return;
    final (sale, message) = result;
    setState(() => _dirty = false);
    showMessage(context, message);
    // Back to where the form was opened from (list or detail). A form
    // opened on its own (nothing behind it) goes to the sales list.
    if (context.canPop()) {
      context.pop(sale);
    } else {
      context.go('/sales');
    }
  }

  /// "This phone belongs to …" → use that customer instead.
  Future<void> _useExisting(String id) async {
    try {
      final c = await ref.read(customersRepositoryProvider).get(id);
      if (!mounted) return;
      setState(() {
        _customer = c;
        _newCustomer = false;
        fieldErrors = const {};
        errorData = null;
      });
    } on Failure catch (f) {
      if (mounted) showMessage(context, failureText(context, f));
    }
  }

  Future<void> _confirmLeave() async {
    final l = context.l10n;
    final leave = await showConfirmDialog(
      context,
      title: _isEdit ? l.discardChangesTitle : l.discardSaleTitle,
      message: l.discardSaleMessage,
      confirmLabel: l.discard,
      cancelLabel: l.keepEditing,
      destructive: true,
    );
    if (leave && mounted) {
      setState(() => _dirty = false);
      Navigator.of(context).pop();
    }
  }

  // ----------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isEdit
                ? l.editSale
                : (_type == 'booking' ? l.newBooking : l.newSale),
          ),
        ),
        body: !_loaded
            ? (_loadError != null
                  ? ErrorState(
                      message: failureText(context, _loadError!),
                      onRetry: _loadSale,
                    )
                  : const DetailSkeleton(
                      maxWidth: 760,
                      children: [
                        SkeletonLines(count: 2, title: true),
                        SizedBox(height: Space.s3),
                        SkeletonLines(count: 3, title: true),
                        SizedBox(height: Space.s3),
                        SkeletonLines(count: 4, title: true),
                      ],
                    ))
            : Form(
                key: formKey,
                child: PageBody(maxWidth: 760, children: _sections(context)),
              ),
        bottomNavigationBar: _loaded
            ? _SummaryBar(
                total: _total,
                profit: _total - _cost,
                due: _total - _paid,
                busy: busy,
                saveLabel: _isEdit ? l.save : l.saveSale,
                onSave: _save,
              )
            : null,
      ),
    );
  }

  List<Widget> _sections(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final v = Validators.of(context);
    final booking = _type == 'booking';
    final existingId = idOrNull(errorData?['existing_customer_id']);

    String? payValidator(String? value) {
      if ((value ?? '').trim().isEmpty) return null;
      final e = v.money(value);
      if (e != null) return e;
      return _dec(value!) > _total
          ? l.cannotExceedTotal(Fmt.money(_total.toString(), decimals: true))
          : null;
    }

    String? discountValidator(String? value) {
      if ((value ?? '').trim().isEmpty) return null;
      final e = v.money(value);
      if (e != null) return e;
      final max = _subtotal + _dec(_transport.text);
      return _dec(value!) > max ? l.discountTooHigh : null;
    }

    return [
      if (!_isEdit) ...[
        SegmentedTabs<String>(
          segments: {
            'instant': l.saleTypeInstant,
            'booking': l.saleTypeBooking,
          },
          selected: _type,
          onChanged: (type) {
            setState(() {
              _type = type;
              _deliveryDate ??= type == 'booking' ? _saleDate : null;
            });
            _changed();
          },
        ),
        const SizedBox(height: Space.s2),
        Text(
          booking ? l.bookingHint : l.instantHint,
          style: AppTypography.caption.copyWith(color: t.textTertiary),
        ),
        const SizedBox(height: Space.s4),
      ],

      // Customer
      _Section(
        title: l.customerDetails,
        child: _newCustomer
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _ncName,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: v.required,
                    onChanged: (_) => _changed(),
                    decoration: InputDecoration(
                      labelText: l.nameField,
                      prefixIcon: const Icon(Icons.person_outline),
                      errorText: fieldErrors['new_customer.name'],
                    ),
                  ),
                  const SizedBox(height: Space.s3),
                  TextFormField(
                    controller: _ncPhone,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: v.phone,
                    onChanged: (_) => _changed(),
                    decoration: InputDecoration(
                      labelText: l.phoneField,
                      prefixText: '+91 ',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      errorText: fieldErrors['new_customer.phone'],
                    ),
                  ),
                  if (existingId != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => _useExisting(existingId),
                        icon: const Icon(Icons.how_to_reg, size: 18),
                        label: Text(l.useThisCustomer),
                      ),
                    ),
                  const SizedBox(height: Space.s3),
                  TextFormField(
                    controller: _ncAddress,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => _changed(),
                    decoration: InputDecoration(
                      labelText: l.addressOptional,
                      prefixIcon: const Icon(Icons.place_outlined),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _pickCustomer,
                      icon: const Icon(Icons.search),
                      label: Text(l.pickExistingCustomer),
                    ),
                  ),
                ],
              )
            : _PickerField(
                label: l.selectCustomer,
                value: _customer == null
                    ? null
                    : '${_customer!.name} · ${_customer!.phone}',
                icon: Icons.person_search_outlined,
                errorText: _customerError ?? fieldErrors['customer_id'],
                onTap: _isEdit ? null : _pickCustomer,
              ),
      ),

      // Dates
      _Section(
        title: l.date,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PickerField(
              label: l.saleDate,
              value: Fmt.date(_saleDate),
              icon: Icons.event,
              errorText: fieldErrors['sale_date'],
              onTap: () => _pickDate(
                current: _saleDate,
                first: '2020-01-01',
                last: _today,
                onPicked: (d) => setState(() {
                  _saleDate = d;
                  if (_deliveryDate != null &&
                      _deliveryDate!.compareTo(d) < 0) {
                    _deliveryDate = d;
                  }
                }),
              ),
            ),
            if (booking) ...[
              const SizedBox(height: Space.s3),
              _PickerField(
                label: l.deliveryDate,
                value: _deliveryDate == null ? null : Fmt.date(_deliveryDate),
                icon: Icons.local_shipping_outlined,
                errorText: fieldErrors['delivery_date'],
                onTap: () => _pickDate(
                  current: _deliveryDate ?? _saleDate,
                  first: _saleDate,
                  last: Ymd.addDays(_today, 366),
                  onPicked: (d) => setState(() => _deliveryDate = d),
                ),
              ),
              const SizedBox(height: Space.s3),
              TextFormField(
                controller: _deliveryAddress,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => _changed(),
                decoration: InputDecoration(
                  labelText: l.deliveryAddressOptional,
                  prefixIcon: const Icon(Icons.place_outlined),
                  counterText: '',
                  errorText: fieldErrors['delivery_address'],
                ),
              ),
            ],
          ],
        ),
      ),

      // Items
      _Section(
        title: l.itemsCount('${_items.length}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (fieldErrors['items'] != null) ...[
              Text(
                fieldErrors['items']!,
                style: AppTypography.caption.copyWith(color: t.error),
              ),
              const SizedBox(height: Space.s2),
            ],
            for (final (i, row) in _items.indexed) ...[
              _ItemCard(
                key: row.key,
                index: i,
                row: row,
                errors: fieldErrors,
                showProductError: _triedSave,
                validators: v,
                canRemove: _items.length > 1,
                onPickProduct: () => _pickProduct(row),
                onChanged: _changed,
                onRemove: () {
                  setState(() => _items.removeAt(i).dispose());
                  _changed();
                },
              ),
              const SizedBox(height: Space.s3),
            ],
            OutlinedButton.icon(
              onPressed: _items.length >= 50
                  ? null
                  : () {
                      setState(() => _items.add(_ItemRow()));
                      _changed();
                    },
              icon: const Icon(Icons.add),
              label: Text(l.addItem),
            ),
          ],
        ),
      ),

      // Charges
      _Section(
        title: l.amountSummary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: MoneyField(
                    controller: _transport,
                    label: l.transport,
                    validator: (x) =>
                        (x ?? '').trim().isEmpty ? null : v.money(x),
                    errorText: fieldErrors['transport_charge'],
                    onChanged: (_) => _changed(),
                  ),
                ),
                const SizedBox(width: Space.s3),
                Expanded(
                  child: MoneyField(
                    controller: _discount,
                    label: l.discount,
                    validator: discountValidator,
                    errorText: fieldErrors['discount'],
                    onChanged: (_) => _changed(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.s3),
            LineItemSummaryCard(
              lines: [
                SummaryLine(
                  l.subtotal,
                  Fmt.money(_subtotal.toString(), decimals: true),
                ),
                SummaryLine(
                  l.total,
                  Fmt.money(_total.toString(), decimals: true),
                  emphasis: true,
                ),
                if (_isEdit)
                  SummaryLine(
                    l.alreadyPaid,
                    Fmt.money(_paidBefore, decimals: true),
                    color: t.success,
                  ),
              ],
            ),
          ],
        ),
      ),

      // Payment now (new sales only; later payments are added on the detail page)
      if (!_isEdit)
        _Section(
          title: booking ? l.advanceReceived : l.paymentReceived,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MoneyField(
                controller: _payAmount,
                label: l.amountOptional,
                validator: payValidator,
                errorText: fieldErrors['payment.amount'],
                onChanged: (_) => _changed(),
              ),
              const SizedBox(height: Space.s3),
              Wrap(
                spacing: Space.s2,
                runSpacing: Space.s2,
                children: [
                  for (final m in kPaymentMethods)
                    ChoiceChip(
                      label: Text(l.paymentMethodText(m)),
                      selected: _payMethod == m,
                      onSelected: (_) {
                        setState(() => _payMethod = m);
                        _changed();
                      },
                    ),
                ],
              ),
              const SizedBox(height: Space.s3),
              TextFormField(
                controller: _payNote,
                maxLength: 500,
                onChanged: (_) => _changed(),
                decoration: InputDecoration(
                  labelText: l.paymentNoteOptional,
                  counterText: '',
                ),
              ),
            ],
          ),
        ),

      _Section(
        title: l.notesOptional,
        child: TextFormField(
          controller: _notes,
          minLines: 2,
          maxLines: 4,
          maxLength: 1000,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => _changed(),
          decoration: InputDecoration(
            hintText: l.saleNotesHint,
            errorText: fieldErrors['notes'],
          ),
        ),
      ),

      if (error != null) ...[
        FormErrorBanner(error!),
        const SizedBox(height: Space.s3),
      ],
    ];
  }
}

/// Titled card section of the form.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.s4),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: AppTypography.title.copyWith(color: t.textPrimary),
            ),
            const SizedBox(height: Space.s3),
            child,
          ],
        ),
      ),
    );
  }
}

/// A tappable field showing a chosen value (customer, product, date).
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.errorText,
  });

  final String label;
  final String? value;
  final IconData icon;
  final VoidCallback? onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: onTap != null,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.mdAll,
        child: InputDecorator(
          isEmpty: value == null,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            suffixIcon: onTap == null
                ? null
                : const Icon(Icons.arrow_drop_down),
            errorText: errorText,
            enabled: onTap != null,
          ),
          child: value == null
              ? null
              : Text(
                  value!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(color: t.textPrimary),
                ),
        ),
      ),
    );
  }
}

/// Row in a picker sheet.
class _PickTile extends StatelessWidget {
  const _PickTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: Space.s4,
        vertical: Space.s3,
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: Space.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.title.copyWith(color: t.textPrimary),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(color: t.textSecondary),
                ),
              ],
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: AppTypography.caption.copyWith(color: t.error),
            ),
        ],
      ),
    );
  }
}

/// One item: product, quantity, price, cost and the line total.
class _ItemCard extends StatelessWidget {
  const _ItemCard({
    super.key,
    required this.index,
    required this.row,
    required this.errors,
    required this.showProductError,
    required this.validators,
    required this.canRemove,
    required this.onPickProduct,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final _ItemRow row;
  final Map<String, String> errors;
  final bool showProductError;
  final Validators validators;
  final bool canRemove;
  final VoidCallback onPickProduct;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    final v = validators;
    final unit = unitText(l, row.unit, row.unitLabel);
    String? err(String field) => errors['items.$index.$field'];

    return Container(
      padding: const EdgeInsets.all(Space.s3),
      decoration: BoxDecoration(
        color: t.surfaceVariant,
        borderRadius: Radii.mdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _PickerField(
                  label: l.selectProduct,
                  value: row.productName,
                  icon: Icons.view_module_outlined,
                  errorText:
                      err('product_id') ??
                      (showProductError && row.productId == null
                          ? l.selectProductError
                          : null),
                  onTap: onPickProduct,
                ),
              ),
              if (canRemove)
                IconButton(
                  tooltip: l.removeItem,
                  onPressed: onRemove,
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
          const SizedBox(height: Space.s3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: row.quantity,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d{0,9}(\.\d{0,2})?'),
                    ),
                  ],
                  validator: v.quantity,
                  onChanged: (_) => onChanged(),
                  decoration: InputDecoration(
                    labelText: l.quantity,
                    suffixText: row.productId == null ? null : unit,
                    errorText: err('quantity'),
                    errorMaxLines: 2,
                  ),
                ),
              ),
              const SizedBox(width: Space.s3),
              Expanded(
                child: MoneyField(
                  controller: row.price,
                  label: l.unitPriceLabel,
                  validator: v.money,
                  errorText: err('unit_price'),
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.s3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: MoneyField(
                  controller: row.cost,
                  label: l.unitCostLabel,
                  validator: v.money,
                  errorText: err('unit_cost'),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: Space.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      l.lineTotal,
                      style: AppTypography.caption.copyWith(
                        color: t.textTertiary,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        Fmt.money(row.lineTotal.toString(), decimals: true),
                        style: AppTypography.title.copyWith(
                          color: t.textPrimary,
                          fontFeatures: AppTypography.tabular,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Sticky bar: Total · Profit · Due (live) and Save.
class _SummaryBar extends StatelessWidget {
  const _SummaryBar({
    required this.total,
    required this.profit,
    required this.due,
    required this.busy,
    required this.saveLabel,
    required this.onSave,
  });

  final Decimal total;
  final Decimal profit;
  final Decimal due;
  final bool busy;
  final String saveLabel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.tokens;
    String money(Decimal d) => Fmt.money(d.toString());

    Widget figure(String label, Decimal value, Color color) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(color: t.textSecondary),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              money(value),
              style: AppTypography.title.copyWith(
                color: color,
                fontFeatures: AppTypography.tabular,
              ),
            ),
          ),
        ],
      ),
    );

    return Material(
      color: t.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.s4,
            Space.s3,
            Space.s4,
            Space.s3,
          ),
          // heightFactor 1: only as tall as the bar, not the whole screen.
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Row(
                children: [
                  figure(l.total, total, t.textPrimary),
                  figure(
                    l.profit,
                    profit,
                    profit < Decimal.zero ? t.error : t.success,
                  ),
                  figure(
                    l.due,
                    due,
                    due > Decimal.zero ? t.error : t.textTertiary,
                  ),
                  const SizedBox(width: Space.s2),
                  BusyButton(label: saveLabel, busy: busy, onPressed: onSave),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
