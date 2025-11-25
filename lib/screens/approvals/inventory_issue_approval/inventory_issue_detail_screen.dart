import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modernapproval/models/approval_status_response_model.dart';
import 'package:modernapproval/models/approvals/inventory_issue/inventory_issue_details_model/inventory_issue_details_item.dart';
import 'package:modernapproval/models/approvals/inventory_issue/inventory_issue_master_model/inventory_issue_master_item.dart';
import 'package:modernapproval/models/approvals/inventory_issue/inventory_issue_model/inventory_issue.dart';
import 'package:modernapproval/models/approvals/production_outbound/production_outbound_det_model.dart';
import 'package:modernapproval/models/approvals/production_outbound/production_outbound_mast_model.dart';
import 'package:modernapproval/models/approvals/production_outbound/production_outbound_model.dart';
import 'package:modernapproval/models/user_model.dart';
import 'package:modernapproval/services/api_service.dart';
import 'package:modernapproval/widgets/error_display.dart';
import '../../../app_localizations.dart';
import '../../../main.dart';

// --- مكتبات الطباعة ---
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/rendering.dart' show TextDirection;

// ---------------------

class InventoryIssueDetailScreen extends StatefulWidget {
  final UserModel user;
  final InventoryIssue request;

  const InventoryIssueDetailScreen({
    super.key,
    required this.user,
    required this.request,
  });

  @override
  State<InventoryIssueDetailScreen> createState() =>
      _InventoryIssueDetailScreenState();
}

