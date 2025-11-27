import 'dart:developer';

import 'package:modernapproval/models/approvals/general_journal_disbursement_approval/general_journal_desbursement_approval_model/general_journal_desbursement_approval_item.dart';
import 'package:modernapproval/models/approvals/general_journal_disbursement_approval/general_journal_disbursement_details_model/general_journal_disbursement_details_item.dart';
import 'package:modernapproval/models/approvals/general_journal_disbursement_approval/general_journal_disbursement_master_model/general_journal_disbursement_master_item.dart';
import 'package:modernapproval/models/approvals/purchase_pay/purchase_pay_det_model.dart';
import 'package:modernapproval/models/approvals/purchase_pay/purchase_pay_mast_model.dart';
import 'package:modernapproval/models/approvals/purchase_pay/purchase_pay_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:modernapproval/models/approval_status_response_model.dart';
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

// ---------------------

class GeneralJournalDisbursementDetailsScreen extends StatefulWidget {
  final UserModel user;
  final GeneralJournalDesbursementApprovalItem request;

  const GeneralJournalDisbursementDetailsScreen({
    super.key,
    required this.user,
    required this.request,
  });

  @override
  State<GeneralJournalDisbursementDetailsScreen> createState() =>
      _GeneralJournalDisbursementDetailsScreenState();
}

