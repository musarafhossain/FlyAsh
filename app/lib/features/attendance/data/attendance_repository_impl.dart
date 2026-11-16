import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../domain/attendance.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  AttendanceRepositoryImpl(this._api);

  final ApiClient _api;

  static AttendanceDay _day(Object? d) => AttendanceDay.fromJson(d as Json);

  @override
  Future<AttendanceDay> day(
    String date, {
    int page = 1,
    String? search,
  }) async => (await _api.get(
    '/attendance',
    query: {
      'date': date,
      'page': page,
      'limit': kPageSize, // like every list
      if (search != null && search.isNotEmpty) 'search': search,
    },
    parse: _day,
  )).data;

  @override
  Future<AttendanceDay> save(
    String date,
    Map<String, bool> present, {
    Map<String, String> wages = const {},
  }) async => (await _api.put(
    '/attendance',
    body: {
      // Only the saved rows back (merged into the page shown).
      'rows': 'saved',
      'date': date,
      'records': [
        for (final e in present.entries)
          {
            'labour_id': e.key,
            'present': e.value,
            if (e.value && wages[e.key] != null) 'wage': wages[e.key],
          },
      ],
    },
    parse: _day,
  )).data;
}

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
  (ref) => AttendanceRepositoryImpl(ref.watch(apiClientProvider)),
);
