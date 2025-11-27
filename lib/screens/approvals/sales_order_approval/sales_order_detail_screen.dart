import 'dart:developer';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:modernapproval/models/approval_status_response_model.dart';
import 'package:modernapproval/models/approvals/sales_order/sales_order_det_model.dart';
import 'package:modernapproval/models/approvals/sales_order/sales_order_mast_model.dart';
import 'package:modernapproval/models/user_model.dart';
import 'package:modernapproval/services/api_service.dart';
import 'package:modernapproval/widgets/error_display.dart';
import 'package:number_to_word_arabic/number_to_word_arabic.dart';
import '../../../app_localizations.dart';
import '../../../main.dart';

// --- مكتبات الطباعة ---
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/rendering.dart' show TextDirection;

import '../../../models/approvals/sales_order/sales_order_model.dart';
import '../../../services/event_bus.dart';

class SalesOrderDetailScreen extends StatefulWidget {
  final UserModel user;
  final SalesOrder request;

  const SalesOrderDetailScreen({
    super.key,
    required this.user,
    required this.request,
  });

  @override
  State<SalesOrderDetailScreen> createState() => _SalesOrderDetailScreenState();
}

class _SalesOrderDetailScreenState extends State<SalesOrderDetailScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _detailsFuture;

  SalesOrderMaster? _masterData;
  List<SalesOrderDetails>? _detailData;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _loadAllDetails();
  }

  Future<Map<String, dynamic>> _loadAllDetails() async {
    try {
      final results = await Future.wait([
        _apiService.getSalesOrderMaster(
          trnsTypeCode: widget.request.trnsTypeCode,
          trnsSerial: widget.request.trnsSerial,
        ),
        _apiService.getSalesOrderDetail(
          trnsTypeCode: widget.request.trnsTypeCode,
          trnsSerial: widget.request.trnsSerial,
        ),
      ]);

      setState(() {
        _masterData = results[0] as SalesOrderMaster;
        _detailData = results[1] as List<SalesOrderDetails>;
        log(_masterData!.repSales!.length.toString());
        log(_masterData!.repSales!.replaceAll(" ", '').length.toString());
        log(_masterData!.managerSales!.length.toString());
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
        title: Text(l.translate('salesDetails')),
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
                        await _printDocument(l, isArabic, _masterData!);
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

              final masterData = snapshot.data!['master'] as SalesOrderMaster;
              final detailData =
                  snapshot.data!['detail'] as List<SalesOrderDetails>;

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
    SalesOrderMaster master,
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
                isArabic
                    ? master.storeNameA ?? 'N/A'
                    : master.storeNameE ?? 'N/A',
              ),
              const SizedBox(height: 8),
              // _buildCompactInfoRow(
              //   Icons.description,
              //   l.translate('item_name'),
              //   isArabic ? (master. ?? '') : (master.descE ?? ''),
              // ),
              const SizedBox(height: 8),
              _buildCompactInfoRow(
                Icons.calendar_today,
                l.translate('order_date'),
                master.formattedOrderDate,
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
    List<SalesOrderDetails> details,
    bool isArabic,
  ) {
    final columns = [
      l.translate("serial_number"),
      l.translate('item_name'),
      l.translate("item_number"),
      l.translate('quantity'),
      l.translate('unit_name'),
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
                    DataCell(Text(item.qty?.toString() ?? 'N/A')),
                    DataCell(Text(item.unitName ?? 'N/A')),
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
        "❌ CRITICAL ERROR: Missing 'prev_ser' or 'last_level' in the initial SalesRequest object.",
      );
      print("❌ Make sure 'getSaleAuth' API returns these values!");
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
    final String authPk1 = widget.request.authPk1;
    final String authPk2 = widget.request.authPk2;
    final int lastLevel = widget.request.lastLevel!;
    final int prevSerOriginal = widget.request.prevSer!;

    try {
      BotToast.showLoading();
      print("--- 🚀 Starting Approval Process (Status: $actualStatus) ---");
      //todo update stage 1 here for sale
      final ApprovalStatusResponse s1 = await _apiService.stage1_getStatus(
        userId: userId,
        roleCode: roleCode,
        authPk1: authPk1,
        authPk2: authPk2,
        actualStatus: actualStatus,
        approvalType: "sale_order",
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
        //todo update this stage for sale
        await _apiService.stage3_checkLastLevel(
          userId: userId,
          authPk1: authPk1,
          authPk2: authPk2,
          approvalType: "sale_order",
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
      //todo update stage 4 for sale
      await _apiService.stage4_updateStatus(stage4Body, "sale_order");

      final Map<String, dynamic> stage5Body = {
        "auth_pk1": authPk1,
        "auth_pk2": authPk2,
        "prev_ser": prevSerOriginal,
        "prev_level": prevLevelS1,
      };

      //todo update stage 5 for order
      await _apiService.stage5_deleteStatus(stage5Body, "sale_order");

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

        //todo update stage 6 for order
        await _apiService.stage6_postFinalStatus(stage6Body, "sale_order");
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
      BotToast.closeAllLoading();
      EventBus.notifyHomeRefresh();
      Navigator.pop(context, true);
    } catch (e) {
      BotToast.closeAllLoading();
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
  Future<void> _printDocument(
    AppLocalizations l,
    bool isArabic,
    SalesOrderMaster salesOrderMaster,
  ) async {
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
        "كود الصنف",
        "أسم الصنف",
        "الوحدة",
        "الكمية",
        "السعر",
        "الاجمالي",
        "الملاحظات",
      ];

      ///Master items data
      int rowNumberMaster = 0;
      final dataTopTable =
          _detailData!.map((item) {
            rowNumberMaster++;
            return [
              rowNumberMaster.toString(),
              item.itemCode?.toString() ?? '',
              isArabic ? (item.itemName ?? '') : (item.itemName ?? ''),
              item.unitName ?? '',
              item.qty?.toString() ?? '0',
              item.price?.toString() ?? '',
              item.totPrice?.toString() ?? '',
              item.note?.toString() ?? '',
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
                _buildFixedPdfHeader(ttf, logoImage),
                _buildFirstTable(_masterData!),
                pw.SizedBox(height: 4),
                _buildSecondTable(_masterData!, ttf),
                pw.SizedBox(height: 4),
                _buildPdfTable(headers, dataTopTable, ttf),
                pw.SizedBox(height: 1),
                _buildPdfTableTotalPriceSkeleton(_detailData!, ttf),
                pw.SizedBox(height: 4),
                _buildPdfLastTable(ttf),

                pw.SizedBox(height: 10),

                _buildFixedPdfFooter(ttf, _masterData!, _detailData!),
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

  pw.Widget _buildFixedPdfHeader(pw.Font ttf, pw.MemoryImage? logo) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (logo != null)
          pw.Column(children: [pw.Image(logo, width: 60, height: 60)])
        else
          pw.SizedBox(width: 60, height: 60),
      ],
    );
  }

  pw.Widget _buildFirstTable(SalesOrderMaster master) {
    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(2.2),
        1: const pw.FlexColumnWidth(2.0),
        2: const pw.FlexColumnWidth(1.8),
        3: const pw.FlexColumnWidth(1.5),
      },
      border: pw.TableBorder.all(width: 2),
      children: [
        pw.TableRow(
          children: [
            pw.Container(
              width: 1,
              padding: const pw.EdgeInsets.all(8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(":Sales Order"),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("رقم امر البيع:"),
                      pw.Text("${master.salesOrderNo}"),
                    ],
                  ),
                  pw.Text(":Date"),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("التاريخ:"),
                      pw.Text("${master.formattedOrderDate}"),
                      // pw.Text("${}"),
                    ],
                  ),
                ],
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(":Issue Date"),
                  pw.Text("تاريخ الصرف:"),
                  pw.Text(":Issue At"),
                  pw.Text("وقت الصرف:"),
                ],
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Column(
                children: [
                  pw.Text("Document No رقم الوثيقة"),
                  pw.Text("012-MSE"),
                ],
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Column(
                children: [pw.Text("Sell Order"), pw.Text("أمر بيع")],
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildSecondTable(SalesOrderMaster master, pw.Font ttf) {
    return pw.Table(
      border: pw.TableBorder.all(width: 2),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.0),
        1: const pw.FlexColumnWidth(2.0),
      },
      children: [
        pw.TableRow(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(":Sale Offer No"),
                  pw.Text("رقم عرض البيع:"),
                  pw.Text(":Store Code"),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("رقم المخزن:"),
                      pw.Text("${master.storeCode}"),
                    ],
                  ),
                ],
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(":Client Name"),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("اسم العميل:"),
                      pw.Text(
                        "${master.customerNameA ?? master.customerNameE}",
                        style: pw.TextStyle(font: ttf, fontSize: 9),
                      ),
                    ],
                  ),
                  pw.Text(":Store Name"),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("رقم المخزن:"),
                      pw.Text("${master.storeNameA ?? master.storeNameE}"),
                    ],
                  ),
                ],
              ),
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
        0: const pw.FlexColumnWidth(1.4),
        1: const pw.FlexColumnWidth(1.4),
        2: const pw.FlexColumnWidth(1.4),
        3: const pw.FlexColumnWidth(0.8),
        4: const pw.FlexColumnWidth(1.0),
        5: const pw.FlexColumnWidth(2.2),
        6: const pw.FlexColumnWidth(2.3),
        7: const pw.FlexColumnWidth(1.4),
      },
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
    );
  }

  pw.Widget _buildPdfTableTotalPriceSkeleton(
    List<SalesOrderDetails> listSalesOrderDetail,
    pw.Font ttf,
  ) {
    num total = listSalesOrderDetail.fold(
      0.0,
      (sum, item) => sum + item.totPrice!,
    );
    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(0.8),
        1: const pw.FlexColumnWidth(1.4),
        2: const pw.FlexColumnWidth(1.4),
        3: const pw.FlexColumnWidth(0.8),
        4: const pw.FlexColumnWidth(1.2),
        5: const pw.FlexColumnWidth(2.3),
        6: const pw.FlexColumnWidth(2.3),
        7: const pw.FlexColumnWidth(1.4),
      },
      children: [
        pw.TableRow(
          children: [
            pw.Text(""),
            pw.Text("${total}"),
            pw.Text("الاجمالي:"),
            pw.Text(""),
            pw.Text(""),
            pw.Text(""),
            pw.Text(""),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPdfLastTable(pw.Font ttf) {
    return pw.Table(
      border: pw.TableBorder.all(width: 2),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.4),
        1: const pw.FlexColumnWidth(1.4),
        2: const pw.FlexColumnWidth(1.0),
      },
      children: [
        pw.TableRow(
          children: [
            pw.Text(" مدير ادارة المبيعات :"),
            pw.Text(" مسؤول المبيعات :"),
            pw.Text(" قسم الحسابات :"),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("الاسم:"),

                    (_masterData!.managerSales
                                ?.replaceAll(" ", "")
                                .isNotEmpty ??
                            false)
                        ? pw.FittedBox(
                          child: pw.Text("${_masterData!.managerSales}"),
                        )
                        : pw.Text(" "),

                    pw.SizedBox(width: 1),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [pw.Text(":التوقيع"), pw.SizedBox(width: 1)],
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("الاسم:"),
                    (_masterData!.repSales?.replaceAll(" ", "").isNotEmpty ??
                            false)
                        ? pw.FittedBox(
                          child: pw.Text("${_masterData!.repSales}"),
                        )
                        : pw.Text(""),
                    pw.SizedBox(width: 1),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [pw.Text(":التوقيع"), pw.SizedBox(width: 1)],
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [pw.Text("الاسم:"), pw.SizedBox(width: 1)],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [pw.Text(":التوقيع"), pw.SizedBox(width: 1)],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPdfTotalTable(
    SalesOrderMaster salesOrderMaster,
    List<SalesOrderDetails> listSalesOrderDetail,
  ) {
    double grandTotalBeforeCalc = listSalesOrderDetail.fold(
      0.0,
      (sum, item) => sum + item.totPrice!,
    ); // الاجمالي قبل الحسابات
    num taxSal = salesOrderMaster.taxSal ?? 0;
    num taxProf = salesOrderMaster.taxSal ?? 0;
    num otherExp = salesOrderMaster.taxSal ?? 0;
    num discVal = salesOrderMaster.taxSal ?? 0;
    num finalTotalCost =
        (grandTotalBeforeCalc + taxSal) - taxProf - otherExp - discVal;
    String finalTotalCostArabic = Tafqeet.convert('${finalTotalCost.toInt()}');

    return pw.Column(
      children: [
        pw.Table(
          border: pw.TableBorder.all(),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(6),
          },
          children: [
            pw.TableRow(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('$grandTotalBeforeCalc'),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('الاجمالي'),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('${taxSal}'),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('ضريبة القيمة المضافة'),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('${taxProf}'),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('ضريبة أ ت'),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('${otherExp}'),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('مصاريف اخري'),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('${discVal}'),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('خصم'),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('${finalTotalCost}'),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('المجموع'),
                ),
              ],
            ),
          ],
        ),
        // The last cell as the second element in the column
        pw.Container(
          width: double.infinity, // This will make it full width
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(border: pw.TableBorder.all()),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(' اجمالي المبلغ      فقط('),
              pw.Text('${finalTotalCostArabic}'),
              pw.Text('('),
              pw.SizedBox(width: 1),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildFixedPdfFooter(
    pw.Font ttf,
    SalesOrderMaster salesOrderMaster,
    List<SalesOrderDetails> listSalesOrderDetail,
  ) {
    num total = listSalesOrderDetail.fold(
      0.0,
      (sum, item) => sum + item.totPrice!,
    );
    num tax14 = salesOrderMaster.taxSal ?? 0.00;
    String currentDateTime = DateFormat(
      'yyyy-MM-dd hh:mm:ss a',
      'ar',
    ).format(DateTime.now()).replaceAll('AM', 'ص').replaceAll('PM', 'م');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,

      children: [
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "مكان التسليم :",
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  "وصف مكان التسليم :",
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  "شروط أخري:",
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  "شروط الدفع :",
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  "تاريخ التسليم :",
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  "صلاحية العرض : لا شئ من تاريخه",
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  children: [
                    pw.Text(
                      "الاجمالي :",
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Container(
                      height: 25,
                      width: 100,
                      alignment: pw.Alignment.center,
                      margin: pw.EdgeInsets.only(right: 5),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white.shade(0.6),
                        border: pw.Border.all(color: PdfColors.black),
                      ),
                      child: pw.Text(
                        "${total}",
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 3),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      ": % 14",
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Container(
                      height: 25,
                      width: 100,
                      alignment: pw.Alignment.center,
                      margin: pw.EdgeInsets.only(right: 5),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white.shade(0.6),
                        border: pw.Border.all(color: PdfColors.black),
                      ),
                      child: pw.Text(
                        "${tax14}",
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 3),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "الاجمالي بعد 14 % :",
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Container(
                      height: 25,
                      width: 100,
                      alignment: pw.Alignment.center,
                      margin: pw.EdgeInsets.only(right: 5),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white.shade(0.6),
                        border: pw.Border.all(color: PdfColors.black),
                      ),
                      child: pw.Text(
                        "${total + tax14}",
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 12,
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

        pw.SizedBox(height: 10),
      ],
    );
  }
}