class _GeneralJournalDisbursementDetailsScreenState
    extends State<GeneralJournalDisbursementDetailsScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _detailsFuture;

  GeneralJournalDisbursementMasterItem? _masterData;
  List<GeneralJournalDisbursementDetailsItem>? _detailData;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _loadAllDetails();
  }

  Future<Map<String, dynamic>> _loadAllDetails() async {
    try {
      final results = await Future.wait([
        _apiService.getGeneralJournalDisbursementApprovalMaster(
          trnsTypeCode: widget.request.trnsTypeCode ?? 0,
          trnsSerial: widget.request.reqSerial ?? 0,
        ),
        _apiService.getGeneralJournalDisbursementApprovalDetail(
          trnsTypeCode: widget.request.trnsTypeCode ?? 0,
          trnsSerial: widget.request.reqSerial ?? 0,
        ),
      ]);
      log("message1");
      setState(() {
        _masterData = results[0] as GeneralJournalDisbursementMasterItem;
        _detailData = results[1] as List<GeneralJournalDisbursementDetailsItem>;
      });
      log("message");
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
        title: Text(l.translate('purchasePayDetails')),
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

              final masterData =
                  snapshot.data!['master']
                      as GeneralJournalDisbursementMasterItem;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCompactMasterSection1(
                      l,
                      masterData,
                      isArabic,
                      "transaction_info",
                    ),
                    _buildCompactMasterSection2(
                      l,
                      masterData,
                      isArabic,
                      "supplier_info",
                    ),

                    _buildCompactMasterSection(
                      l,
                      masterData,
                      isArabic,
                      "payment_info",
                    ),

                    const SizedBox(height: 20),
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

  Widget _buildCompactMasterSection1(
    AppLocalizations l,
    GeneralJournalDisbursementMasterItem master,
    bool isArabic,
    String? title,
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
                    l.translate(title ?? 'masterInfo'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1F36),
                    ),
                  ),
                ],
              ),
              // const Divider(height: 16, thickness: 1),
              // _buildCompactInfoRow(
              //   Icons.calendar_today,
              //   l.translate('store'),
              //   master.storeName,
              // ),
              // const SizedBox(height: 8),

              // _buildCompactInfoRow(
              //   Icons.calendar_today,
              //   l.translate('store_code'),
              //   master..toString(),
              // ),
              const SizedBox(height: 8),
              _buildCompactInfoRow(
                Icons.description,
                l.translate('trns_desc'),
                isArabic ? (master.trnsDesc ?? '') : (master.trnsDesc ?? ''),
              ),
              const SizedBox(height: 8),
              _buildCompactInfoRow(
                Icons.calendar_today,
                l.translate('operation_number'),
                master.trnsTypeCode.toString(),
              ),
              const SizedBox(height: 8),

              _buildCompactInfoRow(
                Icons.calendar_today,
                l.translate('operation_date'),
                master.formattedReqDate.toString() ?? 'N/A',
              ),

              const SizedBox(height: 8),
              Row(
                children: [
                  // Flexible(
                  //   flex: 1,
                  //   child: Container(
                  //     height: 55,
                  //     child: _buildCompactInfoRow(
                  //       Icons.store,
                  //       l.translate('index'),
                  //       master.reqSerial.toString() ?? 'N/A',
                  //     ),
                  //   ),
                  // ),
                  // SizedBox(width: 4),
                  Flexible(
                    flex: 1,
                    child: Container(
                      height: 55,
                      child: _buildCompactInfoRow(
                        Icons.calendar_today,
                        l.translate('serial_number'),
                        master.reqSerial.toString(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactMasterSection2(
    AppLocalizations l,
    GeneralJournalDisbursementMasterItem master,
    bool isArabic,
    String? title,
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
                    l.translate(title ?? 'masterInfo'),
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
                Icons.calendar_today,
                l.translate('transaction'),
                master.trnsDesc.toString(),
              ),
              const SizedBox(height: 8),

              _buildCompactInfoRow(
                Icons.calendar_today,
                l.translate('transaction_code'),
                master.trnsTypeCode.toString(),
              ),
              const SizedBox(height: 8),
              _buildCompactInfoRow(
                Icons.calendar_today,
                l.translate('supplier_name'),
                master.supplierName.toString(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactMasterSection(
    AppLocalizations l,
    GeneralJournalDisbursementMasterItem master,
    bool isArabic,
    String? title,
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
                    l.translate(title ?? 'masterInfo'),
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
                l.translate('payment_method'),
                master.payMethd.toString() ?? 'N/A',
              ),
              const SizedBox(height: 8),
              _buildCompactInfoRow(
                Icons.description,
                l.translate('due_date'),
                master.formattedReqDate.toString() ?? 'N/A',
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Flexible(
                    flex: 1,
                    child: Container(
                      height: 55,
                      child: _buildCompactInfoRow(
                        Icons.calendar_today,
                        l.translate('total'),
                        (master.totalValue ?? master.totalValue).toString(),
                      ),
                    ),
                  ),

                  SizedBox(width: 4),
                  Flexible(
                    flex: 1,
                    child: Container(
                      height: 55,
                      child: _buildCompactInfoRow(
                        Icons.calendar_today,
                        l.translate('currency'),
                        master.currencyDesc.toString(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildCompactInfoRow(
                Icons.description,
                l.translate('payment_state'),
                master.payFlag.toString(),
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
                            colors: [Colors.red.shade600, Colors.red.shade400],
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
        "❌ CRITICAL ERROR: Missing 'prev_ser' or 'last_level' in the initial PurchaseRequest object.",
      );
      print("❌ Make sure 'GET_PUR_REQUEST_AUTH' API returns these values!");
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
    final String authPk1 = widget.request.authPk1 ?? '';
    final String authPk2 = widget.request.authPk2 ?? '';
    final int lastLevel = widget.request.lastLevel!;
    final int prevSerOriginal = widget.request.prevSer!;

    try {
      print("--- 🚀 Starting Approval Process (Status: $actualStatus) ---");
      final ApprovalStatusResponse s1 = await _apiService.stage1_getStatus(
        userId: userId,
        roleCode: roleCode,
        authPk1: authPk1,
        authPk2: authPk2,
        actualStatus: actualStatus,
        approvalType: "gen_j_disbursement",
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
          approvalType: "gen_j_disbursement",
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
      await _apiService.stage4_updateStatus(stage4Body, "gen_j_disbursement");

      final Map<String, dynamic> stage5Body = {
        "auth_pk1": authPk1,
        "auth_pk2": authPk2,
        "prev_ser": prevSerOriginal,
        "prev_level": prevLevelS1,
      };

      await _apiService.stage5_deleteStatus(stage5Body, "gen_j_disbursement");

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

        await _apiService.stage6_postFinalStatus(
          stage6Body,
          "gen_j_disbursement",
        );
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
  Future<void> _printDocument(
    AppLocalizations l,
    bool isArabic,
    GeneralJournalDisbursementMasterItem purchasePayMaster,
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
        "البيان",
        "اسم المشروع",
        "رقم البند الرئيسي",
        "رقم البند الفرعي",
        "رقم البند الاعمال",
        "القيمة",
        "مركز تكلفة1",
        "مركز تكلفة2",
      ];

      ///Master items data
      int rowNumberMaster = 0;
      final dataTopTable =
          _detailData!.map((item) {
            rowNumberMaster++;
            return [
              rowNumberMaster.toString(),
              item.pyTkDescA?.toString() ?? '',
              item.projectName?.toString() ?? '',
              item.mastBandCode?.toString() ?? '',
              item.bandCode?.toString() ?? '',
              item.detBandCode?.toString() ?? '',
              item.valueCurr?.toString() ?? '',
              item.costCenter1?.toString() ?? '',
              item.costCenter2?.toString() ?? '',
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
                  purchasePayMaster,
                  _detailData!.first,
                ),
                pw.SizedBox(height: 10),
                _buildPdfTable(headers, dataTopTable, ttf),
                // pw.SizedBox(height: 10),
                _buildPdfTotalTable(_masterData!, _detailData!, ttf),
                // pw.SizedBox(height: 10),
                _buildFixedPdfFooter(ttf, purchasePayMaster),
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
    GeneralJournalDisbursementMasterItem purchasePayMaster,
    GeneralJournalDisbursementDetailsItem purchasePayDetail,
  ) {
    ///current date time
    DateTime now = DateTime.now();
    String formattedTime = DateFormat('hh:mm:a').format(now);
    formattedTime = formattedTime.replaceAll('AM', 'ص').replaceAll('PM', 'م');

    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logo != null)
              pw.Column(children: [pw.Image(logo, width: 60, height: 60)])
            else
              pw.SizedBox(width: 60, height: 60),
            pw.Column(
              children: [
                pw.Text(
                  "نظام الحسابات العامة",
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red,
                  ),
                ),
                pw.Text(
                  "نموذج رقم 201009 ش ع 2017/12",
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        // pw.SizedBox(height: 5),
        // pw.Row(
        //   mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        //   children: [
        //     pw.Text(
        //       "شركة المنشأت والمعدات الحديثه",
        //       style: pw.TextStyle(font: ttf, fontSize: 12),
        //       textDirection: pw.TextDirection.ltr,
        //     ),
        //   ],
        // ),
        pw.SizedBox(height: 5),
        pw.Column(
          children: [
            pw.Text(
              "طلب",
              style: pw.TextStyle(
                font: ttf,
                fontSize: 9,
                color: PdfColors.blue900,
                fontWeight: pw.FontWeight.bold,
                decoration: pw.TextDecoration.underline,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              "    صرف مبالغ نقدية على سبيل الأمانة    ",
              style: pw.TextStyle(
                font: ttf,
                fontSize: 9,
                color: PdfColors.blue900,
                fontWeight: pw.FontWeight.bold,
                decoration: pw.TextDecoration.underline,
              ),
            ),
          ],
        ),

        ///Date
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          children: [
            pw.Text(
              "رقم الحركة  : ",
              style: pw.TextStyle(font: ttf, fontSize: 9),
            ),
            pw.SizedBox(width: 10),
            pw.Text(
              "${purchasePayMaster.reqSerial} /  ${purchasePayMaster.descA}",
              style: pw.TextStyle(
                font: ttf,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(""),
          ],
        ),

        pw.SizedBox(height: 3),

        ///supplier name and code
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          children: [
            pw.Text("البيان : ", style: pw.TextStyle(font: ttf, fontSize: 9)),
            pw.SizedBox(width: 10),
            pw.Text(
              "${purchasePayMaster.trnsDesc} ",
              style: pw.TextStyle(
                font: ttf,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Spacer(),
            pw.Text("المسلسل : ", style: pw.TextStyle(font: ttf, fontSize: 9)),
            pw.SizedBox(width: 10),
            pw.Text(
              "${purchasePayMaster.reqSerial} ",
              style: pw.TextStyle(
                font: ttf,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),

        pw.SizedBox(height: 3),

        ///company name  , currency , closed or not
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          children: [
            pw.Text(
              "السداد : ${purchasePayMaster.payMethd}",
              style: pw.TextStyle(font: ttf, fontSize: 9),
            ),
            pw.Spacer(),
            pw.Text(
              "حالة الطلب :  ${purchasePayMaster.closed == 1 ? 'مغلق' : 'غير مغلق'}",
              style: pw.TextStyle(
                font: ttf,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),

        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          children: [
            pw.Text(
              "جهة السداد : ${purchasePayMaster.cpBnkBoxCode}",
              style: pw.TextStyle(font: ttf, fontSize: 9),
            ),
            pw.SizedBox(width: 10),
            pw.Text(
              "${purchasePayMaster.cpBnkBoxName}",
              style: pw.TextStyle(
                font: ttf,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Text(
              "العملة :  ${purchasePayMaster.currencyDesc}",
              style: pw.TextStyle(
                font: ttf,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),

        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          children: [
            pw.Text(
              "المورد : ${purchasePayMaster.supplierName}",
              style: pw.TextStyle(font: ttf, fontSize: 9),
            ),
            pw.Spacer(),
            pw.Text(
              "القيمة :  ${purchasePayMaster.totalValue}",
              style: pw.TextStyle(
                font: ttf,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),

        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          children: [
            pw.Text(
              "التاريخ : ${purchasePayMaster.formattedReqDate}",
              style: pw.TextStyle(font: ttf, fontSize: 9),
            ),
            pw.Spacer(),
            pw.Text(
              "حالة السداد :  ${purchasePayMaster.payFlag}",
              style: pw.TextStyle(
                font: ttf,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 3),
        // pw.Row(
        //   mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,

        //   children: [
        //     pw.Column(
        //       crossAxisAlignment: pw.CrossAxisAlignment.start,
        //       children: [
        //         pw.Text(
        //           "رقم المخزن : ${_masterData!.storeCode}",
        //           style: pw.TextStyle(font: ttf, fontSize: 9),
        //         ),
        //         pw.Text(
        //           "تاريخ الطلب : ${_masterData!.formattedReqDate}",
        //           style: pw.TextStyle(font: ttf, fontSize: 9),
        //         ),
        //         pw.Text(
        //           "طريقة السداد : ${_masterData!.payMethod}",
        //           style: pw.TextStyle(font: ttf, fontSize: 9),
        //         ),
        //         pw.Text(
        //           "حالة الدفع : ${_masterData!.payFlag}",
        //           style: pw.TextStyle(font: ttf, fontSize: 9),
        //         ),
        //       ],
        //     ),
        //     pw.Column(
        //       crossAxisAlignment: pw.CrossAxisAlignment.start,
        //       children: [
        //         pw.Text(
        //           "اسم المخزن : ${_masterData!.storeName}",
        //           style: pw.TextStyle(font: ttf, fontSize: 9),
        //         ),
        //         pw.Text(
        //           "رقم امر التوريد : ${_masterData!.orderTrnsType} / ${_masterData!.orderTrnsSerial}",
        //           style: pw.TextStyle(font: ttf, fontSize: 9),
        //         ),
        //         //todo ask about this approve flag
        //         pw.Text(
        //           "حالة الاعتماد : ${_masterData!.approveFlag == 1 ? "معتمد" : "غير معتمد"}",
        //           style: pw.TextStyle(font: ttf, fontSize: 9),
        //         ),
        //         pw.Text(
        //           "حالة الاقفال : ${_masterData!.closed == 1 ? "مقفل" : "غير مقفل"}",
        //           style: pw.TextStyle(font: ttf, fontSize: 9),
        //         ),
        //       ],
        //     ),
        //   ],
        // ),
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
        color: PdfColors.blue900,

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
        1: const pw.FlexColumnWidth(1.6),
        2: const pw.FlexColumnWidth(1.2),
        3: const pw.FlexColumnWidth(1.6),
        4: const pw.FlexColumnWidth(1.6),
        5: const pw.FlexColumnWidth(1.6),
        6: const pw.FlexColumnWidth(1.8),
        7: const pw.FlexColumnWidth(2.5),
        8: const pw.FlexColumnWidth(0.6),
      },
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
    );
  }

  pw.Widget _buildPdfTotalTable(
    GeneralJournalDisbursementMasterItem purchasePayMaster,
    List<GeneralJournalDisbursementDetailsItem> listPurchasePayDetail,
    pw.Font ttf,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 5),
        pw.Text(
          "يرجي صرف المبلغ المذكور فقط كهعدة ، وأتعهد بإستخدام المبلغ للقيام بالأعمال المحددة بالبيان وأتعهد بتقديم المستندات الدالة علي ذلك وتسوية",
          style: pw.TextStyle(font: ttf, fontSize: 9),
        ),
        pw.SizedBox(height: 5),
        pw.Text('المبلغ  : ${purchasePayMaster.totalValue}'),
        pw.SizedBox(height: 5),
        pw.Text('الاسم : ${purchasePayMaster.supplierName}'),
        pw.SizedBox(height: 5),
        pw.Text('التوقيع : ...................'),
        pw.SizedBox(height: 5),
        pw.Text('الوظيفة : ...................'),
        pw.SizedBox(height: 5),
        pw.Text('تحريرا في : ...................'),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Container(
              width: 300,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('الأدارة المالية : '),
                  pw.Row(
                    children: [
                      pw.Text('المراجعه : '),
                      pw.SizedBox(width: 100),

                      pw.Text('التوقيع : '),
                    ],
                  ),
                  pw.Row(
                    children: [
                      pw.Text('المدير المالى : '),
                      pw.SizedBox(width: 80),
                      pw.Text('التوقيع : '),
                    ],
                  ),
                ],
              ),
            ),
            pw.Container(
              width: 300,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('الأدارة : '),
                  pw.Row(children: [pw.Text('مدير الادارة : ')]),
                  pw.Row(children: [pw.Text('التوقيع واعتماد الطلب : ')]),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildFixedPdfFooter(
    pw.Font ttf,
    GeneralJournalDisbursementMasterItem purchasePayMaster,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,

      children: [
        pw.SizedBox(height: 3),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            pw.Text(
              "يعتمد الصرف ,",
              style: pw.TextStyle(
                font: ttf,
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            pw.Text(
              "التوقيع /",
              style: pw.TextStyle(
                font: ttf,
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(),
            pw.Column(
              children: [
                pw.Text(
                  "معد الحركة / ${purchasePayMaster.insertUser ?? ''}",
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  "تاريخ اعداد الحركة / ${purchasePayMaster.formattedReqDate}",
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            pw.Text(
              "*  اعتماد الصرف قاصر علي السادة رئيس وأعضاء مجلس الإدارة فقط ",
              style: pw.TextStyle(
                font: ttf,
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            pw.Text(
              "الاعتمادات / ",
              style: pw.TextStyle(
                font: ttf,
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Column(
              children: [
                pw.Text(
                  "عضو مجلس الإدارة المنتدب الرئيس التنفيذى",
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text("......................."),
              ],
            ),
            pw.Column(
              children: [
                pw.Text(
                  "رئيس مجلس الإدارة",
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text("......................."),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
