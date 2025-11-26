import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:modernapproval/models/password_group_model.dart';
import 'package:modernapproval/screens/approvals/inventory_issue_approval/inventory_issue_approval_screen.dart';
import 'package:modernapproval/screens/approvals/leave_and_absence_approval/leave_and_absence_approval_screen.dart';
import 'package:modernapproval/screens/approvals/production_inbound_approval/production_inbound_approval_screen.dart';
import 'package:modernapproval/screens/approvals/production_outbound/production_outbound_approval_screen.dart';
import 'package:modernapproval/screens/approvals/purchase_order_approval/purchase_order_approval_screen.dart';
import 'package:modernapproval/screens/approvals/purchase_pay_approval/purchase_pay_approval_screen.dart';
import 'package:modernapproval/screens/approvals/purchase_request_approval/purchase_request_approval_screen.dart';
import 'package:modernapproval/screens/approvals/sales_order_approval/sales_order_approval_screen.dart';
import '../../app_localizations.dart';
import '../../custom_icon/custom_icon_icons.dart';
import '../../models/form_report_model.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../widgets/action_card.dart';
import '../../widgets/error_display.dart';
import '../../main.dart';

class ApprovalsScreen extends StatefulWidget {
  final UserModel user;

  const ApprovalsScreen({super.key, required this.user});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  late Future<List<FormReportItem>> _approvalsFuture;
  late Future<List<PasswordGroup>> _passwordGroupsFuture;
  PasswordGroup? _selectedPasswordGroup;
  final ApiService _apiService = ApiService();

  final Map<int, int> _approvalCounts = {};
  bool _isCountLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    _passwordGroupsFuture = _apiService.getUserPasswordGroups(
      widget.user.usersCode,
    );
    _passwordGroupsFuture
        .then((groups) {
          if (groups.isNotEmpty) {
            if (!mounted) return;
            setState(() {
              _selectedPasswordGroup = groups.firstWhere(
                (g) => g.isDefault,
                orElse: () => groups.first,
              );
              _fetchAndSetPurchaseRequestCount();
              _fetchAndSetPurchaseOrderCount();
              _fetchAndSetSalesOrderCount();
              _fetchAndSetPurchasePayCount();
              _fetchAndSetProductionOutboundCount();
              _fetchAndSetProductionInboundCount();
              _fetchAndSetInventoryIssueCount();
              _fetchAndSetLeaveAndAbsenceCount();
              _fetchAndSetMissionCount();
              _fetchAndSetExitCount();
            });
          }
        })
        .catchError((e) {
          print("Error fetching password groups: $e");
        });

