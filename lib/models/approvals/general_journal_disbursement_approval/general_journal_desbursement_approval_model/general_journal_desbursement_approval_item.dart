import 'package:modernapproval/utils/package_utility.dart';

class GeneralJournalDesbursementApprovalItem {
  int? trnsTypeCode;
  int? reqSerial;
  DateTime? reqDate;
  int? totalValue;
  int? insertUser;
  String? insertDate;
  String? descA;
  String? descE;
  int? fileSerial;
  int? prevSer;
  dynamic usersCode;
  int? roleCode;
  String? authPk1;
  String? authPk2;
  int? lastLevel;
  dynamic trnsFlag;
  dynamic trnsStatus;

  GeneralJournalDesbursementApprovalItem({
    this.trnsTypeCode,
    this.reqSerial,
    this.reqDate,
    this.totalValue,
    this.insertUser,
    this.insertDate,
    this.descA,
    this.descE,
    this.fileSerial,
    this.prevSer,
    this.usersCode,
    this.roleCode,
    this.authPk1,
    this.authPk2,
    this.lastLevel,
    this.trnsFlag,
    this.trnsStatus,
  });

  factory GeneralJournalDesbursementApprovalItem.fromJson(
    Map<String, dynamic> json,
  ) => GeneralJournalDesbursementApprovalItem(
    trnsTypeCode: json['trns_type_code'] as int?,
    reqSerial: json['req_serial'] as int?,
    reqDate: json['req_date'] != null ? DateTime.parse(json['req_date']) : null,
    totalValue: json['total_value'] as int?,
    insertUser: json['insert_user'] as int?,
    insertDate: json['insert_date'] as String?,
    descA: json['desc_a'] as String?,
    descE: json['desc_e'] as String?,
    fileSerial: json['file_serial'] as int?,
    prevSer: json['prev_ser'] as int?,
    usersCode: json['users_code'] as dynamic,
    roleCode: json['role_code'] as int?,
    authPk1: json['auth_pk1'] as String?,
    authPk2: json['auth_pk2'] as String?,
    lastLevel: json['last_level'] as int?,
    trnsFlag: json['trns_flag'] as dynamic,
    trnsStatus: json['trns_status'] as dynamic,
  );

  Map<String, dynamic> toJson() => {
    'trns_type_code': trnsTypeCode,
    'req_serial': reqSerial,
    'req_date': reqDate,
    'total_value': totalValue,
    'insert_user': insertUser,
    'insert_date': insertDate,
    'desc_a': descA,
    'desc_e': descE,
    'file_serial': fileSerial,
    'prev_ser': prevSer,
    'users_code': usersCode,
    'role_code': roleCode,
    'auth_pk1': authPk1,
    'auth_pk2': authPk2,
    'last_level': lastLevel,
    'trns_flag': trnsFlag,
    'trns_status': trnsStatus,
  };

  String get formattedReqDate {
    return formatDate(reqDate);
  }
}
