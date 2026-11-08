import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/session.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/status_pill.dart';

/// Calls GET /health. Temporary connection check until the real splash (F6).
final healthProvider = FutureProvider.autoDispose<Json>((ref) async {
  final res = await ref
      .read(apiClientProvider)
      .get('/health', parse: (d) => d as Json);
  return res.data;
});

/// Shows whether the app can reach the API, and the factory date.
class ApiStatusCard extends ConsumerWidget {
  const ApiStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final health = ref.watch(healthProvider);
    final factoryDate = ref.watch(businessDateProvider);
    final l = context.l10n;

    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(Space.s4),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: Radii.mdAll,
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.serverTitle,
                  style: AppTypography.title.copyWith(color: t.textPrimary),
                ),
                Text(
                  health.when(
                    data: (_) => l.serverConnected(Fmt.date(factoryDate)),
                    loading: () => l.serverChecking,
                    error: (e, _) => failureText(context, e),
                  ),
                  style: AppTypography.caption.copyWith(color: t.textSecondary),
                ),
              ],
            ),
          ),
          health.when(
            data: (_) =>
                StatusPill(l.serverOnline, tone: StatusTone.success, dot: true),
            loading: () => const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, _) => TextButton(
              onPressed: () => ref.invalidate(healthProvider),
              child: Text(l.retry),
            ),
          ),
        ],
      ),
    );
  }
}
