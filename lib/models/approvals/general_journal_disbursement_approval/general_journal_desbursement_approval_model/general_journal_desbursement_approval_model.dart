import 'package:modernapproval/models/approvals/general_journal_disbursement_approval/general_journal_desbursement_approval_model/general_journal_desbursement_approval_item.dart';

import 'link.dart';

class GeneralJournalDesbursementApprovalModel {
  List<GeneralJournalDesbursementApprovalItem>? items;
  bool? hasMore;
  int? limit;
  int? offset;
  int? count;
  List<Link>? links;

  GeneralJournalDesbursementApprovalModel({
    this.items,
    this.hasMore,
    this.limit,
    this.offset,
    this.count,
    this.links,
  });

  factory GeneralJournalDesbursementApprovalModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return GeneralJournalDesbursementApprovalModel(
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (e) => GeneralJournalDesbursementApprovalItem.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
      hasMore: json['hasMore'] as bool?,
      limit: json['limit'] as int?,
      offset: json['offset'] as int?,
      count: json['count'] as int?,
      links:
          (json['links'] as List<dynamic>?)
              ?.map((e) => Link.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'items': items?.map((e) => e.toJson()).toList(),
    'hasMore': hasMore,
    'limit': limit,
    'offset': offset,
    'count': count,
    'links': links?.map((e) => e.toJson()).toList(),
  };
}
