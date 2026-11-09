import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../domain/attendance.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  AttendanceRepositoryImpl(this._api);

  final ApiClient _api;

  static AttendanceDay _day(Object? d) => AttendanceDay.fromJson(d as Json);

  @override
  Future<AttendanceDay> day(String date) async =>
      (await _api.get('/attendance', query: {'date': date}, parse: _day)).data;

  @override
  Future<(AttendanceDay, String)> save(
    String date,
    Map<int, String?> statuses,
  ) async {
    final res = await _api.put(
      '/attendance',
      body: {
        'date': date,
        'records': [
          for (final e in statuses.entries)
            {'labour_id': e.key, 'status': e.value},
        ],
      },
      parse: _day,
    );
    return (res.data, res.message);
  }
}

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
  (ref) => AttendanceRepositoryImpl(ref.watch(apiClientProvider)),
);