    _approvalsFuture = _fetchAndProcessApprovals();
  }

  Future<void> _refreshCounts() async {
    await _fetchAndSetPurchaseRequestCount();
    await _fetchAndSetPurchaseOrderCount();
    await _fetchAndSetSalesOrderCount();
    await _fetchAndSetPurchasePayCount();
    await _fetchAndSetProductionOutboundCount();
    await _fetchAndSetProductionInboundCount();
    await _fetchAndSetInventoryIssueCount();
    await _fetchAndSetLeaveAndAbsenceCount();
    await _fetchAndSetMissionCount();
    await _fetchAndSetExitCount();
  }

  Future<void> _fetchAndSetPurchaseRequestCount() async {
    if (_selectedPasswordGroup == null) return;
    if (!mounted) return;

    setState(() {
      _isCountLoading = true;
    });

    try {
      final requests = await _apiService.getPurchaseRequests(
        userId: widget.user.usersCode,
        roleId: widget.user.roleCode!,
        passwordNumber: _selectedPasswordGroup!.passwordNumber,
      );
      _approvalCounts[101] = requests.length;
    } catch (e) {
      print("Error fetching purchase request count: $e");
      _approvalCounts[101] = 0;
    } finally {
      if (mounted) {
        setState(() {
          _isCountLoading = false;
        });
      }
    }
  }

  Future<void> _fetchAndSetPurchaseOrderCount() async {
    if (_selectedPasswordGroup == null) return;
    if (!mounted) return;

    setState(() {
      _isCountLoading = true;
    });

    try {
      final requests = await _apiService.getPurchaseOrders(
        userId: widget.user.usersCode,
        roleId: widget.user.roleCode!,
        passwordNumber: _selectedPasswordGroup!.passwordNumber,
      );
      _approvalCounts[102] = requests.length;
    } catch (e) {
      print("Error fetching purchase request count: $e");
      _approvalCounts[102] = 0;
    } finally {
      if (mounted) {
        setState(() {
          _isCountLoading = false;
        });
      }
    }
  }

  Future<void> _fetchAndSetSalesOrderCount() async {
    if (_selectedPasswordGroup == null) return;
    if (!mounted) return;

    setState(() {
      _isCountLoading = true;
    });

    try {
      final requests = await _apiService.getSalesOrders(
        userId: widget.user.usersCode,
        roleId: widget.user.roleCode!,
        passwordNumber: _selectedPasswordGroup!.passwordNumber,
      );
      _approvalCounts[108] = requests.length;
    } catch (e) {
      print("Error fetching purchase request count: $e");
      _approvalCounts[108] = 0;
    } finally {
      if (mounted) {
        setState(() {
          _isCountLoading = false;
        });
      }
    }
  }

  Future<void> _fetchAndSetPurchasePayCount() async {
    if (_selectedPasswordGroup == null) return;
    if (!mounted) return;

    setState(() {
      _isCountLoading = true;
    });

    try {
      final requests = await _apiService.getPurchasePay(
        userId: widget.user.usersCode,
        roleId: widget.user.roleCode!,
        passwordNumber: _selectedPasswordGroup!.passwordNumber,
      );
      _approvalCounts[111] = requests.length;
    } catch (e) {
      print("Error fetching purchase pay count: $e");
      _approvalCounts[111] = 0;
    } finally {
      if (mounted) {
        setState(() {
          _isCountLoading = false;
        });
      }
    }
  }

  Future<void> _fetchAndSetProductionOutboundCount() async {
    if (_selectedPasswordGroup == null) return;
    if (!mounted) return;

    setState(() {
      _isCountLoading = true;
    });

    try {
      final requests = await _apiService.getProductionOutbound(
        userId: widget.user.usersCode,
        roleId: widget.user.roleCode!,
        passwordNumber: _selectedPasswordGroup!.passwordNumber,
      );
      _approvalCounts[105] = requests.length;
    } catch (e) {
      print("Error fetching Production outbound count: $e");
      _approvalCounts[105] = 0;
    } finally {
      if (mounted) {
        setState(() {
          _isCountLoading = false;
        });
      }
    }
  }

  Future<void> _fetchAndSetProductionInboundCount() async {
    if (_selectedPasswordGroup == null) return;
    if (!mounted) return;

    setState(() {
      _isCountLoading = true;
    });

    try {
      final requests = await _apiService.getProductionInbound(
        userId: widget.user.usersCode,
        roleId: widget.user.roleCode!,
        passwordNumber: _selectedPasswordGroup!.passwordNumber,
      );
      _approvalCounts[106] = requests.length;
    } catch (e) {
      print("Error fetching Production inbound count: $e");
      _approvalCounts[106] = 0;
    } finally {
      if (mounted) {
        setState(() {
          _isCountLoading = false;
        });
      }
    }
  }

  Future<void> _fetchAndSetInventoryIssueCount() async {
    if (_selectedPasswordGroup == null) return;
    if (!mounted) return;

    setState(() {
      _isCountLoading = true;
    });

    try {
      final requests = await _apiService.getInventoryIssue(
        userId: widget.user.usersCode,
        roleId: widget.user.roleCode!,
        passwordNumber: _selectedPasswordGroup!.passwordNumber,
      );
      _approvalCounts[104] = requests.length;
    } catch (e) {
      print("Error fetching Inventory issue count: $e");
      _approvalCounts[104] = 0;
    } finally {
      if (mounted) {
        setState(() {
          _isCountLoading = false;
        });
      }
    }
  }

  Future<void> _fetchAndSetLeaveAndAbsenceCount() async {
    if (_selectedPasswordGroup == null) return;
    if (!mounted) return;

    setState(() {
      _isCountLoading = true;
    });

    try {
      final requests = await _apiService.getLeaveAndAbsence(
        userId: widget.user.usersCode,
        roleId: widget.user.roleCode!,
        passwordNumber: _selectedPasswordGroup!.passwordNumber,
      );
      _approvalCounts[109] = requests.length;
    } catch (e) {
      print("Error fetching Leave and Absence count: $e");
      _approvalCounts[109] = 0;
    } finally {
      if (mounted) {
        setState(() {
          _isCountLoading = false;
        });
      }
    }
  }

  //todo change this to mission
  Future<void> _fetchAndSetMissionCount() async {
    if (_selectedPasswordGroup == null) return;
    if (!mounted) return;

    setState(() {
      _isCountLoading = true;
    });

    try {
      final requests = await _apiService.getLeaveAndAbsence(
        userId: widget.user.usersCode,
        roleId: widget.user.roleCode!,
        passwordNumber: _selectedPasswordGroup!.passwordNumber,
      );
      _approvalCounts[109] = requests.length;
    } catch (e) {
      print("Error fetching Leave and Absence count: $e");
      _approvalCounts[109] = 0;
    } finally {
      if (mounted) {
        setState(() {
          _isCountLoading = false;
        });
      }
    }
  }

  //todo change this to exit
  Future<void> _fetchAndSetExitCount() async {
    if (_selectedPasswordGroup == null) return;
    if (!mounted) return;

    setState(() {
      _isCountLoading = true;
    });

    try {
      final requests = await _apiService.getLeaveAndAbsence(
        userId: widget.user.usersCode,
        roleId: widget.user.roleCode!,
        passwordNumber: _selectedPasswordGroup!.passwordNumber,
      );
      _approvalCounts[109] = requests.length;
    } catch (e) {
      print("Error fetching Leave and Absence count: $e");
      _approvalCounts[109] = 0;
    } finally {
      if (mounted) {
        setState(() {
          _isCountLoading = false;
        });
      }
    }
  }

  Future<List<FormReportItem>> _fetchAndProcessApprovals() async {
    final items = await _apiService.getFormsAndReports(widget.user.usersCode);
    final approvals = items.where((item) => item.type == 'F').toList();
    approvals.sort((a, b) => a.ord.compareTo(b.ord));
    return approvals;
  }

  void _fetchData() {
    setState(() {
      _approvalsFuture = _fetchAndProcessApprovals();
    });
  }

  void _handleNavigation(FormReportItem item) async {
    if (_selectedPasswordGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('noPasswordGroups'),
          ),
        ),
      );
      return;
    }
    log("FormReportItem");
    log(item.toJson().toString(), name: "FormReportItem");
    log(_selectedPasswordGroup!.usersCode.toString(), name: "SG:userCode");
    log(_selectedPasswordGroup!.passwordName.toString(), name: "SG:pwName");
    log(_selectedPasswordGroup!.passwordNumber.toString(), name: "SG:pwNum");
    log(_selectedPasswordGroup!.isDefault.toString(), name: "SG:isDefault");

    switch (item.pageId) {
      case 101:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => PurchaseRequestApprovalScreen(
                  user: widget.user,
                  selectedPasswordNumber:
                      _selectedPasswordGroup!.passwordNumber,
                ),
          ),
        );
        if (mounted) {
          _refreshCounts();
        }
      case 102:
        log("entering order approval");
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => PurchaseOrderApprovalScreen(
                  user: widget.user,
                  selectedPasswordNumber:
                      _selectedPasswordGroup!.passwordNumber,
                ),
          ),
        );
        if (mounted) {
          _refreshCounts();
        }
      case 105:
        log("entering Production outbound approval");
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ProductionOutboundApprovalScreen(
                  user: widget.user,
                  selectedPasswordNumber:
                      _selectedPasswordGroup!.passwordNumber,
                ),
          ),
        );
        if (mounted) {
          _refreshCounts();
        }
      case 106:
        log("entering Production inbound approval");
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ProductionInboundApprovalScreen(
                  user: widget.user,
                  selectedPasswordNumber:
                      _selectedPasswordGroup!.passwordNumber,
                ),
          ),
        );
        if (mounted) {
          _refreshCounts();
        }
      case 104:
        log("entering Inventory issue approval");
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => InventoryIssueApprovalScreen(
                  user: widget.user,
                  selectedPasswordNumber:
                      _selectedPasswordGroup!.passwordNumber,
                ),
          ),
        );
        if (mounted) {
          _refreshCounts();
        }
      case 108:
        log("entering Sales order approval");
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => SalesOrderApprovalScreen(
                  user: widget.user,
                  selectedPasswordNumber:
                      _selectedPasswordGroup!.passwordNumber,
                ),
          ),
        );
        if (mounted) {
          _refreshCounts();
        }
      case 109:
        log("entering Leave and Absence approval");
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => LeaveAndAbsenceApprovalScreen(
                  user: widget.user,
                  selectedPasswordNumber:
                      _selectedPasswordGroup!.passwordNumber,
                ),
          ),
        );
        if (mounted) {
          _refreshCounts();
        }
      case 111:
        log("entering Purchase pay approval");
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => PurchasePayApprovalScreen(
                  user: widget.user,
                  selectedPasswordNumber:
                      _selectedPasswordGroup!.passwordNumber,
                ),
          ),
        );
        if (mounted) {
          _refreshCounts();
        }
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Work in progress for: ${item.pageNameE}')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      appBar: _buildAppBar(context, isArabic),
      bottomNavigationBar: _buildSelectedGroupFooter(l, isArabic),
      body: FutureBuilder<List<FormReportItem>>(
        future: _approvalsFuture,
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
              onRetry: _fetchData,
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(l.translate('noData')));
          }
          final approvals = snapshot.data!;
          // log("approvals length");
          // log(approvals.length.toString());
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            itemCount: approvals.length,
            itemBuilder: (context, index) {
              final item = approvals[index];
              final colors = _getColorsForItem(item.pageId);

              ///this map each feature the use have , the key is pageID given from backend
              ///the value is the number of available items"approvals" inside that feature
              log("_approvalCounts");
              log(_approvalCounts.toString(), name: "approval count");
              log(
                _approvalCounts[item.pageId].toString(),
                name: "fetching if the number of approval user have",
              );

              return ActionCard(
                title: isArabic ? item.pageName : item.pageNameE,
                icon: _getIconForItem(item.pageId),
                iconColor: colors['icon']!,
                backgroundColor: colors['background']!,
                onTap: () => _handleNavigation(item),
                notificationCount: _approvalCounts[item.pageId] ?? null,
                isCountLoading:
                    (item.pageId == 101 ||
                        item.pageId == 102 ||
                        item.pageId == 108 ||
                        item.pageId == 111 ||
                        item.pageId == 105 ||
                        item.pageId == 106 ||
                        item.pageId == 109 ||
                        item.pageId == 104) &&
                    _isCountLoading,
              );
            },
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isArabic) {
    return AppBar(
      backgroundColor: const Color(0xFF6C63FF),
      elevation: 2,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        isArabic ? 'الموافقات' : 'Approvals',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Cairo',
          letterSpacing: 0.5,
        ),
      ),
      actions: [
        _buildPasswordGroupDropdown(isArabic),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.language, color: Colors.white, size: 24),
          tooltip: isArabic ? 'تغيير اللغة' : 'Change Language',
          onPressed: () {
            final myAppState = MyApp.of(context);
            if (myAppState != null) {
              myAppState.changeLanguage(
                isArabic ? const Locale('en', '') : const Locale('ar', ''),
              );
            }
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSelectedGroupFooter(AppLocalizations l, bool isArabic) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.store, color: Color(0xFF6C63FF), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _selectedPasswordGroup != null
                  ? "${l.translate('selectedBranch')}: ${_selectedPasswordGroup!.passwordName}"
                  : l.translate('noPasswordGroups'),
              style: const TextStyle(
                color: Color(0xFF2C3E50),
                fontWeight: FontWeight.w600,
                fontSize: 13,
                fontFamily: 'Cairo',
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: isArabic ? TextAlign.right : TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordGroupDropdown(bool isArabic) {
    return FutureBuilder<List<PasswordGroup>>(
      future: _passwordGroupsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: Icon(Icons.error_outline, color: Colors.white70, size: 22),
          );
        }
        final groups = snapshot.data!;
        if (_selectedPasswordGroup != null &&
            !groups.any(
              (g) => g.passwordNumber == _selectedPasswordGroup!.passwordNumber,
            )) {
          _selectedPasswordGroup = groups.first;
        }

        return PopupMenuButton<PasswordGroup>(
          onSelected: (PasswordGroup newValue) {
            setState(() {
              _selectedPasswordGroup = newValue;
              _fetchAndSetPurchaseRequestCount();
              _fetchAndSetPurchaseOrderCount();
              _fetchAndSetSalesOrderCount();
              _fetchAndSetPurchasePayCount();
              _fetchAndSetProductionOutboundCount();
              _fetchAndSetProductionInboundCount();
              _fetchAndSetInventoryIssueCount();
              _fetchAndSetLeaveAndAbsenceCount();
              _fetchAndSetMissionCount();
              _fetchAndSetExitCount();
            });
          },
          offset: const Offset(0, 48),
          color: const Color(0xFF5850E6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          icon: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.store_mall_directory, color: Colors.white, size: 20),
              SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
            ],
          ),
          itemBuilder: (BuildContext context) {
            return groups.map((PasswordGroup group) {
              final isSelected =
                  _selectedPasswordGroup?.passwordNumber ==
                  group.passwordNumber;
              return PopupMenuItem<PasswordGroup>(
                value: group,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? Colors.white.withOpacity(0.1)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color:
                              isSelected ? Colors.greenAccent : Colors.white54,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          group.passwordName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight:
                                isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check,
                          color: Colors.greenAccent,
                          size: 18,
                        ),
                    ],
                  ),
                ),
              );
            }).toList();
          },
        );
      },
    );
  }

  IconData _getIconForItem(int pageId) {
    switch (pageId) {
      case 101:
        return CustomIcon.pa1;
      case 102:
        return Icons.local_shipping_outlined;
      case 103:
        return Icons.attach_money;
      case 104:
        return Icons.inventory_2_outlined;
      case 105:
        return Icons.output_outlined;
      case 106:
        return Icons.input_outlined;
      case 107:
        return Icons.receipt_long_outlined;
      case 108:
        return Icons.point_of_sale;
      case 109:
        return Icons.event_busy_outlined;
      case 110:
        return Icons.badge_outlined;
      case 111:
        return Icons.payments_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  Map<String, Color> _getColorsForItem(int pageId) {
    switch (pageId) {
      case 101:
        return {
          'background': const Color(0xFFE3F2FD),
          'icon': const Color(0xFF1976D2),
        };
      case 102:
        return {
          'background': const Color(0xFFE8F5E9),
          'icon': const Color(0xFF388E3C),
        };
      case 103:
        return {
          'background': const Color(0xFFE0F2F1),
          'icon': const Color(0xFF00897B),
        };
      case 104:
        return {
          'background': const Color(0xFFF3E5F5),
          'icon': const Color(0xFF7B1FA2),
        };
      case 105:
        return {
          'background': const Color(0xFFFFF3E0),
          'icon': const Color(0xFFF57C00),
        };
      case 106:
        return {
          'background': const Color(0xFFE1F5FE),
          'icon': const Color(0xFF0288D1),
        };
      case 107:
        return {
          'background': const Color(0xFFECEFF1),
          'icon': const Color(0xFF546E7A),
        };
      case 108:
        return {
          'background': const Color(0xFFFCE4EC),
          'icon': const Color(0xFFC2185B),
        };
      case 109:
        return {
          'background': const Color(0xFFFFF9C4),
          'icon': const Color(0xFFF9A825),
        };
      case 110:
        return {
          'background': const Color(0xFFEFEBE9),
          'icon': const Color(0xFF6D4C41),
        };
      case 111:
        return {
          'background': const Color(0xFFF0F4C3),
          'icon': const Color(0xFF9E9D24),
        };
      default:
        return {
          'background': const Color(0xFFF5F5F5),
          'icon': const Color(0xFF757575),
        };
    }
  }
}
