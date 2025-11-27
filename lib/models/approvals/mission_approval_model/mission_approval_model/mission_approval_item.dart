import 'package:modernapproval/utils/package_utility.dart';

class MissionApprovalItem {
  int? empCode;
  DateTime? exitDate;
  int? dateSerial;
  String? empName;
  String? empNameE;
  int? compEmpCode;
  int? exitType;
  DateTime? enterDate;
  String? reasonAr;
  String? exitTime;
  String? enterTime;
  int? fileSerial;
  int? prevSer;
  dynamic usersCode;
  String? authPk1;
  String? authPk2;
  String? authPk3;
  dynamic trnsFlag;
  dynamic trnsStatus;
  dynamic trnsDateAuth;
  int? lastLevel;

  MissionApprovalItem({
    this.empCode,
    this.exitDate,
    this.dateSerial,
    this.empName,
    this.empNameE,
    this.compEmpCode,
    this.exitType,
    this.enterDate,
    this.reasonAr,
    this.exitTime,
    this.enterTime,
    this.fileSerial,
    this.prevSer,
    this.usersCode,
    this.authPk1,
    this.authPk2,
    this.authPk3,
    this.trnsFlag,
    this.trnsStatus,
    this.trnsDateAuth,
    this.lastLevel,
  });

  factory MissionApprovalItem.fromJson(Map<String, dynamic> json) =>
      MissionApprovalItem(
        empCode: json['emp_code'] as int?,
        exitDate: parseApiDate(json['exit_date'] as String?),
        dateSerial: json['date_serial'] as int?,
        empName: json['emp_name'] as String?,
        empNameE: json['emp_name_e'] as String?,
        compEmpCode: json['comp_emp_code'] as int?,
        exitType: json['exit_type'] as int?,
        enterDate: parseApiDate(json['enter_date'] as String?),
        reasonAr: json['reason_ar'] as String?,
        exitTime: json['exit_time'] as String?,
        enterTime: json['enter_time'] as String?,
        fileSerial: json['file_serial'] as int?,
        prevSer: json['prev_ser'] as int?,
        usersCode: json['users_code'] as dynamic,
        authPk1: json['auth_pk1'] as String?,
        authPk2: json['auth_pk2'] as String?,
        authPk3: json['auth_pk3'] as String?,
        trnsFlag: json['trns_flag'] as dynamic,
        trnsStatus: json['trns_status'] as dynamic,
        trnsDateAuth: json['trns_date_auth'] as dynamic,
        lastLevel: json['last_level'] as int?,
      );

  Map<String, dynamic> toJson() => {
    'emp_code': empCode,
    'exit_date': exitDate,
    'date_serial': dateSerial,
    'emp_name': empName,
    'emp_name_e': empNameE,
    'comp_emp_code': compEmpCode,
    'exit_type': exitType,
    'enter_date': enterDate,
    'reason_ar': reasonAr,
    'exit_time': exitTime,
    'enter_time': enterTime,
    'file_serial': fileSerial,
    'prev_ser': prevSer,
    'users_code': usersCode,
    'auth_pk1': authPk1,
    'auth_pk2': authPk2,
    'auth_pk3': authPk3,
    'trns_flag': trnsFlag,
    'trns_status': trnsStatus,
    'trns_date_auth': trnsDateAuth,
    'last_level': lastLevel,
  };

  String get formattedExitDate {
    return formatDate(exitDate);
  }

  String get formattedEnterDate {
    return formatDate(enterDate);
  }

  String get formattedTrnsAuthDate {
    return formatDate(trnsDateAuth);
  }
}
