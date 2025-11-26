import '../../../utils/package_utility.dart';

class ExitPermission {
  num? empCode;
  DateTime? exitDate;
  num? dateSerial;
  String? empName;
  String? empNameE;
  num? compEmpCode;
  num? exitType;
  DateTime? enterDate;
  String? reasonAr;
  String? exitTime;
  String? enterTime;
  num? fileSerial;
  num? prevSer;
  String? usersCode;
  String? authPk1;
  String? authPk2;
  String? authPk3;
  dynamic trnsFlag;
  dynamic trnsStatus;
  DateTime? trnsDateAuth;
  num? lastLevel;

  ExitPermission({
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

  factory ExitPermission.fromJson(Map<String, dynamic> json) {
    return ExitPermission(
      empCode: json['emp_code'],
      exitDate:
          json['exit_date'] != null ? DateTime.parse(json['exit_date']) : null,
      dateSerial: json['date_serial'],
      empName: json['emp_name'],
      empNameE: json['emp_name_e'],
      compEmpCode: json['comp_emp_code'],
      exitType: json['exit_type'],
      enterDate:
          json['enter_date'] != null
              ? DateTime.parse(json['enter_date'])
              : null,
      reasonAr: json['reason_ar'],
      exitTime: json['exit_time'],
      enterTime: json['enter_time'],
      fileSerial: json['file_serial'],
      prevSer: json['prev_ser'],
      usersCode: json['users_code'],
      authPk1: json['auth_pk1'],
      authPk2: json['auth_pk2'],
      authPk3: json['auth_pk3'],
      trnsFlag: json['trns_flag'],
      trnsStatus: json['trns_status'],
      trnsDateAuth:
          json['trns_date_auth'] != null
              ? DateTime.parse(json['trns_date_auth'])
              : null,
      lastLevel: json['last_level'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['emp_code'] = this.empCode;
    data['exit_date'] = this.exitDate;
    data['date_serial'] = this.dateSerial;
    data['emp_name'] = this.empName;
    data['emp_name_e'] = this.empNameE;
    data['comp_emp_code'] = this.compEmpCode;
    data['exit_type'] = this.exitType;
    data['enter_date'] = this.enterDate;
    data['reason_ar'] = this.reasonAr;
    data['exit_time'] = this.exitTime;
    data['enter_time'] = this.enterTime;
    data['file_serial'] = this.fileSerial;
    data['prev_ser'] = this.prevSer;
    data['users_code'] = this.usersCode;
    data['auth_pk1'] = this.authPk1;
    data['auth_pk2'] = this.authPk2;
    data['auth_pk3'] = this.authPk3;
    data['trns_flag'] = this.trnsFlag;
    data['trns_status'] = this.trnsStatus;
    data['trns_date_auth'] = this.trnsDateAuth;
    data['last_level'] = this.lastLevel;
    return data;
  }

  String get formattedTrnsDateAuth {
    return formatDate(trnsDateAuth);
  }

  String get formattedEnterDate {
    return formatDate(enterDate);
  }

  String get formattedExitDate {
    return formatDate(exitDate);
  }
}
