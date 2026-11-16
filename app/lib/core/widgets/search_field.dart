import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

/// The search box used on every list (03-AppFlow §13): a search icon, the
/// hint, and an ✕ that shows while there is text. ✕ clears the text and
/// calls [onChanged] with "" so the list shows everything again.
class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(SearchField old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  /// Shows / hides the ✕ (also when the text is cleared from outside).
  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;
    return TextField(
      controller: widget.controller,
      autofocus: widget.autofocus,
      onChanged: widget.onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: hasText
            ? IconButton(
                tooltip: context.l10n.clear,
                icon: const Icon(Icons.close),
                onPressed: () {
                  widget.controller.clear();
                  widget.onChanged('');
                },
              )
            : null,
      ),
    );
  }
}
