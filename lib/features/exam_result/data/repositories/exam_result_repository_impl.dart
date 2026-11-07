import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../domain/entities/exam_result_row.dart';
import '../../domain/entities/subject_performance_slice.dart';
import '../../domain/repositories/exam_result_repository.dart';

class ExamResultRepositoryImpl implements ExamResultRepository {
  static String get _api => dotenv.env['API_BASE_URL']!;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // --------------------------------------------------
  // STEP 1: API HEADERS
  // --------------------------------------------------

  Future<Map<String, String>> _headers() async {
    final token = await _storage.read(key: 'access_token');

    if (token == null || token.isEmpty) {
      throw Exception('Missing login information. Please log in again.');
    }

    return {'Authorization': 'Bearer $token', 'Accept': 'application/json'};
  }

  // --------------------------------------------------
  // STEP 2: COMMON API HELPERS
  // --------------------------------------------------

  Future<dynamic> _getJson(Uri uri, String requestName) async {
    print('\n========== $requestName ==========');
    print('REQUEST URL: $uri');

    final response = await http
        .get(uri, headers: await _headers())
        .timeout(const Duration(seconds: 15));

    print('STATUS: ${response.statusCode}');

    if (response.statusCode != 200) {
      print('ERROR BODY: ${response.body}');
      throw Exception('$requestName failed with status ${response.statusCode}');
    }

    try {
      return jsonDecode(response.body);
    } on FormatException {
      throw Exception('$requestName returned invalid JSON.');
    }
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return {};
  }