class _InventoryIssueDetailScreenState
    extends State<InventoryIssueDetailScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _detailsFuture;

  InventoryIssueMasterItem? _masterData;
  List<InventoryIssueDetailsItem>? _detailData;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _loadAllDetails();
  }

  Future<Map<String, dynamic>> _loadAllDetails() async {
    try {
      final results = await Future.wait([
        _apiService.getInventoryIssueMaster(
          trnsTypeCode: widget.request.trnsTypeCode ?? 0,
          trnsSerial: widget.request.trnsSerial ?? 0,
        ),
        _apiService.getInventoryIssueDetail(
          trnsTypeCode: widget.request.trnsTypeCode ?? 0,
          trnsSerial: widget.request.trnsSerial ?? 0,
        ),
      ]);

      setState(() {
        _masterData = results[0] as InventoryIssueMasterItem;
        _detailData = results[1] as List<InventoryIssueDetailsItem>;
      });

      return {'master': _masterData, 'detail': _detailData};
    } catch (e) {
      rethrow;
    }
  }

  void _retryLoad() {
    setState(() {
      _detailsFuture = _loadAllDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(l.translate('requestDetails')),
        backgroundColor: const Color(0xFF6C63FF),
        actions: [
          IconButton(
            icon: const Icon(Icons.language, color: Colors.white),
            onPressed: () {
              final myAppState = MyApp.of(context);
              if (myAppState != null) {
                myAppState.changeLanguage(
                  isArabic ? const Locale('en', '') : const Locale('ar', ''),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.print_outlined, color: Colors.white),
            onPressed:
                _masterData != null && _detailData != null
                    ? () async {
                      try {
                        await _printDocument(l, isArabic);
                      } catch (e) {
                        print("--- ❌ PDF PRINTING FAILED ---");
                        print(e.toString());
                        if (mounted) {
                          String errorMessage =
                              "حدث خطأ أثناء تجهيز ملف الطباعة.";
                          if (e.toString().toLowerCase().contains(
                            "unable to load asset",
                          )) {
                            errorMessage =
                                "خطأ: ملفات الخطوط أو الصور غير موجودة.";
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(errorMessage),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                    : null,
          ),
        ],
      ),
      body: Stack(
        children: [
          FutureBuilder<Map<String, dynamic>>(
            future: _detailsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return ErrorDisplay(
                  errorMessageKey:
                      snapshot.error.toString().contains('noInternet')
                          ? 'noInternet'
                          : 'serverError',
                  onRetry: _retryLoad,
                );
              }

              if (!snapshot.hasData) {
                return ErrorDisplay(
                  errorMessageKey: 'noData',
                  onRetry: _retryLoad,
                );
              }

              final masterData =
                  snapshot.data!['master'] as InventoryIssueMasterItem;
              final detailData =
                  snapshot.data!['detail'] as List<InventoryIssueDetailsItem>;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCompactMasterSection(l, masterData, isArabic),
                    const SizedBox(height: 20),
                    _buildModernDetailTable(l, detailData, isArabic),
                  ],
                ),
              );
            },
          ),
          if (_isSubmitting)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 20),
                    Text(
                      l.translate('submissionLoading'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Amiri',
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactMasterSection(
    AppLocalizations l,
    InventoryIssueMasterItem master,
    bool isArabic,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.white, const Color(0xFF6C63FF).withOpacity(0.03)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: Color(0xFF6C63FF),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l.translate('masterInfo'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1F36),
                    ),
                  ),
                ],
              ),
              const Divider(height: 16, thickness: 1),
              _buildCompactInfoRow(
                Icons.store,
                l.translate('store_name'),
                master.storeName ?? 'N/A',
              ),
              const SizedBox(height: 8),
              _buildCompactInfoRow(
                Icons.description,
                l.translate('item_name'),
                isArabic ? (master.descA ?? '') : (master.descE ?? ''),
              ),
              const SizedBox(height: 8),
              _buildCompactInfoRow(
                Icons.calendar_today,
                l.translate('req_date'),
                master.formattedTrnsDate,
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 280),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6C63FF).withOpacity(0.85),
                        const Color(0xFF8B7FFF).withOpacity(0.85),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.task_alt, size: 20),
                    label: Text(
                      l.translate('takeAction'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Amiri',
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed:
                        _isSubmitting
                            ? null
                            : () => _showActionDialog(context, l),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactInfoRow(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6C63FF).withOpacity(0.7), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDetailTable(
    AppLocalizations l,
    List<InventoryIssueDetailsItem> details,
    bool isArabic,
  ) {
    final columns = [
      l.translate("serial_number"),
      l.translate('item_name'),
      l.translate("item_number"),
      l.translate('quantity'),
      l.translate('unit_name'),
      l.translate('unit_cost'),
      l.translate('total'),
      //todo 2
      // l.translate("last_price"),
    ];
    int i = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.translate('itemDetails'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const Divider(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(
                const Color(0xFF6C63FF).withOpacity(0.1),
              ),
              headingTextStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF6C63FF),
                fontSize: 14,
              ),
              dataRowMinHeight: 60,
              dataRowMaxHeight: 80,
              columnSpacing: 30,
              columns:
                  columns
                      .map(
                        (title) => DataColumn(
                          label: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                      .toList(),
              rows: List<DataRow>.generate(details.length, (index) {
                final item = details[index];
                final color = index.isEven ? Colors.white : Colors.grey.shade50;
                return DataRow(
                  color: MaterialStateProperty.all(color),
                  cells: [
                    DataCell(Text((++i).toString())),
                    DataCell(
                      SizedBox(
                        child: Text(
                          isArabic
                              ? (item.itemName ?? '')
                              : (item.itemName ?? ''),
                          overflow: TextOverflow.visible,
                        ),
                      ),
                    ),
                    DataCell(Text(item.itemCode?.toString() ?? 'N/A')),
                    DataCell(Text(item.quantity?.toString() ?? 'N/A')),
                    DataCell(Text(item.unitName ?? 'N/A')),
                    DataCell(
                      Text(
                        item.unitCost?.toStringAsFixed(2).toString() ?? 'N/A',
                      ),
                    ),
                    DataCell(
                      Text(item.total?.toStringAsFixed(2).toString() ?? 'N/A'),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  void _showActionDialog(BuildContext context, AppLocalizations l) {
    final TextEditingController notesController = TextEditingController();
    bool isDialogLoading = false;

    showDialog(
      context: context,
      barrierDismissible: !_isSubmitting,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.task_alt, color: Color(0xFF6C63FF)),
                  SizedBox(width: 8),
                  Text(l.translate('takeAction')),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: notesController,
                    decoration: InputDecoration(
                      labelText: l.translate('notes'),
                      hintText: l.translate('notesHint'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  if (isDialogLoading)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(width: 16),
                          Text(l.translate('submitting')),
                        ],
                      ),
                    )
                  else
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Approve Button
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.shade600,
                                Colors.green.shade400,
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle, size: 20),
                            label: Text(
                              l.translate('approve'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed:
                                () => _showApproveConfirmation(
                                  dialogContext,
                                  notesController.text,
                                  setDialogState,
                                  isDialogLoading,
                                ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Reject Button
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.red.shade600,
                                Colors.red.shade400,
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.cancel, size: 20),
                            label: Text(
                              l.translate('reject'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed:
                                () => _showRejectConfirmation(
                                  dialogContext,
                                  notesController.text,
                                  setDialogState,
                                  isDialogLoading,
                                ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      isDialogLoading
                          ? null
                          : () => Navigator.pop(dialogContext),
                  child: Text(l.translate('cancel')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showApproveConfirmation(
    BuildContext dialogContext,
    String notes,
    StateSetter setDialogState,
    bool isDialogLoading,
  ) {
    final l = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    showDialog(
      context: dialogContext,
      builder:
          (confirmContext) => Directionality(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            // Fixed
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              icon: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, color: Colors.green, size: 32),
              ),
              title: Text(
                l.translate('confirmApproval'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l.translate('approveConfirmationMessage'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                  if (notes.isNotEmpty) ...[
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${l.translate('notes')}:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(notes, style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actionsAlignment: MainAxisAlignment.start,
              actions:
                  isArabic
                      ? [
                        // Arabic: Confirm button first (right side)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(confirmContext);
                            setDialogState(() => isDialogLoading = true);
                            _submitApproval(dialogContext, notes, 1);
                          },
                          child: Text(l.translate('confirmApprove')),
                        ),
                        // Arabic: Cancel button second (left side)
                        TextButton(
                          onPressed: () => Navigator.pop(confirmContext),
                          child: Text(
                            l.translate('cancel'),
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      ]
                      : [
                        // English: Confirm button first (left side)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(confirmContext);
                            setDialogState(() => isDialogLoading = true);
                            _submitApproval(dialogContext, notes, 1);
                          },
                          child: Text(l.translate('confirmApprove')),
                        ),
                        // English: Cancel button second (right side)
                        TextButton(
                          onPressed: () => Navigator.pop(confirmContext),
                          child: Text(
                            l.translate('cancel'),
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      ],
            ),
          ),
    );
  }

  void _showRejectConfirmation(
    BuildContext dialogContext,
    String notes,
    StateSetter setDialogState,
    bool isDialogLoading,
  ) {
    final l = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    showDialog(
      context: dialogContext,
      builder:
          (confirmContext) => Directionality(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            // Fixed
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              icon: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning, color: Colors.red, size: 32),
              ),
              title: Text(
                l.translate('confirmRejection'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l.translate('rejectConfirmationMessage'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                  if (notes.isNotEmpty) ...[
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${l.translate('notes')}:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(notes, style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actionsAlignment: MainAxisAlignment.start,
              actions:
                  isArabic
                      ? [
                        // Arabic: Confirm button first (right side)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(confirmContext);
                            setDialogState(() => isDialogLoading = true);
                            _submitApproval(dialogContext, notes, -1);
                          },
                          child: Text(l.translate('confirmReject')),
                        ),
                        // Arabic: Cancel button second (left side)
                        TextButton(
                          onPressed: () => Navigator.pop(confirmContext),
                          child: Text(
                            l.translate('cancel'),
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      ]
                      : [
                        // English: Confirm button first (left side)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(confirmContext);
                            setDialogState(() => isDialogLoading = true);
                            _submitApproval(dialogContext, notes, -1);
                          },
                          child: Text(l.translate('confirmReject')),
                        ),
                        // English: Cancel button second (right side)
                        TextButton(
                          onPressed: () => Navigator.pop(confirmContext),
                          child: Text(
                            l.translate('cancel'),
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      ],
            ),
          ),
    );
  }

  Future<void> _submitApproval(
    BuildContext dialogContext,
    String notes,
    int actualStatus,
  ) async {
    if (widget.request.prevSer == null || widget.request.lastLevel == null) {
      print(
        "❌ CRITICAL ERROR: Missing 'prev_ser' or 'last_level' in the initial ProductionOutbound object.",
      );
      print("❌ Make sure 'GET_inv_issue_AUTH' API returns these values!");
      _showErrorDialog(
        "بيانات الطلب الأساسية غير مكتملة (prev_ser, last_level). لا يمكن المتابعة.",
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final l = AppLocalizations.of(context)!;
    final int userId = widget.user.usersCode;
    final int roleCode = widget.user.roleCode!;
    final String authPk1 = widget.request.authPk1 ?? "";
    final String authPk2 = widget.request.authPk2 ?? "";
    final int lastLevel = widget.request.lastLevel ?? 0;
    final int prevSerOriginal = widget.request.prevSer ?? 0;

    try {
      print("--- 🚀 Starting Approval Process (Status: $actualStatus) ---");
      final ApprovalStatusResponse s1 = await _apiService.stage1_getStatus(
        userId: userId,
        roleCode: roleCode,
        authPk1: authPk1,
        authPk2: authPk2,
        actualStatus: actualStatus,
        approvalType: "inv_issue",
      );

      final int trnsStatus = s1.trnsStatus;
      final int prevSerS1 = s1.prevSer;
      final int prevLevelS1 = s1.prevLevel;
      final int roundNoS1 = s1.roundNo;

      print(
        "--- ℹ️ Stage 1 Data Received: trnsStatus=$trnsStatus, prevSer=$prevSerS1, prevLevel=$prevLevelS1, roundNo=$roundNoS1",
      );

      print(
        "--- ℹ️ Checking Stage 3 Condition: lastLevel ($lastLevel) == 1 && trnsStatus ($trnsStatus) == 1",
      );
      if (lastLevel == 1 && trnsStatus == 1) {
        print("--- 🚀 Condition Met (Stage 3) ---");
        await _apiService.stage3_checkLastLevel(
          userId: userId,
          authPk1: authPk1,
          authPk2: authPk2,
          approvalType: "inv_issue",
        );
      } else {
        print("--- ⏩ Skipping Stage 3 (Condition Not Met) ---");
      }

      final Map<String, dynamic> stage4Body = {
        "user_id": userId,
        "actual_status": actualStatus,
        "trns_notes": notes,
        "prev_ser": prevSerS1,
        "round_no": roundNoS1,
        "auth_pk1": authPk1,
        "auth_pk2": authPk2,
        "trns_status": trnsStatus,
      };
      await _apiService.stage4_updateStatus(stage4Body, "inv_issue");

      final Map<String, dynamic> stage5Body = {
        "auth_pk1": authPk1,
        "auth_pk2": authPk2,
        "prev_ser": prevSerOriginal,
        "prev_level": prevLevelS1,
      };
      await _apiService.stage5_deleteStatus(stage5Body, "inv_issue");

      print(
        "--- ℹ️ Checking Stage 6 Condition: trnsStatus ($trnsStatus) == 0 || trnsStatus ($trnsStatus) == -1",
      );
      if (trnsStatus == 0 || trnsStatus == -1) {
        print("--- 🚀 Condition Met (Stage 6) ---");
        final Map<String, dynamic> stage6Body = {
          "trns_status": trnsStatus,
          "prev_ser": prevSerS1,
          "prev_level": prevLevelS1,
          "round_no": roundNoS1,
          "auth_pk1": s1.authPk1,
          "auth_pk2": s1.authPk2,
          "auth_pk3": s1.authPk3,
          "auth_pk4": s1.authPk4,
          "auth_pk5": s1.authPk5,
        };
        await _apiService.stage6_postFinalStatus(stage6Body, "inv_issue");
      } else {
        print("--- ⏩ Skipping Stage 6 (Condition Not Met) ---");
      }

      print("--- ✅ Process Completed Successfully ---");
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      Navigator.pop(dialogContext);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.translate('submissionSuccess')),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      print("--- ❌ Process Failed ---");
      print("❌ ERROR DETAILS: $e");
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      Navigator.pop(dialogContext);
      _showErrorDialog(e.toString());
    }
  }

  void _showErrorDialog(String error) {
    final l = AppLocalizations.of(context)!;
    String userMessage = l.translate('submissionErrorBody');
    if (error.contains('noInternet')) {
      userMessage = l.translate('noInternet');
    }

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(l.translate('submissionError')),
            content: Text(userMessage),
            actions: [
              TextButton(
                child: Text(l.translate('ok')),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
    );
  }

  // ========================================================
  // 🎯 دالة الطباعة - بيانات ثابتة زي الصورة الثانية
  // ========================================================
  Future<void> _printDocument(AppLocalizations l, bool isArabic) async {
    try {
      final fontData = await rootBundle.load("assets/fonts/Amiri-Regular.ttf");
      final ttf = pw.Font.ttf(fontData);

      pw.MemoryImage? logoImage;
      try {
        final logoData = await rootBundle.load("assets/images/lo.png");
        logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
      } catch (e) {
        print("⚠️ Logo not found");
      }

      final headers = [
        "م",
        "رقم الصنف",
        "اسم الصنف",
        "الوحدة",
        "الكمية",
        "التكلفة",
        "رقم المشروع",
        "رقم البند الرئيسي",
        "رقم البند الفرعي",
        "رقم بند الصنف",
        "الاجمالي",
      ];

      ///table items data
      int rowNumber = 0;
      final data =
          _detailData!.map((item) {
            rowNumber++;
            return [
              rowNumber.toString(),
              item.itemCode?.toString() ?? '',
              isArabic ? (item.itemName ?? '') : (item.itemName ?? ''),
              item.unitName ?? '',
              item.quantity?.toStringAsFixed(2) ?? '0',
              item.unitCost?.toStringAsFixed(2) ?? '0',
              item.projectId?.toString() ?? '',
              item.mastBandCode?.toString() ?? '',
              item.bandCode?.toString() ?? '',
              item.consumableItemCode?.toString() ?? '',
              item.total?.toStringAsFixed(2) ?? '',
            ];
          }).toList();

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(base: ttf, bold: ttf, italic: ttf),
          build:
              (context) => [
                _buildFixedPdfHeader(
                  ttf,
                  logoImage,
                  _masterData!,
                  _detailData!,
                ),
                pw.SizedBox(height: 10),
                _buildPdfTable(headers, data, ttf),
                pw.SizedBox(height: 10),
                _buildFixedPdfFooter(ttf, _detailData!),
              ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      print("❌ Print Error: $e");
      rethrow;
    }
  }

  pw.Widget _buildFixedPdfHeader(
    pw.Font ttf,
    pw.MemoryImage? logo,
    InventoryIssueMasterItem master,
    List<InventoryIssueDetailsItem> details,
  ) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Container(
              padding: pw.EdgeInsets.all(2),
              decoration: pw.BoxDecoration(
                color: PdfColors.white, // Outer container background
                border: pw.Border.all(color: PdfColors.black, width: 1),
              ),
              child: pw.Container(
                padding: pw.EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 8,
                ), // Inner padding
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(
                    0x80D3D3D3,
                  ), // Grey with 50% opacity (D3D3D3 is light grey)
                  border: pw.Border.all(color: PdfColors.black, width: 1),
                ),
                child: pw.Text(
                  "تسوية صادر رقم     ${master.trnsSerial}/${master.trnsTypeCode}",
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 18,
                    color: PdfColors.blue900,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ),

            pw.SizedBox(width: 20),
            if (logo != null)
              pw.Image(logo, width: 60, height: 60)
            else
              pw.SizedBox(width: 60, height: 60),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(
          color: PdfColors.black,
          height: 1, // Line thickness
          thickness: 1, // Alternative way to set thickness
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Table(
              border: pw.TableBorder.all(),
              tableWidth: pw.TableWidth.min,
              children: [
                pw.TableRow(
                  children: [
                    pw.Container(
                      alignment: pw.Alignment.center,
                      padding: pw.EdgeInsets.all(4),

                      child: pw.Text(
                        "${master.docNo ?? ""}",
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Container(
                      padding: pw.EdgeInsets.all(4),
                      color: PdfColors.grey300,
                      child: pw.Text("رقم المستند"),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Container(
                      padding: pw.EdgeInsets.all(4),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        "${master.formattedTrnsDate ?? ""}",
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Container(
                      padding: pw.EdgeInsets.all(4),
                      color: PdfColors.grey300,
                      child: pw.Text("التاريخ"),
                    ),
                  ],
                ),
              ],
            ),
            pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "معد الحركة : ${master.insertUser.toString()}",
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    "تاريخ الادخال : ${master.formattedInsertDate.toString()}",
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    "المعتمد 1 : ${master.auth1Name ?? ""}",
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    "المعتمد 2 : ${master.auth2Name ?? ""}",
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(
              children: [
                pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    "${master.storeName ?? ""}",
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Container(
                  padding: pw.EdgeInsets.symmetric(horizontal: 4),
                  color: PdfColors.grey300,
                  child: pw.Text("اسم المخزن"),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    "${master.storeCode ?? ""}",
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Container(
                  padding: pw.EdgeInsets.symmetric(horizontal: 4),
                  color: PdfColors.grey300,
                  child: pw.Text("رقم المخزن"),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    "${master.costCode2 ?? ""} / ${master.costCode2Name ?? ""}",
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Container(
                  padding: pw.EdgeInsets.symmetric(horizontal: 4),
                  color: PdfColors.grey300,
                  child: pw.Text("مركز التكلفة 2 "),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    "${master.descA ?? master.descE ?? ""}",
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Container(
                  padding: pw.EdgeInsets.symmetric(horizontal: 4),
                  color: PdfColors.grey300,
                  child: pw.Text("البيان"),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPdfTable(
    List<String> headers,
    List<List<String>> data,
    pw.Font ttf,
  ) {
    return pw.TableHelper.fromTextArray(
      headers: headers.reversed.toList(),
      data: data.map((row) => row.reversed.toList()).toList(),
      border: pw.TableBorder.all(color: PdfColors.black, width: 1),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        font: ttf,
        fontSize: 9,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellStyle: pw.TextStyle(font: ttf, fontSize: 9),
      cellHeight: 25,
      headerAlignment: pw.Alignment.center,
      cellAlignment: pw.Alignment.center,
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
        5: pw.Alignment.center,
        6: pw.Alignment.center,
      },
      cellPadding: const pw.EdgeInsets.all(4),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.2),
        1: const pw.FlexColumnWidth(0.8),
        2: const pw.FlexColumnWidth(0.8),
        3: const pw.FlexColumnWidth(0.8),
        4: const pw.FlexColumnWidth(0.8),
        5: const pw.FlexColumnWidth(0.8),
        6: const pw.FlexColumnWidth(1),
        7: const pw.FlexColumnWidth(0.8),
        8: const pw.FlexColumnWidth(2.3),
        9: const pw.FlexColumnWidth(1.8),
        10: const pw.FlexColumnWidth(0.8),
      },
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
    );
  }

  pw.Widget _buildFixedPdfFooter(
    pw.Font ttf,
    List<InventoryIssueDetailsItem> inventoryIssueList,
  ) {
    double finalTotalCost = inventoryIssueList.fold(
      0.0,
      (sum, item) => sum + ((item.total!)),
    ); // الاجمالي قبل الحسابات
    return pw.Column(
      children: [
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Table(
              border: pw.TableBorder.all(),

              children: [
                pw.TableRow(
                  children: [
                    pw.Container(
                      alignment: pw.Alignment.center,
                      padding: pw.EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 22,
                      ),

                      child: pw.Text(
                        "${finalTotalCost.toStringAsFixed(2)}",
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),

                    pw.Container(
                      alignment: pw.Alignment.center,
                      padding: pw.EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 18,
                      ),

                      child: pw.Text(
                        "",
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),

                    pw.Container(
                      alignment: pw.Alignment.center,
                      padding: pw.EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 18,
                      ),

                      child: pw.Text(
                        "123",
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 15),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              children: [
                pw.Text(
                  "امين المخزن",
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Container(width: 120, height: 1, color: PdfColors.black),
              ],
            ),
            pw.Column(
              children: [
                pw.Text(
                  "اعتماد",
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Container(width: 120, height: 1, color: PdfColors.black),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
