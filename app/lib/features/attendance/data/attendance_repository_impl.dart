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
  Future<AttendanceDay> save(String date, Map<String, bool> present) async =>
      (await _api.put(
        '/attendance',
        body: {
          'date': date,
          'records': [
            for (final e in present.entries)
              {'labour_id': e.key, 'present': e.value},
          ],
        },
        parse: _day,
      )).data;
}

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
  (ref) => AttendanceRepositoryImpl(ref.watch(apiClientProvider)),
);