  List<Map<String, dynamic>> _extractList(
    dynamic body, [
    List<String> keys = const [],
  ]) {
    if (body is List) {
      return body
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (body is! Map) {
      return [];
    }

    for (final key in keys) {
      if (body[key] is List) {
        return (body[key] as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }

    if (body['data'] is List) {
      return (body['data'] as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return [];
  }

  String? _stringValue(dynamic value) {
    if (value == null) return null;

    final result = value.toString().trim();

    if (result.isEmpty || result.toLowerCase() == 'null') {
      return null;
    }

    return result;
  }

  // --------------------------------------------------
  // STEP 3: FETCH + AGGREGATE THE STUDENT'S MARKS
  // --------------------------------------------------
  //
  // Uses /student-marks/{branch_uid}/total_marks_new/ WITHOUT an
  // assessment_group filter, which makes the backend return every matching
  // assessment group (Mid Exam, Final Exam, ...) for this class/section/
  // academic year in one call — the same thing the web's "All Assessment
  // Groups" view shows. We then sum each subject's marks across every group
  // it appears in, and keep every individual assessment ("Class Test", "CQ
  // (Final Exam)", "Mid Exam", ...) for the per-subject breakdown ("View").

  Future<List<_SubjectAggregate>> _fetchAggregatedSubjects() async {
    final branchUid = await _storage.read(key: 'branch_uid');
    final userUid = await _storage.read(key: 'user_uid');

    if (branchUid == null ||
        branchUid.isEmpty ||
        userUid == null ||
        userUid.isEmpty) {
      throw Exception('Missing branch or user information. Please log in.');
    }

    // A. Fetch student profile.

    final profileUri = Uri.parse(
      '$_api/protected/student_registrations/'
      'branch/$branchUid/student-profile/$userUid/',
    );

    final profileBody = _asMap(await _getJson(profileUri, 'STUDENT PROFILE'));

    final profile = _asMap(profileBody['data']).isNotEmpty
        ? _asMap(profileBody['data'])
        : profileBody;

    final classUid = _stringValue(profile['class_uid']);
    final sectionUid = _stringValue(profile['section_uid']);

    final studentUid = _stringValue(
      profile['student_profile_uid'] ??
          profile['student_uid'] ??
          profile['uid'],
    );

    final profileYearUid = _stringValue(profile['academic_year_uid']);

    print('STUDENT CLASS: $classUid');
    print('STUDENT SECTION: $sectionUid');
    print('STUDENT PROFILE UID: $studentUid');
    print('STUDENT ACADEMIC YEAR: $profileYearUid');

    if (classUid == null || sectionUid == null || studentUid == null) {
      throw Exception(
        'Student profile is missing its class, section, or student UID.',
      );
    }

    // B. Fetch academic years, so we pass a real academic_year_uid along
    // (the new endpoint requires one when assessment_group is omitted).

    final yearsUri = Uri.parse('$_api/protected/academic_years/$branchUid/');

    final yearsBody = await _getJson(yearsUri, 'ACADEMIC YEARS');

    final years = _extractList(yearsBody, [
      'academic_years',
      'academicYears',
      'years',
    ]);

    if (years.isEmpty) {
      print('No academic years returned by the API.');
      return [];
    }

    Map<String, dynamic>? matchingYear;

    for (final year in years) {
      final uid = _stringValue(year['uid'] ?? year['academic_year_uid']);

      if (uid == profileYearUid) {
        matchingYear = year;
        break;
      }
    }

    if (matchingYear == null) {
      throw Exception(
        'Could not find the student academic year: $profileYearUid',
      );
    }

    final academicYearUid = _stringValue(
      matchingYear['uid'] ?? matchingYear['academic_year_uid'],
    );

    if (academicYearUid == null) {
      throw Exception('Academic year UID is missing.');
    }

    print('SELECTED ACADEMIC YEAR: $academicYearUid');

    // C. Fetch marks for ALL assessment groups in one call.

    final marksUri =
        Uri.parse(
          '$_api/protected/student-marks/$branchUid/total_marks_new/',
        ).replace(
          queryParameters: {
            'class_uid': classUid,
            'section_uid': sectionUid,
            'academic_year_uid': academicYearUid,
            'student_uid': studentUid,
          },
        );

    final marksBody = _asMap(
      await _getJson(marksUri, 'STUDENT MARKS (ALL ASSESSMENT GROUPS)'),
    );
    print('MARKS RESPONSE: ${jsonEncode(marksBody)}');

    final pagination = _asMap(marksBody['pagination']);
    final dataList = pagination['data'];

    if (dataList is! List || dataList.isEmpty) {
      print('No assessment-group data returned for this student.');
      return [];
    }

    // We filtered by student_uid, so there should be exactly one entry.
    final studentEntry = _asMap(dataList.first);
    final groupsRaw = studentEntry['assessment_groups'];
    final groups = groupsRaw is List
        ? groupsRaw
              .whereType<Map>()
              .map((g) => Map<String, dynamic>.from(g))
              .toList()
        : <Map<String, dynamic>>[];

    print('ASSESSMENT GROUPS IN RESPONSE: ${groups.length}');

    // D. Sum every subject's marks across every group it appears in, and
    // keep every individual assessment component for the breakdown view.
    final bySubject = <String, _SubjectAggregate>{};

    for (final group in groups) {
      double gObt = 0, gFull = 0;
      if (group['marks'] is Map) {
        (group['marks'] as Map).forEach((k, v) {
          if (v is Map) {
            gObt += _toDouble(v['total_marks_obtained']);
            gFull += _toDouble(v['full_mark']);
          }
        });
      }
      print(
        'GROUP ${group['assessment_group_uid']} | ${group['assessment_group_name']} | '
        'obtained=$gObt full=$gFull',
      );
      final marksRaw = group['marks'];
      if (marksRaw is! Map) continue;

      final marks = Map<String, dynamic>.from(marksRaw);

      marks.forEach((subjectKey, rawInfo) {
        if (rawInfo is! Map) return;

        final info = Map<String, dynamic>.from(rawInfo);

        final subjectUid = _stringValue(info['subject_uid']);
        final subjectName = (info['subject_name'] ?? subjectKey).toString();
        final key = subjectUid ?? subjectName;

        final aggregate = bySubject.putIfAbsent(
          key,
          () => _SubjectAggregate(subjectName),
        );

        aggregate.obtainedMarks += _toDouble(info['total_marks_obtained']);
        aggregate.fullMarks += _toDouble(info['full_mark']);

        final weighted = info['total_marks_weighted'];
        if (weighted != null) {
          aggregate.weightedSum += _toDouble(weighted);
          aggregate.weightedCount++;
        }

        final assessmentsRaw = info['assessments'];
        if (assessmentsRaw is List) {
          for (final rawComponent in assessmentsRaw) {
            if (rawComponent is! Map) continue;
            final component = Map<String, dynamic>.from(rawComponent);

            aggregate.assessments.add(
              AssessmentComponentDetail(
                title: (component['title'] ?? '').toString(),
                marksObtained: _toDouble(component['marks_obtained']),
                fullMark: _toDouble(component['full_mark']),
                weightedMarks: _toDouble(component['weighted_marks']),
                weightage: component['weightage'] == null
                    ? null
                    : _toDouble(component['weightage']),
                isAbsent: component['is_absent'] == true,
              ),
            );
          }
        }
      });
    }

    print('SUBJECTS AGGREGATED: ${bySubject.length}');

    return bySubject.values.toList();
  }

  // --------------------------------------------------
  // STEP 4: EXAM RESULTS
  // --------------------------------------------------

  @override
  Future<List<ExamResultRow>> getExamResults() async {
    final subjects = await _fetchAggregatedSubjects();

    final rows = subjects.map((aggregate) {
      final weightedAvg = aggregate.weightedCount > 0
          ? aggregate.weightedSum / aggregate.weightedCount
          : 0.0;

      final percentage = aggregate.fullMarks > 0
          ? (aggregate.obtainedMarks / aggregate.fullMarks) * 100
          : weightedAvg;

      return _buildRow(
        aggregate.subjectName,
        aggregate.obtainedMarks,
        aggregate.fullMarks,
        weightedAvg,
        percentage,
        aggregate.assessments,
      );
    }).toList();

    print('FINAL EXAM RESULT ROW COUNT: ${rows.length}');

    return rows;
  }

  // --------------------------------------------------
  // STEP 5: SUBJECT PERFORMANCE
  // --------------------------------------------------

  @override
  Future<List<SubjectPerformanceSlice>> getSubjectPerformance() async {
    final subjects = await _fetchAggregatedSubjects();

    final slices = subjects.map((aggregate) {
      // Same formula as getExamResults() and the web: obtained ÷ full mark,
      // not a weighted average — the two screens should always agree.
      final weightedAvg = aggregate.weightedCount > 0
          ? aggregate.weightedSum / aggregate.weightedCount
          : 0.0;
      final value = aggregate.fullMarks > 0
          ? (aggregate.obtainedMarks / aggregate.fullMarks) * 100
          : weightedAvg;

      return SubjectPerformanceSlice(
        subjectName: aggregate.subjectName,
        value: double.parse(value.toStringAsFixed(2)),
      );
    }).toList();

    print('FINAL SUBJECT PERFORMANCE: $slices');

    return slices;
  }

  // --------------------------------------------------
  // STEP 6: GRADE CALCULATION
  // --------------------------------------------------

  ExamResultRow _buildRow(
    String subject,
    double obtained,
    double fullMark,
    double weighted,
    double percentage,
    List<AssessmentComponentDetail> assessments,
  ) {
    late String grade;
    late String performance;
    late bool passed;

    if (percentage >= 80) {
      grade = 'A+';
      performance = 'Excellent';
      passed = true;
    } else if (percentage >= 70) {
      grade = 'A';
      performance = 'Very Good';
      passed = true;
    } else if (percentage >= 60) {
      grade = 'A-';
      performance = 'Good';
      passed = true;
    } else if (percentage >= 50) {
      grade = 'B';
      performance = 'Satisfactory';
      passed = true;
    } else if (percentage >= 40) {
      grade = 'C';
      performance = 'Average';
      passed = true;
    } else if (percentage >= 33) {
      grade = 'D';
      performance = 'Pass';
      passed = true;
    } else {
      grade = 'F';
      performance = 'Fail';
      passed = false;
    }

    return ExamResultRow(
      subjectName: subject,
      marksObtained: obtained,
      fullMark: fullMark,
      weightedMarks: weighted,
      grade: grade,
      performance: performance,
      statusLabel: passed ? 'Passed' : 'Failed',
      isPassed: passed,
      assessments: assessments,
    );
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }
}

class _SubjectAggregate {
  _SubjectAggregate(this.subjectName);

  final String subjectName;

  double obtainedMarks = 0;
  double fullMarks = 0;
  double weightedSum = 0;
  int weightedCount = 0;
  final List<AssessmentComponentDetail> assessments = [];
}
