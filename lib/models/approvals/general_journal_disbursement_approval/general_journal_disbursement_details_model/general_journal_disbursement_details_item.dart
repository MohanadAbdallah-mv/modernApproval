class GeneralJournalDisbursementDetailsItem {
  int? trnsTypeCode;
  int? trnsSerial;
  String? pyTkDescA;
  dynamic pyTkDescE;
  String? costCenter1;
  dynamic projectName;
  dynamic mastBandCode;
  dynamic bandCode;
  dynamic detBandCode;
  String? costCenter2;
  int? valueCurr;

  GeneralJournalDisbursementDetailsItem({
    this.trnsTypeCode,
    this.trnsSerial,
    this.pyTkDescA,
    this.pyTkDescE,
    this.costCenter1,
    this.projectName,
    this.mastBandCode,
    this.bandCode,
    this.detBandCode,
    this.costCenter2,
    this.valueCurr,
  });

  factory GeneralJournalDisbursementDetailsItem.fromJson(
    Map<String, dynamic> json,
  ) => GeneralJournalDisbursementDetailsItem(
    trnsTypeCode: json['trns_type_code'] as int?,
    trnsSerial: json['trns_serial'] as int?,
    pyTkDescA: json['py_tk_desc_a'] as String?,
    pyTkDescE: json['py_tk_desc_e'] as dynamic,
    costCenter1: json['cost_center1'] as String?,
    projectName: json['project_name'] as dynamic,
    mastBandCode: json['mast_band_code'] as dynamic,
    bandCode: json['band_code'] as dynamic,
    detBandCode: json['det_band_code'] as dynamic,
    costCenter2: json['cost_center2'] as String?,
    valueCurr: json['value_curr'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'trns_type_code': trnsTypeCode,
    'trns_serial': trnsSerial,
    'py_tk_desc_a': pyTkDescA,
    'py_tk_desc_e': pyTkDescE,
    'cost_center1': costCenter1,
    'project_name': projectName,
    'mast_band_code': mastBandCode,
    'band_code': bandCode,
    'det_band_code': detBandCode,
    'cost_center2': costCenter2,
    'value_curr': valueCurr,
  };
}
