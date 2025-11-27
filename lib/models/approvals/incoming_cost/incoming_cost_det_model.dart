class IncomingCostDetail {
  num? trnsSerial;
  num? trnsTypeCode;
  String? itemCode;
  String? itemName;
  String? unitName;
  num? incomeQuantity;
  num? itemConfgId;
  num? price;
  num? totalCurr;
  num? vnPrice;
  num? totalLocal;

  IncomingCostDetail({
    this.trnsSerial,
    this.trnsTypeCode,
    this.itemCode,
    this.itemName,
    this.unitName,
    this.incomeQuantity,
    this.itemConfgId,
    this.price,
    this.totalCurr,
    this.vnPrice,
    this.totalLocal,
  });

  factory IncomingCostDetail.fromJson(Map<String, dynamic> json) {
    return IncomingCostDetail(
      trnsSerial: json['trns_serial'],
      trnsTypeCode: json['trns_type_code'],
      itemCode: json['item_code'],
      itemName: json['item_name'],
      unitName: json['unit_name'],
      incomeQuantity: json['income_quantity'],
      itemConfgId: json['item_confg_id'],
      price: json['price'],
      totalCurr: json['total_curr'],
      vnPrice: json['vn_price'],
      totalLocal: json['total_local'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['trns_serial'] = this.trnsSerial;
    data['trns_type_code'] = this.trnsTypeCode;
    data['item_code'] = this.itemCode;
    data['item_name'] = this.itemName;
    data['unit_name'] = this.unitName;
    data['income_quantity'] = this.incomeQuantity;
    data['item_confg_id'] = this.itemConfgId;
    data['price'] = this.price;
    data['total_curr'] = this.totalCurr;
    data['vn_price'] = this.vnPrice;
    data['total_local'] = this.totalLocal;
    return data;
  }
}
