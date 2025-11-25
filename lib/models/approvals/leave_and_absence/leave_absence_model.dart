import '../../../utils/package_utility.dart';

class LeaveAndAbsence {
  int? empCode;
  int? serialPyv;
  String? empName;
  String? empNameE;
  int? compEmpCode;
  DateTime? trnsDate;
  int? trnsType;
  String? vcncDescA;
  DateTime? startDt;
  DateTime? endDt;
  int? period;
  DateTime? returnDate;
  String? trnsAddress;
  int? fileSerial;
  int? prevSer;
  String? usersCode;
  String? authPk1;
  String? authPk2;
  String? trnsFlag;
  String? trnsStatus;
  DateTime? trnsDateAuth;
  int? lastLevel;

  LeaveAndAbsence({
    this.empCode,
    this.serialPyv,
    this.empName,
    this.empNameE,
    this.compEmpCode,
    this.trnsDate,
    this.trnsType,
    this.vcncDescA,
    this.startDt,
    this.endDt,
    this.period,
    this.returnDate,
    this.trnsAddress,
    this.fileSerial,
    this.prevSer,
    this.usersCode,
    this.authPk1,
    this.authPk2,
    this.trnsFlag,
    this.trnsStatus,
    this.trnsDateAuth,
    this.lastLevel,
  });

  factory LeaveAndAbsence.fromJson(Map<String, dynamic> json) {
    return LeaveAndAbsence(
      empCode: json['emp_code'],
      serialPyv: json['serial_pyv'],
      empName: json['emp_name'],
      empNameE: json['emp_name_e'],
      compEmpCode: json['comp_emp_code'],
      trnsDate:
          json['trns_date'] != null ? DateTime.parse(json['trns_date']) : null,
      trnsType: json['trns_type'],
      vcncDescA: json['vcnc_desc_a'],
      startDt:
          json['start_dt'] != null ? DateTime.parse(json['start_dt']) : null,
      endDt: json['end_dt'] != null ? DateTime.parse(json['end_dt']) : null,
      period: json['period'],
      returnDate:
          json['return_date'] != null
              ? DateTime.parse(json['return_date'])
              : null,
      trnsAddress: json['trns_address'],
      fileSerial: json['file_serial'],
      prevSer: json['prev_ser'],
      usersCode: json['users_code'],
      authPk1: json['auth_pk1'],
      authPk2: json['auth_pk2'],
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
    data['serial_pyv'] = this.serialPyv;
    data['emp_name'] = this.empName;
    data['emp_name_e'] = this.empNameE;
    data['comp_emp_code'] = this.compEmpCode;
    data['trns_date'] = this.trnsDate;
    data['trns_type'] = this.trnsType;
    data['vcnc_desc_a'] = this.vcncDescA;
    data['start_dt'] = this.startDt;
    data['end_dt'] = this.endDt;
    data['period'] = this.period;
    data['return_date'] = this.returnDate;
    data['trns_address'] = this.trnsAddress;
    data['file_serial'] = this.fileSerial;
    data['prev_ser'] = this.prevSer;
    data['users_code'] = this.usersCode;
    data['auth_pk1'] = this.authPk1;
    data['auth_pk2'] = this.authPk2;
    data['trns_flag'] = this.trnsFlag;
    data['trns_status'] = this.trnsStatus;
    data['trns_date_auth'] = this.trnsDateAuth;
    data['last_level'] = this.lastLevel;
    return data;
  }

  String get formattedTrnsDate {
    return formatDate(trnsDate);
  }

  String get formattedStartDate {
    return formatDate(startDt);
  }

  String get formattedEndDate {
    return formatDate(endDt);
  }

  String get formattedReturnDate {
    return formatDate(returnDate);
  }

  String get formattedTrnsAuthDate {
    return formatDate(trnsDateAuth);
  }
}
