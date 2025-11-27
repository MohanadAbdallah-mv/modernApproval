import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:modernapproval/models/approval_status_response_model.dart'; // <-- إضافة
import 'package:modernapproval/models/approvals/exit_permission/exit_permission_model.dart';
import 'package:modernapproval/models/approvals/inventory_issue/inventory_issue_details_model/inventory_issue_details_item.dart';
import 'package:modernapproval/models/approvals/inventory_issue/inventory_issue_master_model/inventory_issue_master_item.dart';
import 'package:modernapproval/models/approvals/inventory_issue/inventory_issue_model/inventory_issue.dart';
import 'package:modernapproval/models/approvals/leave_and_absence/leave_absence_model.dart';
import 'package:modernapproval/models/approvals/production_inbound/production_inbound_details_model/details_item.dart';
import 'package:modernapproval/models/approvals/production_inbound/production_inbound_master_model/master_item.dart';
import 'package:modernapproval/models/approvals/production_inbound/production_inbound_model/item.dart';
import 'package:modernapproval/models/approvals/production_outbound/production_outbound_det_model.dart';
import 'package:modernapproval/models/approvals/production_outbound/production_outbound_mast_model.dart';
import 'package:modernapproval/models/approvals/production_outbound/production_outbound_model.dart';
import 'package:modernapproval/models/approvals/purchase_order/purchase_order_mast_model.dart';
import 'package:modernapproval/models/approvals/purchase_order/purchase_order_det_model.dart';
import 'package:modernapproval/models/approvals/purchase_pay/purchase_pay_det_model.dart';
import 'package:modernapproval/models/approvals/purchase_pay/purchase_pay_mast_model.dart';
import 'package:modernapproval/models/approvals/purchase_pay/purchase_pay_model.dart';
import 'package:modernapproval/models/approvals/sales_order/sales_order_det_model.dart';
import 'package:modernapproval/models/approvals/sales_order/sales_order_mast_model.dart';
import 'package:modernapproval/models/approvals/sales_order/sales_order_model.dart';
import 'package:modernapproval/models/approved_request_model.dart';
import 'package:modernapproval/models/dashboard_stats_model.dart';
import 'package:modernapproval/models/form_report_model.dart';
import 'package:modernapproval/models/password_group_model.dart';
import 'package:modernapproval/models/purchase_request_model.dart';
import '../models/approvals/purchase_order/purchase_order_model.dart';
import '../models/purchase_request_det_model.dart';
import '../models/purchase_request_mast_model.dart';
import '../models/user_model.dart';

class ApiService {
  final String _baseUrl =
      "http://195.201.241.253:7001/ords/modern_test/Approval";

