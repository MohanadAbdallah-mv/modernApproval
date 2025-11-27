import 'package:modernapproval/utils/package_utility.dart';

class GeneralJournalDisbursementMasterItem {
  int? trnsTypeCode;
  int? reqSerial;
  DateTime? reqDate;
  String? descA;
  dynamic descE;
  int? approved;
  String? trnsDesc;
  String? insertUser;
  String? supplierName;
  String? insertDate;
  String? currencyDesc;
  String? dueDate;
  int? totalValue;
  String? payFlag;
  int? closed;
  String? payMethd;
  int? cpBnkBoxCode;
  String? cpBnkBoxName;

  GeneralJournalDisbursementMasterItem({
    this.trnsTypeCode,
    this.reqSerial,
    this.reqDate,
    this.descA,
    this.descE,
    this.approved,
    this.trnsDesc,
    this.insertUser,
    this.supplierName,
    this.insertDate,
    this.currencyDesc,
    this.dueDate,
    this.totalValue,
    this.payFlag,
    this.closed,
    this.payMethd,
    this.cpBnkBoxCode,
    this.cpBnkBoxName,
  });

  factory GeneralJournalDisbursementMasterItem.fromJson(
    Map<String, dynamic> json,
  ) => GeneralJournalDisbursementMasterItem(
    trnsTypeCode: json['trns_type_code'] as int?,
    reqSerial: json['req_serial'] as int?,
    reqDate: json['req_date'] != null ? DateTime.parse(json['req_date']) : null,
    descA: json['desc_a'] as String?,
    descE: json['desc_e'] as dynamic,
    approved: json['approved'] as int?,
    trnsDesc: json['trns_desc'] as String?,
    insertUser: json['insert_user'] as String?,
    supplierName: json['supplier_name'] as String?,
    insertDate: json['insert_date'] as String?,
    currencyDesc: json['currency_desc'] as String?,
    dueDate: json['due_date'] as String?,
    totalValue: json['total_value'] as int?,
    payFlag: json['pay_flag'] as String?,
    closed: json['closed'] as int?,
    payMethd: json['pay_methd'] as String?,
    cpBnkBoxCode: json['cp_bnk_box_code'] as int?,
    cpBnkBoxName: json['cp_bnk_box_name'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'trns_type_code': trnsTypeCode,
    'req_serial': reqSerial,
    'req_date': reqDate,
    'desc_a': descA,
    'desc_e': descE,
    'approved': approved,
    'trns_desc': trnsDesc,
    'insert_user': insertUser,
    'supplier_name': supplierName,
    'insert_date': insertDate,
    'currency_desc': currencyDesc,
    'due_date': dueDate,
    'total_value': totalValue,
    'pay_flag': payFlag,
    'closed': closed,
    'pay_methd': payMethd,
    'cp_bnk_box_code': cpBnkBoxCode,
    'cp_bnk_box_name': cpBnkBoxName,
  };

  String get formattedReqDate {
    return formatDate(reqDate);
  }
}
