import '../../../utils/package_utility.dart';

class IncomingCost {
  num? trnsTypeCode;
  num? trnsSerial;
  DateTime? reqDate;
  String? supplierName;
  String? descTrns;
  num? currencyCode;
  String? currencyDesc;
  num? insertUser;
  DateTime? insertDate;
  String? descA;
  String? descE;
  String? storeName;
  num? fileSerial;
  num? prevSer;
  String? usersCode;
  num? roleCode;
  String? authPk1;
  String? authPk2;
  num? lastLevel;
  dynamic trnsFlag;
  dynamic trnsStatus;

  IncomingCost({
    this.trnsTypeCode,
    this.trnsSerial,
    this.reqDate,
    this.supplierName,
    this.descTrns,
    this.currencyCode,
    this.currencyDesc,
    this.insertUser,
    this.insertDate,
    this.descA,
    this.descE,
    this.storeName,
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

  factory IncomingCost.fromJson(Map<String, dynamic> json) {
    return IncomingCost(
      trnsTypeCode: json['trns_type_code'],
      trnsSerial: json['trns_serial'],
      reqDate:
          json['req_date'] != null ? DateTime.parse(json['req_date']) : null,
      supplierName: json['supplier_name'],
      descTrns: json['desc_trns'],
      currencyCode: json['currency_code'],
      currencyDesc: json['currency_desc'],
      insertUser: json['insert_user'],
      insertDate:
          json['insert_date'] != null
              ? DateTime.parse(json['insert_date'])
              : null,
      descA: json['desc_a'],
      descE: json['desc_e'],
      storeName: json['store_name'],
      fileSerial: json['file_serial'],
      prevSer: json['prev_ser'],
      usersCode: json['users_code'],
      roleCode: json['role_code'],
      authPk1: json['auth_pk1'],
      authPk2: json['auth_pk2'],
      lastLevel: json['last_level'],
      trnsFlag: json['trns_flag'],
      trnsStatus: json['trns_status'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['trns_type_code'] = this.trnsTypeCode;
    data['trns_serial'] = this.trnsSerial;
    data['req_date'] = this.reqDate;
    data['supplier_name'] = this.supplierName;
    data['desc_trns'] = this.descTrns;
    data['currency_code'] = this.currencyCode;
    data['currency_desc'] = this.currencyDesc;
    data['insert_user'] = this.insertUser;
    data['insert_date'] = this.insertDate;
    data['desc_a'] = this.descA;
    data['desc_e'] = this.descE;
    data['store_name'] = this.storeName;
    data['file_serial'] = this.fileSerial;
    data['prev_ser'] = this.prevSer;
    data['users_code'] = this.usersCode;
    data['role_code'] = this.roleCode;
    data['auth_pk1'] = this.authPk1;
    data['auth_pk2'] = this.authPk2;
    data['last_level'] = this.lastLevel;
    data['trns_flag'] = this.trnsFlag;
    data['trns_status'] = this.trnsStatus;
    return data;
  }

  String get formattedRequestDate {
    return formatDate(reqDate);
  }

  String get formattedInsertDate {
    return formatDate(insertDate);
  }
}