  Future<List<UserModel>> getAllUsers() async {
    final response = await http.get(Uri.parse('$_baseUrl/all_emp'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> items = data['items'];
      print("Data is $items");
      List<UserModel> users = [];
      for (var item in items) {
        try {
          log(item.toString());
          users.add(UserModel.fromJson(item));
        } catch (e) {
          log("item at error:${item.toString()}");
          print("❌ Error parsing item: $item");
          print("❌ Error details: $e");
        }
      }

      print("users is $users");
      return users;
    } else {
      throw Exception('Failed to load users');
    }
  }

  Future<void> postLoginData(Map<String, dynamic> loginData) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/ACCESSINFO'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(loginData),
      );
      print('data loginData $loginData');
      if (response.statusCode != 200 && response.statusCode != 201) {
        print('Failed to post login data. Status code: ${response.statusCode}');
        print('Response Body: ${response.body}');
      } else {
        print('Response Body: ${response.body}');
        print('Login activity posted successfully!');
      }
    } catch (e) {
      print('Error posting login data: $e');
    }
  }

  Future<List<FormReportItem>> getFormsAndReports(int userId) async {
    final url = Uri.parse('$_baseUrl/get_form_reports_by_user/$userId');
    print('Fetching forms and reports from: $url');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'];
        log("forms and reports");
        log(items.toString());
        return items.map((item) => FormReportItem.fromJson(item)).toList();
      } else {
        print('Server Error: ${response.statusCode}, Body: ${response.body}');
        throw Exception('serverError');
      }
    } on SocketException {
      print('Network Error: No internet connection.');
      throw Exception('noInternet');
    } on TimeoutException {
      print('Network Error: Request timed out.');
      throw Exception('noInternet');
    } catch (e) {
      print('An unexpected error occurred at fetching forms and reports: $e');
      throw Exception('serverError');
    }
  }

  Future<List<PasswordGroup>> getUserPasswordGroups(int userId) async {
    final url = Uri.parse('$_baseUrl/get_user_password_group/$userId');
    print('Fetching password groups from: $url');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'];
        if (items.isEmpty) return [];
        return items.map((item) => PasswordGroup.fromJson(item)).toList();
      } else {
        print('Server Error: ${response.statusCode}, Body: ${response.body}');
        throw Exception('serverError');
      }
    } on SocketException {
      print('Network Error: No internet connection.');
      throw Exception('noInternet');
    } on TimeoutException {
      print('Network Error: Request timed out.');
      throw Exception('noInternet');
    } catch (e) {
      print('An unexpected error occurred: $e');
      throw Exception('serverError');
    }
  }

  /// Purchase Request calls
  Future<List<PurchaseRequest>> getPurchaseRequests({
    required int userId,
    required int roleId,
    required int passwordNumber,
  }) async {
    final queryParams = {
      'user_id': userId.toString(),
      'password_number': passwordNumber.toString(),
      'role_id': roleId.toString(),
    };
    final url = Uri.parse(
      '$_baseUrl/GET_PUR_REQUEST_AUTH',
    ).replace(queryParameters: queryParams);
    print('Fetching purchase requests from: $url');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'];
        if (items.isEmpty) return [];
        return items.map((item) => PurchaseRequest.fromJson(item)).toList();
      } else {
        print('Server Error: ${response.statusCode}, Body: ${response.body}');
        throw Exception('serverError');
      }
    } on SocketException {
      print('Network Error: No internet connection.');
      throw Exception('noInternet');
    } on TimeoutException {
      print('Network Error: Request timed out.');
      throw Exception('noInternet');
    } catch (e) {
      print('An unexpected error occurred at Pur req: $e');
      throw Exception('serverError');
    }
  }

  Future<List<RequestItem>> getApprovedOrRejectedRequests({
    required int userId,
    required bool isApprove,
  }) async {
    late final url;
    if (isApprove) {
      url = Uri.parse(
        '$_baseUrl/get_last_approve_by_user/${userId.toString()}',
      );
      print('Fetching Approved requests from: $url');
    } else {
      url = Uri.parse('$_baseUrl/get_last_reject_by_user/${userId.toString()}');
      print('Fetching Rejected requests from: $url');
    }
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'];
        if (items.isEmpty) return [];
        return items.map((item) => RequestItem.fromJson(item)).toList();
      } else {
        print('Server Error: ${response.statusCode}, Body: ${response.body}');
        throw Exception('serverError');
      }
    } on SocketException {
      print('Network Error: No internet connection.');
      throw Exception('noInternet');
    } on TimeoutException {
      print('Network Error: Request timed out.');
      throw Exception('noInternet');
    } catch (e) {
      print('An unexpected error occurred: $e');
      throw Exception('serverError');
    }
  }

  Future<PurchaseRequestMaster> getPurchaseRequestMaster({
    required int trnsTypeCode,
    required int trnsSerial,
  }) async {
    final queryParams = {
      'trns_type_code': trnsTypeCode.toString(),
      'trns_serial': trnsSerial.toString(),
    };
    final url = Uri.parse(
      '$_baseUrl/get_pur_request_mast',
    ).replace(queryParameters: queryParams);
    print('Fetching purchase request master from: $url');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'];
        if (items.isEmpty) {
          throw Exception('noData');
        }
        return PurchaseRequestMaster.fromJson(items.first);
      } else {
        print('Server Error: ${response.statusCode}, Body: ${response.body}');
        throw Exception('serverError');
      }
    } on SocketException {
      print('Network Error: No internet connection.');
      throw Exception('noInternet');
    } on TimeoutException {
      print('Network Error: Request timed out.');
      throw Exception('noInternet');
    } catch (e) {
      print('An unexpected error occurred: $e');
      throw Exception('serverError');
    }
  }

  Future<List<PurchaseRequestDetail>> getPurchaseRequestDetail({
    required int trnsTypeCode,
    required int trnsSerial,
  }) async {
    final queryParams = {
      'trns_type_code': trnsTypeCode.toString(),
      'trns_serial': trnsSerial.toString(),
    };
    final url = Uri.parse(
      '$_baseUrl/get_pur_request_det',
    ).replace(queryParameters: queryParams);
    print('Fetching purchase request details from: $url');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'];
        if (items.isEmpty) return [];
        return items
            .map((item) => PurchaseRequestDetail.fromJson(item))
            .toList();
      } else {
        print('Server Error: ${response.statusCode}, Body: ${response.body}');
        throw Exception('serverError');
      }
    } on SocketException {
      print('Network Error: No internet connection.');
      throw Exception('noInternet');
    } on TimeoutException {
      print('Network Error: Request timed out.');
      throw Exception('noInternet');
    } catch (e) {
      print('An unexpected error occurred: $e');
      throw Exception('serverError');
    }
  }

  // --- ✅ --- بداية دوال عملية الاعتماد/الرفض --- ✅ ---

  // دالة مجمعة للتعامل مع الأخطاء
  Future<http.Response> _handleApiCall(
    Future<http.Response> Function() apiCall,
    String stageName,
    String? body,
  ) async {
    try {
      final response = await apiCall().timeout(const Duration(seconds: 30));
      print("✅ $stageName - Success - Status Code: ${response.statusCode}");
      // طباعة الجسم فقط لو مش GET
      if (body != null) {
        print("✅ $stageName - Sent Body: $body");
      }
      print("✅ $stageName - Response Body: ${response.body}");

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw http.ClientException(
          "$stageName Error: Invalid response status code ${response.statusCode} | Body: ${response.body}",
          response.request?.url,
        );
      }
      return response;
    } on SocketException {
      print("❌ $stageName - SocketException: No internet connection.");
      throw Exception('noInternet');
    } on TimeoutException {
      print("❌ $stageName - TimeoutException: Request timed out.");
      throw Exception('noInternet');
    } catch (e) {
      print("❌ $stageName - Unexpected Error: $e");
      // تمرير الخطأ الأصلي لمزيد من التفاصيل
      throw Exception('serverError: $e');
    }
  }

  // --- المرحلة الأولى: GET ---
  Future<ApprovalStatusResponse> stage1_getStatus({
    required int userId,
    required int roleCode,
    required String authPk1,
    required String authPk2,
    required int actualStatus,
    required String approvalType,
    String? authPk3,
  }) async {
    var queryParams;
    if (authPk3 == null) {
      queryParams = {
        'user_id': userId.toString(),
        'role_code': roleCode.toString(),
        'auth_pk1': authPk1,
        'auth_pk2': authPk2,
        'actual_status': actualStatus.toString(),
      };
    } else {
      queryParams = {
        'user_id': userId.toString(),
        'role_code': roleCode.toString(),
        'auth_pk1': authPk1,
        'auth_pk2': authPk2,
        'auth_pk3': authPk3,
        'actual_status': actualStatus.toString(),
      };
    }
    Uri url;
    switch (approvalType) {
      case "pur_request":
        url = Uri.parse(
          '$_baseUrl/UPDATE_PUR_REQUEST_STATUS',
        ).replace(queryParameters: queryParams);
      case "pur_order":
        url = Uri.parse(
          '$_baseUrl/UPDATE_PUR_PO_ORDER_STATUS',
        ).replace(queryParameters: queryParams);
      case "sale_order":
        url = Uri.parse(
          '$_baseUrl/UPDATE_sal_SALES_ORDER_STATUS',
        ).replace(queryParameters: queryParams);
      case "pur_pay":
        url = Uri.parse(
          '$_baseUrl/UPDATE_PUR_PAY_REQUEST_STATUS',
        ).replace(queryParameters: queryParams);
      case "pro_out":
        url = Uri.parse(
          '$_baseUrl/UPDATE_ST_PD_TRNS_OUT_STATUS',
        ).replace(queryParameters: queryParams);
      case "pro_in":
        url = Uri.parse(
          '$_baseUrl/UPDATE_ST_PD_TRNS_IN_STATUS',
        ).replace(queryParameters: queryParams);
      case "inv_issue":
        url = Uri.parse(
          '$_baseUrl/UPDATE_ST_ADJUST_TRNS_OUT_STATUS',
        ).replace(queryParameters: queryParams);
      case "lev_abs":
        url = Uri.parse(
          '$_baseUrl/UPDATE_PY_VCNC_TRNS_STATUS',
        ).replace(queryParameters: queryParams);
      case "mission":
        url = Uri.parse(
          '$_baseUrl/UPDATE_PY_VCNC_TRNS_STATUS',
        ).replace(queryParameters: queryParams);
      case "exit":
        url = Uri.parse(
          '$_baseUrl/UPDATE_PY_EXIT_TRNS_STATUS',
        ).replace(queryParameters: queryParams);
      default:
        //todo update this later on
        url = Uri.parse(
          '$_baseUrl/UPDATE_PUR_REQUEST_STATUS',
        ).replace(queryParameters: queryParams);
    }

    print("--- 🚀 Stage 1 (GET) ---");
    print("🚀 Calling: $url");

    final response = await _handleApiCall(
      () => http.get(url),
      "Stage 1 (GET)",
      null,
    );

    final data = json.decode(response.body);
    log("Stage 1");
    log("URL : ${url.toString()}");
    log("response.body: ${response.body.toString()}");
    log("json decoded.body: ${data.toString()}");
    log("raw response :${response.toString()}");

    if (data['items'] == null || (data['items'] as List).isEmpty) {
      print("❌ Stage 1 (GET) - Error: 'items' array is empty or null.");
      throw Exception('serverError: Empty response from Stage 1');
    }
    return ApprovalStatusResponse.fromJson(data['items'][0]);
  }

  // --- المرحلة الثالثة: PUT (Conditional) ---
  Future<void> stage3_checkLastLevel({
    required int userId,
    required String authPk1,
    required String authPk2,
    String? authPk3,
    required String approvalType,
  }) async {
    Uri url;
    switch (approvalType) {
      case "pur_request":
        url = Uri.parse('$_baseUrl/check_last_level_update');
      case "pur_order":
        url = Uri.parse('$_baseUrl/check_last_level_update_PO_ORDER');
      case "sale_order":
        url = Uri.parse('$_baseUrl/check_last_level_update_SAL_SALES_ORDER');
      case "pur_pay":
        url = Uri.parse('$_baseUrl/CHECK_LAST_LEVEL_UPDATE_PAY_REQUEST');
      case "pro_out":
        url = Uri.parse('$_baseUrl/CHECK_LAST_LEVEL_ST_PD_TRNS_OUT');
      case "pro_in":
        url = Uri.parse('$_baseUrl/CHECK_LAST_LEVEL_ST_PD_TRNS_IN');
      case "inv_issue":
        url = Uri.parse('$_baseUrl/CHECK_LAST_LEVEL_ST_ADJUST_TRNS_OUT');
      case "lev_abs":
        url = Uri.parse('$_baseUrl/CHECK_LAST_LEVEL_UPDATE_VCNC_TRNS');
      case "mission":
        url = Uri.parse('$_baseUrl/CHECK_LAST_LEVEL_UPDATE_VCNC_TRNS');
      case "exit":
        url = Uri.parse('$_baseUrl/CHECK_LAST_ELVEL_UPDATE_EXIT_TRNS');
      default:
        //todo update this later on
        url = Uri.parse('$_baseUrl/check_last_level_update');
    }
    var bodyMap;
    if (authPk3 == null) {
      bodyMap = {"user_id": userId, "auth_pk1": authPk1, "auth_pk2": authPk2};
    } else {
      bodyMap = {
        "user_id": userId,
        "auth_pk1": authPk1,
        "auth_pk2": authPk2,
        "auth_pk3": authPk3,
      };
    }

    final body = json.encode(bodyMap);
    log("Stage 3");
    log("URL : ${url.toString()}");

    final headers = {'Content-Type': 'application/json'};

    print("--- 🚀 Stage 3 (PUT) ---");
    print("🚀 Calling: $url");

    await _handleApiCall(
      () => http.put(url, headers: headers, body: body),
      "Stage 3 (PUT)",
      body,
    );
  }

  // --- المرحلة الرابعة: PUT ---
  Future<void> stage4_updateStatus(
    Map<String, dynamic> bodyMap,
    String approvalType,
  ) async {
    Uri url;
    switch (approvalType) {
      case "pur_request":
        url = Uri.parse('$_baseUrl/UPDATE_PUR_REQUEST_STATUS');
      case "pur_order":
        url = Uri.parse('$_baseUrl/UPDATE_PUR_PO_ORDER_STATUS');
      case "sale_order":
        url = Uri.parse('$_baseUrl/UPDATE_sal_SALES_ORDER_STATUS');
      case "pur_pay":
        url = Uri.parse('$_baseUrl/UPDATE_PUR_PAY_REQUEST_STATUS');
      case "pro_out":
        url = Uri.parse('$_baseUrl/UPDATE_ST_PD_TRNS_OUT_STATUS');
      case "pro_in":
        url = Uri.parse('$_baseUrl/UPDATE_ST_PD_TRNS_IN_STATUS');
      case "inv_issue":
        url = Uri.parse('$_baseUrl/UPDATE_ST_ADJUST_TRNS_OUT_STATUS');
      case "lev_abs":
        url = Uri.parse('$_baseUrl/UPDATE_PY_VCNC_TRNS_STATUS');
      case "mission":
        url = Uri.parse('$_baseUrl/UPDATE_ST_ADJUST_TRNS_OUT_STATUS');
      case "exit":
        url = Uri.parse('$_baseUrl/UPDATE_PY_EXIT_TRNS_STATUS');
      default:
        //todo update this later on
        url = Uri.parse('$_baseUrl/UPDATE_PUR_REQUEST_STATUS');
    }
    final body = json.encode(bodyMap);
    log("Stage 4");
    log("URL : ${url.toString()}");

    final headers = {'Content-Type': 'application/json'};

    print("--- 🚀 Stage 4 (PUT) ---");
    print("🚀 Calling: $url");

    await _handleApiCall(
      () => http.put(url, headers: headers, body: body),
      "Stage 4 (PUT)",
      body,
    );
  }

  // --- المرحلة الخامسة: DELETE ---
  Future<void> stage5_deleteStatus(
    Map<String, dynamic> bodyMap,
    String approvalType,
  ) async {
    Uri url;
    switch (approvalType) {
      case "pur_request":
        url = Uri.parse('$_baseUrl/UPDATE_PUR_REQUEST_STATUS');
      case "pur_order":
        url = Uri.parse('$_baseUrl/UPDATE_PUR_PO_ORDER_STATUS');
      case "sale_order":
        url = Uri.parse('$_baseUrl/UPDATE_sal_SALES_ORDER_STATUS');
      case "pur_pay":
        url = Uri.parse('$_baseUrl/UPDATE_PUR_PAY_REQUEST_STATUS');
      case "pro_out":
        url = Uri.parse('$_baseUrl/UPDATE_ST_PD_TRNS_OUT_STATUS');
      case "pro_in":
        url = Uri.parse('$_baseUrl/UPDATE_ST_PD_TRNS_IN_STATUS');
      case "inv_issue":
        url = Uri.parse('$_baseUrl/UPDATE_ST_ADJUST_TRNS_OUT_STATUS');
      case "lev_abs":
        url = Uri.parse('$_baseUrl/UPDATE_PY_VCNC_TRNS_STATUS');
      case "mission":
        url = Uri.parse('$_baseUrl/UPDATE_ST_ADJUST_TRNS_OUT_STATUS');
      case "exit":
        url = Uri.parse('$_baseUrl/UPDATE_PY_EXIT_TRNS_STATUS');
      default:
        //todo update this later on
        url = Uri.parse('$_baseUrl/UPDATE_PUR_REQUEST_STATUS');
    }
    final body = json.encode(bodyMap);
    log("Stage 5");
    log("URL : ${url.toString()}");

    final headers = {'Content-Type': 'application/json'};

    print("--- 🚀 Stage 5 (DELETE) ---");
    print("🚀 Calling: $url");

    await _handleApiCall(
      () => http.delete(url, headers: headers, body: body),
      "Stage 5 (DELETE)",
      body,
    );
  }

  // --- المرحلة السادسة: POST (Conditional) ---
  Future<void> stage6_postFinalStatus(
    Map<String, dynamic> bodyMap,
    String approvalType,
  ) async {
    Uri url;
    switch (approvalType) {
      case "pur_request":
        url = Uri.parse('$_baseUrl/UPDATE_PUR_REQUEST_STATUS');
      case "pur_order":
        url = Uri.parse('$_baseUrl/UPDATE_PUR_PO_ORDER_STATUS');
      case "sale_order":
        url = Uri.parse('$_baseUrl/UPDATE_sal_SALES_ORDER_STATUS');
      case "pur_pay":
        url = Uri.parse('$_baseUrl/UPDATE_PUR_PAY_REQUEST_STATUS');
      case "pro_out":
        url = Uri.parse('$_baseUrl/UPDATE_ST_PD_TRNS_OUT_STATUS');
      case "pro_in":
        url = Uri.parse('$_baseUrl/UPDATE_ST_PD_TRNS_IN_STATUS');
      case "inv_issue":
        url = Uri.parse('$_baseUrl/UPDATE_ST_ADJUST_TRNS_OUT_STATUS');
      case "lev_abs":
        url = Uri.parse('$_baseUrl/UPDATE_PY_VCNC_TRNS_STATUS');
      case "mission":
        url = Uri.parse('$_baseUrl/UPDATE_ST_ADJUST_TRNS_OUT_STATUS');
      case "exit":
        url = Uri.parse('$_baseUrl/UPDATE_PY_EXIT_TRNS_STATUS');
      default:
        //todo update this later on
        url = Uri.parse('$_baseUrl/UPDATE_PUR_REQUEST_STATUS');
    }
    final body = json.encode(bodyMap);
    log("Stage 6");
    log("URL : ${url.toString()}");
    final headers = {'Content-Type': 'application/json'};

    print("--- 🚀 Stage 6 (POST) ---");
    print("🚀 Calling: $url");

    await _handleApiCall(
      () => http.post(url, headers: headers, body: body),
      "Stage 6 (POST)",
      body,
    );
  }

  Future<DashboardStats> getDashboardStats(int userId) async {
    final url = Uri.parse('$_baseUrl/get_dashboard_variable/$userId');
    print('Fetching dashboard stats from: $url');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'];
        if (items.isEmpty) {
          return DashboardStats(countAuth: 0, countReject: 0);
        }
        return DashboardStats.fromJson(items.first);
      } else {
        print(
          'Server Error fetching stats: ${response.statusCode}, Body: ${response.body}',
        );
        throw Exception('serverError');
      }
    } on SocketException {
      print('Network Error fetching stats: No internet connection.');
      throw Exception('noInternet');
    } on TimeoutException {
      print('Network Error fetching stats: Request timed out.');
      throw Exception('noInternet');
    } catch (e) {
      print('An unexpected error occurred fetching stats: $e');
      throw Exception('serverError');
    }
  }

  /// Purchase order calls
  Future<List<PurchaseOrder>> getPurchaseOrders({
    required int userId,
    required int roleId,
    required int passwordNumber,
  }) async {
    final queryParams = {
      'user_id': userId.toString(),
      'password_number': passwordNumber.toString(),
      'role_id': roleId.toString(),
    };
    final url = Uri.parse(
      '$_baseUrl/get_pur_po_order_auth',
    ).replace(queryParameters: queryParams);
    print('Fetching purchase Orders from: $url');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final List<dynamic> items = data['items'];
        if (items.isEmpty) {
          log("list is empty");
          return [];
        }
        // log(items.toString(),name: "Purchase order Raw");
        return items.map((item) => PurchaseOrder.fromJson(item)).toList();
      } else {
        print('Server Error: ${response.statusCode}, Body: ${response.body}');
        throw Exception('serverError');
      }
    } on SocketException {
      print('Network Error: No internet connection.');
      throw Exception('noInternet');
    } on TimeoutException {
      print('Network Error: Request timed out.');
      throw Exception('noInternet');
    } catch (e) {
      print('An unexpected error occurred at Pur order: $e');
      throw Exception('serverError');
    }
  }

  Future<PurchaseOrderMaster> getPurchaseOrderMaster({
    required int trnsTypeCode,
    required int trnsSerial,
  }) async {
    final queryParams = {
      'trns_type_code': trnsTypeCode.toString(),
      'trns_serial': trnsSerial.toString(),
    };
    final url = Uri.parse(
      '$_baseUrl/get_pur_po_order_mast',
    ).replace(queryParameters: queryParams);
    print('Fetching purchase order master from: $url');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'];
        if (items.isEmpty) {
          throw Exception('noData');
        }
        return PurchaseOrderMaster.fromJson(items.first);
      } else {
        print('Server Error: ${response.statusCode}, Body: ${response.body}');
        throw Exception('serverError');
      }
    } on SocketException {
      print('Network Error: No internet connection.');
      throw Exception('noInternet');
    } on TimeoutException {
      print('Network Error: Request timed out.');
      throw Exception('noInternet');
    } catch (e) {
      print('An unexpected error occurred: $e');
      throw Exception('serverError');
    }
  }

  Future<List<PurchaseOrderDetail>> getPurchaseOrderDetail({
    required int trnsTypeCode,
    required int trnsSerial,
  }) async {
    final queryParams = {
      'trns_type_code': trnsTypeCode.toString(),
      'trns_serial': trnsSerial.toString(),
    };
    final url = Uri.parse(
      '$_baseUrl/get_pur_po_order_det',
    ).replace(queryParameters: queryParams);
    print('Fetching purchase order details from: $url');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'];
        if (items.isEmpty) return [];
        return items.map((item) => PurchaseOrderDetail.fromJson(item)).toList();
      } else {
        print('Server Error: ${response.statusCode}, Body: ${response.body}');
        throw Exception('serverError');
      }
    } on SocketException {
      print('Network Error: No internet connection.');
      throw Exception('noInternet');
    } on TimeoutException {
      print('Network Error: Request timed out.');
      throw Exception('noInternet');
    } catch (e) {
      print('An unexpected error occurred: $e');
      throw Exception('serverError');
    }
  }

  /// Sales order calls
  Future<List<SalesOrder>> getSalesOrders({
    required int userId,
    required int roleId,
    required int passwordNumber,
  }) async {
    final queryParams = {
      'user_id': userId.toString(),
      'password_number': passwordNumber.toString(),
      'role_id': roleId.toString(),
    };
    final url = Uri.parse(
      '$_baseUrl/get_sal_sales_order_auth',
    ).replace(queryParameters: queryParams);
    print('Fetching Sales Orders from: $url');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'];
        if (items.isEmpty) {
          log("list is empty");
          return [];
        }
        return items.map((item) => SalesOrder.fromJson(item)).toList();
      } else {
        print('Server Error: ${response.statusCode}, Body: ${response.body}');
        throw Exception('serverError');
      }
    } on SocketException {
      print('Network Error: No internet connection.');
      throw Exception('noInternet');
    } on TimeoutException {
      print('Network Error: Request timed out.');
      throw Exception('noInternet');
    } catch (e) {
      print('An unexpected error occurred at Sales order: $e');
      throw Exception('serverError');
    }
  }

  Future<SalesOrderMaster> getSalesOrderMaster({
    required int trnsTypeCode,
    required int trnsSerial,
  }) async {
    final queryParams = {
      'trns_type_code': trnsTypeCode.toString(),
      'trns_serial': trnsSerial.toString(),
    };
    final url = Uri.parse(
      '$_baseUrl/GET_SAL_SALES_ORDER_MAST',
    ).replace(queryParameters: queryParams);
    print('Fetching Sales order master from: $url');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'];
        if (items.isEmpty) {
          throw Exception('noData');
        }
        return SalesOrderMaster.fromJson(items.first);
      } else {
        print('Server Error: ${response.statusCode}, Body: ${response.body}');
        throw Exception('serverError');
      }
    } on SocketException {
      print('Network Error: No internet connection.');
      throw Exception('noInternet');
    } on TimeoutException {
      print('Network Error: Request timed out.');
      throw Exception('noInternet');
    } catch (e) {
      print('An unexpected error occurred get sales order master: $e');
      throw Exception('serverError');
    }
  }

  Future<List<SalesOrderDetails>> getSalesOrderDetail({
    required int trnsTypeCode,
    required int trnsSerial,
  }) async {
    final queryParams = {
      'trns_type_code': trnsTypeCode.toString(),
      'trns_serial': trnsSerial.toString(),
    };
    final url = Uri.parse(
      '$_baseUrl/GET_SAL_SALES_ORDER_DET',
    ).replace(queryParameters: queryParams);
    print('Fetching Sales order details from: $url');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'];
        if (items.isEmpty) return [];
        return items.map((item) => SalesOrderDetails.fromJson(item)).toList();
      } else {
        print('Server Error: ${response.statusCode}, Body: ${response.body}');
        throw Exception('serverError');
      }
    } on SocketException {
      print('Network Error: No internet connection.');
      throw Exception('noInternet');
    } on TimeoutException {
      print('Network Error: Request timed out.');
      throw Exception('noInternet');
    } catch (e) {
      print('An unexpected error occurred get sales order details: $e');
      throw Exception('serverError');
    }
  }

  /// Purchase Pay
  Future<List<PurchasePay>> getPurchasePay({
    required int userId,
    required int roleId,
    required int passwordNumber,
  }) async {
    final queryParams = {
      'user_id': userId.toString(),
      'password_number': passwordNumber.toString(),
      'role_id': roleId.toString(),
    };
    final url = Uri.parse(
      '$_baseUrl/GET_PUR_PAY_REQUEST_AUTH',
    ).replace(queryParameters: queryParams);
    print('Fetching purchase Pay Requests from: $url');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final List<dynamic> items = data['items'];
        if (items.isEmpty) {
          log("list is empty");
          return [];
        }
        return items.map((item) => PurchasePay.fromJson(item)).toList();
      } else {
        print('Server Error: ${response.statusCode}, Body: ${response.body}');
        throw Exception('serverError');
      }
    } on SocketException {
      print('Network Error: No internet connection.');
      throw Exception('noInternet');
    } on TimeoutException {
      print('Network Error: Request timed out.');
      throw Exception('noInternet');
    } catch (e) {
      print('An unexpected error occurred at Pur Pay: $e');
      throw Exception('serverError');
    }
  }

  Future<PurchasePayMaster> getPurchasePayMaster({
    required int trnsTypeCode,
    required int trnsSerial,
  }) async {
    final queryParams = {
      'trns_type_code': trnsTypeCode.toString(),
      'trns_serial': trnsSerial.toString(),
    };
    final url = Uri.parse(
      '$_baseUrl/GET_PUR_PAY_REQUEST_MAST',
    ).replace(queryParameters: queryParams);
    print('Fetching Purchase pay master from: $url');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        log("status code = 200");
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'];
        if (items.isEmpty) {
          throw Exception('noData');
        }
        log(items.toString());
        return PurchasePayMaster.fromJson(items.first);
      } else {
        print('Server Error: ${response.statusCode}, Body: ${response.body}');
        throw Exception('serverError');
      }
    } on SocketException {
      print('Network Error: No internet connection.');
      throw Exception('noInternet');
    } on TimeoutException {
      print('Network Error: Request timed out.');
      throw Exception('noInternet');
    } catch (e) {
      print('An unexpected error occurred get purchase pay master: $e');
      throw Exception('serverError');
    }
  }

  Future<List<PurchasePayDetail>> getPurchasePayDetail({
    required int trnsTypeCode,
    required int trnsSerial,
  }) async {
    final queryParams = {
      'trns_type_code': trnsTypeCode.toString(),
      'trns_serial': trnsSerial.toString(),
    };
    final url = Uri.parse(
      '$_baseUrl/GET_PUR_PAY_REQUEST_DET',
    ).replace(queryParameters: queryParams);
    print('Fetching purchase Pay details from: $url');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'];
        if (items.isEmpty) return [];
        return items.map((item) => PurchasePayDetail.fromJson(item)).toList();
      } else {
        print('Server Error: ${response.statusCode}, Body: ${response.body}');
        throw Exception('serverError');
      }
    } on SocketException {
      print('Network Error: No internet connection.');
      throw Exception('noInternet');
    } on TimeoutException {
      print('Network Error: Request timed out.');
      throw Exception('noInternet');
    } catch (e) {
      print('An unexpected error occurred at purchase pay: $e');
      throw Exception('serverError');
    }
  }

  /// Production Outbound
  Future<List<ProductionOutbound>> getProductionOutbound({
    required int userId,
    required int roleId,
    required int passwordNumber,
  }) async {
    final queryParams = {
      'user_id': userId.toString(),
      'password_number': passwordNumber.toString(),
      'role_id': roleId.toString(),
    };
    final url = Uri.parse(
      '$_baseUrl/GET_ST_PD_TRNS_OUT_AUTH',
    ).replace(queryParameters: queryParams);
    print('Fetching Production outbound Requests from: $url');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final List<dynamic> items = data['items'];
        if (items.isEmpty) {
          log("list is empty");
          return [];
        }
        return items.map((item) => ProductionOutbound.fromJson(item)).toList();
      } else {
        print('Server Error: ${response.statusCode}, Body: ${response.body}');
        throw Exception('serverError');
      }
    } on SocketException {
      print('Network Error: No internet connection.');
      throw Exception('noInternet');
    } on TimeoutException {
      print('Network Error: Request timed out.');
      throw Exception('noInternet');
    } catch (e) {
      print('An unexpected error occurred at Pro outbound: $e');
      throw Exception('serverError');
    }
  }

  Future<ProductionOutboundMaster> getProductionOutboundMaster({
    required int trnsTypeCode,
    required int trnsSerial,
  }) async {
    final queryParams = {
      'trns_type_code': trnsTypeCode.toString(),
      'trns_serial': trnsSerial.toString(),
    };
    final url = Uri.parse(
      '$_baseUrl/GET_ST_PD_TRNS_OUT_MAST',
    ).replace(queryParameters: queryParams);
    print('Fetching production outbound master from: $url');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        log("status code = 200");
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'];
        if (items.isEmpty) {
          throw Exception('noData');
        }
        log(items.toString());
        return ProductionOutboundMaster.fromJson(items.first);
      } else {
        print('Server Error: ${response.statusCode}, Body: ${response.body}');
        throw Exception('serverError');
      }
    } on SocketException {
      print('Network Error: No internet connection.');
      throw Exception('noInternet');
    } on TimeoutException {
      print('Network Error: Request timed out.');
      throw Exception('noInternet');
    } catch (e) {
      print('An unexpected error occurred get production outbound master: $e');
      throw Exception('serverError');
    }
  }

  Future<List<ProductionOutboundDetail>> getProductionOutboundDetail({
    required int trnsTypeCode,
    required int trnsSerial,
  }) async {
    final queryParams = {
      'trns_type_code': trnsTypeCode.toString(),
      'trns_serial': trnsSerial.toString(),
    };
    final url = Uri.parse(
      '$_baseUrl/GET_ST_PD_TRNS_OUT_DET',
    ).replace(queryParameters: queryParams);
    print('Fetching production outbound details from: $url');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'];
        if (items.isEmpty) return [];
        return items
            .map((item) => ProductionOutboundDetail.fromJson(item))
            .toList();
      } else {
        print('Server Error: ${response.statusCode}, Body: ${response.body}');
        throw Exception('serverError');
      }
    } on SocketException {
      print('Network Error: No internet connection.');
      throw Exception('noInternet');
    } on TimeoutException {
      print('Network Error: Request timed out.');
      throw Exception('noInternet');
    } catch (e) {
      print('An unexpected error occurred at production outbound detail: $e');
      throw Exception('serverError');
    }
  }

  /// Production Inbound

  Future<List<Item>> getProductionInbound({
    required int userId,
    required int roleId,
    required int passwordNumber,
  }) async {
    final queryParams = {
      'user_id': userId.toString(),
      'password_number': passwordNumber.toString(),
      'role_id': roleId.toString(),
    };
    final url = Uri.parse(
      '$_baseUrl/GET_ST_PD_TRNS_IN_AUTH',
    ).replace(queryParameters: queryParams);
    print('Fetching Production inbound Requests from: $url');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final List<dynamic> items = data['items'];
        if (items.isEmpty) {
          log("list is empty");
          return [];
        }
        return items.map((item) => Item.fromJson(item)).toList();
      } else {
        print('Server Error: ${response.statusCode}, Body: ${response.body}');
        throw Exception('serverError');
      }
    } on SocketException {
      print('Network Error: No internet connection.');
      throw Exception('noInternet');
    } on TimeoutException {
      print('Network Error: Request timed out.');
      throw Exception('noInternet');
    } catch (e) {
      print('An unexpected error occurred at Pro outbound: $e');
      throw Exception('serverError');
    }
  }

  Future<MasterItem> getProductionInboundMaster({
    required int trnsTypeCode,
    required int trnsSerial,
  }) async {
    final queryParams = {
      'trns_type_code': trnsTypeCode.toString(),
      'trns_serial': trnsSerial.toString(),
    };
    final url = Uri.parse(
      '$_baseUrl/GET_ST_PD_TRNS_IN_MAST',
    ).replace(queryParameters: queryParams);
    print('Fetching production inbound master from: $url');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        log("status code = 200");
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'];
        if (items.isEmpty) {
          throw Exception('noData');
        }
        log(items.toString());
        return MasterItem.fromJson(items.first);
      } else {
        print('Server Error: ${response.statusCode}, Body: ${response.body}');
        throw Exception('serverError');
      }
    } on SocketException {
      print('Network Error: No internet connection.');
      throw Exception('noInternet');
    } on TimeoutException {
      print('Network Error: Request timed out.');
      throw Exception('noInternet');
    } catch (e) {
      print('An unexpected error occurred get production inbound master: $e');
      throw Exception('serverError');
    }
  }

  Future<List<DetailsItem>> getProductionInboundDetail({
    required int trnsTypeCode,
    required int trnsSerial,
  }) async {
    final queryParams = {
      'trns_type_code': trnsTypeCode.toString(),
      'trns_serial': trnsSerial.toString(),
    };
    final url = Uri.parse(
      '$_baseUrl/GET_ST_PD_TRNS_IN_DET',
    ).replace(queryParameters: queryParams);
    print('Fetching production inbound details from: $url');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'];
        log(items.toString());
        if (items.isEmpty) return [];
        return items.map((item) => DetailsItem.fromJson(item)).toList();
      } else {
        print('Server Error: ${response.statusCode}, Body: ${response.body}');
        throw Exception('serverError');
      }
    } on SocketException {
      print('Network Error: No internet connection.');
      throw Exception('noInternet');
    } on TimeoutException {
      print('Network Error: Request timed out.');
      throw Exception('noInternet');
    } catch (e) {
      print('An unexpected error occurred at production inbound detail: $e');
      throw Exception('serverError');
    }
  }

  /// Leave and Absence
  Future<List<LeaveAndAbsence>> getLeaveAndAbsence({
    required int userId,
    required int roleId,
    required int passwordNumber,
  }) async {
    final queryParams = {
      'user_id': userId.toString(),
      'password_number': passwordNumber.toString(),
      'role_id': roleId.toString(),
    };
    final url = Uri.parse(
      '$_baseUrl/GET_PY_VCNC_TRNS_AUTH',
    ).replace(queryParameters: queryParams);
    print('Fetching Leave and Absence Requests from: $url');
    try {
      final response = await http
          .get(url)
          .timeout(const Duration(seconds: 120));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final List<dynamic> items = data['items'];
        if (items.isEmpty) {
          log("list is empty");
          return [];
        }
        return items.map((item) => LeaveAndAbsence.fromJson(item)).toList();
      } else {
        print('Server Error: ${response.statusCode}, Body: ${response.body}');
        throw Exception('serverError');
      }
    } on SocketException {
      print('Network Error: No internet connection.');
      throw Exception('noInternet');
    } on TimeoutException {
      print('Network Error: Request timed out.');
      throw Exception('noInternet');
    } catch (e) {
      print('An unexpected error occurred at Leave and Absence: $e');
      throw Exception('serverError');
    }
  }

  /// Inventory Issue

  Future<List<InventoryIssue>> getInventoryIssue({
    required int userId,
    required int roleId,
    required int passwordNumber,
  }) async {
    final queryParams = {
      'user_id': userId.toString(),
      'password_number': passwordNumber.toString(),
      'role_id': roleId.toString(),
    };
    final url = Uri.parse(
      '$_baseUrl/GET_ST_ADJUST_TRNS_OUT_AUTH',
    ).replace(queryParameters: queryParams);
    print('Fetching Inventory issue Requests from: $url');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final List<dynamic> items = data['items'];
        if (items.isEmpty) {
          log("list is empty");
          return [];
        }
        return items.map((item) => InventoryIssue.fromJson(item)).toList();
      } else {
        print('Server Error: ${response.statusCode}, Body: ${response.body}');
        throw Exception('serverError');
      }
    } on SocketException {
      print('Network Error: No internet connection.');
      throw Exception('noInternet');
    } on TimeoutException {
      print('Network Error: Request timed out.');
      throw Exception('noInternet');
    } catch (e) {
      print('An unexpected error occurred at Inventory issue: $e');
      throw Exception('serverError');
    }
  }

  Future<InventoryIssueMasterItem> getInventoryIssueMaster({
    required int trnsTypeCode,
    required int trnsSerial,
  }) async {
    final queryParams = {
      'trns_type_code': trnsTypeCode.toString(),
      'trns_serial': trnsSerial.toString(),
    };
    final url = Uri.parse(
      '$_baseUrl/GET_ST_ADJUST_TRNS_OUT_MAST',
    ).replace(queryParameters: queryParams);
    print('Fetching Inventory issue master from: $url');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        log("status code = 200");
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'];
        if (items.isEmpty) {
          throw Exception('noData');
        }
        log(items.toString());
        return InventoryIssueMasterItem.fromJson(items.first);
      } else {
        print('Server Error: ${response.statusCode}, Body: ${response.body}');
        throw Exception('serverError');
      }
    } on SocketException {
      print('Network Error: No internet connection.');
      throw Exception('noInternet');
    } on TimeoutException {
      print('Network Error: Request timed out.');
      throw Exception('noInternet');
    } catch (e) {
      print('An unexpected error occurred get Inventory issue master: $e');
      throw Exception('serverError');
    }
  }

  Future<List<InventoryIssueDetailsItem>> getInventoryIssueDetail({
    required int trnsTypeCode,
    required int trnsSerial,
  }) async {
    final queryParams = {
      'trns_type_code': trnsTypeCode.toString(),
      'trns_serial': trnsSerial.toString(),
    };
    final url = Uri.parse(
      '$_baseUrl/GET_ST_ADJUST_TRNS_OUT_DET',
    ).replace(queryParameters: queryParams);
    print('Fetching Inventory issue details from: $url');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'];
        log(items.toString());
        if (items.isEmpty) return [];
        return items
            .map((item) => InventoryIssueDetailsItem.fromJson(item))
            .toList();
      } else {
        print('Server Error: ${response.statusCode}, Body: ${response.body}');
        throw Exception('serverError');
      }
    } on SocketException {
      print('Network Error: No internet connection.');
      throw Exception('noInternet');
    } on TimeoutException {
      print('Network Error: Request timed out.');
      throw Exception('noInternet');
    } catch (e) {
      print('An unexpected error occurred at Inventory issue detail: $e');
      throw Exception('serverError');
    }
  }

  /// mission
  Future<List<InventoryIssue>> getMission({
    required int userId,
    required int roleId,
    required int passwordNumber,
  }) async {
    final queryParams = {
      'user_id': userId.toString(),
      'password_number': passwordNumber.toString(),
      'role_id': roleId.toString(),
    };
    final url = Uri.parse(
      '$_baseUrl/GET_ST_ADJUST_TRNS_OUT_AUTH',
    ).replace(queryParameters: queryParams);
    print('Fetching Inventory issue Requests from: $url');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final List<dynamic> items = data['items'];
        if (items.isEmpty) {
          log("list is empty");
          return [];
        }
        return items.map((item) => InventoryIssue.fromJson(item)).toList();
      } else {
        print('Server Error: ${response.statusCode}, Body: ${response.body}');
        throw Exception('serverError');
      }
    } on SocketException {
      print('Network Error: No internet connection.');
      throw Exception('noInternet');
    } on TimeoutException {
      print('Network Error: Request timed out.');
      throw Exception('noInternet');
    } catch (e) {
      print('An unexpected error occurred at Inventory issue: $e');
      throw Exception('serverError');
    }
  }

  /// Exit Permissions
  Future<List<ExitPermission>> getExitPermissions({
    required int userId,
    required int roleId,
    required int passwordNumber,
  }) async {
    final queryParams = {
      'user_id': userId.toString(),
      'password_number': passwordNumber.toString(),
      'role_id': roleId.toString(),
    };
    final url = Uri.parse(
      '$_baseUrl/GET_PY_EXIT_TRNS_AUTH',
    ).replace(queryParameters: queryParams);
    print('Fetching Exit Permissions from: $url');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final List<dynamic> items = data['items'];
        if (items.isEmpty) {
          log("list is empty");
          return [];
        }
        return items.map((item) => ExitPermission.fromJson(item)).toList();
      } else {
        print('Server Error: ${response.statusCode}, Body: ${response.body}');
        throw Exception('serverError');
      }
    } on SocketException {
      print('Network Error: No internet connection.');
      throw Exception('noInternet');
    } on TimeoutException {
      print('Network Error: Request timed out.');
      throw Exception('noInternet');
    } catch (e) {
      print('An unexpected error occurred at Exit Permission: $e');
      throw Exception('serverError');
    }
  }
}
