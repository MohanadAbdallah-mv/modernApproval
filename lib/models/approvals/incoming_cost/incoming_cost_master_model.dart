import '../../../utils/package_utility.dart';

class IncomingCostMaster {
  num? trnsSerial;
  num? trnsTypeCode;
  DateTime? trnsDate;
  String? orderTrns;
  String? purchaseTrns;
  num? storeCode;
  String? storeName;
  String? docNo;
  String? descA;
  String? descE;
  String? insertUser;
  String? updateUser;
  DateTime? insertDate;
  String? auth1Name;
  DateTime? auth1Date;
  String? auth2Name;
  DateTime? auth2Date;

  IncomingCostMaster({
    this.trnsSerial,
    this.trnsTypeCode,
    this.trnsDate,
    this.orderTrns,
    this.purchaseTrns,
    this.storeCode,
    this.storeName,
    this.docNo,
    this.descA,
    this.descE,
    this.insertUser,
    this.updateUser,
    this.insertDate,
    this.auth1Name,
    this.auth1Date,
    this.auth2Name,
    this.auth2Date,
  });

  factory IncomingCostMaster.fromJson(Map<String, dynamic> json) {
    return IncomingCostMaster(
      trnsSerial: json['trns_serial'],
      trnsTypeCode: json['trns_type_code'],
      trnsDate:
          json['trns_date'] != null ? DateTime.parse(json['trns_date']) : null,
      orderTrns: json['order_trns'],
      purchaseTrns: json['purchase_trns'],
      storeCode: json['store_code'],
      storeName: json['store_name'],
      docNo: json['doc_no'],
      descA: json['desc_a'],
      descE: json['desc_e'],
      insertUser: json['insert_user'],
      updateUser: json['update_user'],
      insertDate:
          json['insert_date'] != null
              ? DateTime.parse(json['insert_date'])
              : null,
      auth1Name: json['auth1_name'],
      auth1Date:
          json['auth1_date'] != null
              ? DateTime.parse(json['auth1_date'])
              : null,
      auth2Name: json['auth2_name'],
      auth2Date:
          json['auth2_date'] != null
              ? DateTime.parse(json['auth2_date'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['trns_serial'] = this.trnsSerial;
    data['trns_type_code'] = this.trnsTypeCode;
    data['trns_date'] = this.trnsDate;
    data['order_trns'] = this.orderTrns;
    data['purchase_trns'] = this.purchaseTrns;
    data['store_code'] = this.storeCode;
    data['store_name'] = this.storeName;
    data['doc_no'] = this.docNo;
    data['desc_a'] = this.descA;
    data['desc_e'] = this.descE;
    data['insert_user'] = this.insertUser;
    data['update_user'] = this.updateUser;
    data['insert_date'] = this.insertDate;
    data['auth1_name'] = this.auth1Name;
    data['auth1_date'] = this.auth1Date;
    data['auth2_name'] = this.auth2Name;
    data['auth2_date'] = this.auth2Date;
    return data;
  }

  String get formattedTrnsDate {
    return formatDate(trnsDate);
  }

  String get formattedInsertDate {
    return formatDate(insertDate);
  }

  String get formattedAuth1Date {
    return formatDate(auth1Date);
  }

  String get formattedAuth2Date {
    return formatDate(auth2Date);
  }
}
