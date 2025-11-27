import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modernapproval/models/approvals/exit_permission/exit_permission_model.dart';
import 'package:modernapproval/widgets/exit_permission/permission_details_bottom_sheet.dart';
import '../../../app_localizations.dart';
import '../../../models/user_model.dart';
import '../../../services/api_service.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/error_display.dart';

class ExitPermissionApproval extends StatefulWidget {
  final UserModel user;
  final int selectedPasswordNumber;

  const ExitPermissionApproval({
    super.key,
    required this.user,
    required this.selectedPasswordNumber,
  });

  @override
  State<ExitPermissionApproval> createState() => _ExitPermissionApprovalState();
}

class _ExitPermissionApprovalState extends State<ExitPermissionApproval> {
  final ApiService _apiService = ApiService();
  late Future<List<ExitPermission>> _requestsFuture;

  String _permissionTypeFilter = '';
  DateTime? _selectedEnterDate;
  List<ExitPermission> _filteredRequests = [];
  bool _showFilters = false;
  List<String> _availableVacationTypeNames = [];

  // ألوان واضحة وقوية
  final List<Color> _cardColors = [
    const Color(0xFF5B9BD5), // أزرق
    const Color(0xFF70AD47), // أخضر
    const Color(0xFFF4A460), // برتقالي
    const Color(0xFF8E8EBD), // بنفسجي
    const Color(0xFFE67E7E), // أحمر فاتح
    const Color(0xFF9B9B9B), // رمادي
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    setState(() {
      _requestsFuture = _apiService.getExitPermissions(
        userId: widget.user.usersCode,
        roleId: widget.user.roleCode!,
        passwordNumber: widget.selectedPasswordNumber,
      );
    });
  }

  void _extractPermissionType(List<ExitPermission> requests) {
    final permissionTypeNames =
        requests
            .map((request) => request.reasonAr ?? '')
            .where((permissionType) => permissionType.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    _availableVacationTypeNames = [''] + permissionTypeNames;
  }

  void _applyFilters(List<ExitPermission> allRequests) {
    setState(() {
      _filteredRequests =
          allRequests.where((request) {
            // If both filters are empty, show all
            if (_permissionTypeFilter.isEmpty && _selectedEnterDate == null) {
              return true;
            }

            bool matchesPermissionTypeName = true;
            bool matchesDate = true;

            // Apply Vacation Type name filter only if it's not empty
            if (_permissionTypeFilter.isNotEmpty) {
              matchesPermissionTypeName =
                  (request.reasonAr ?? '') == _permissionTypeFilter;
            }

            // Apply date filter only if a date is selected
            if (_selectedEnterDate != null) {
              matchesDate =
                  request.enterDate != null &&
                  _isSameDate(request.enterDate!, _selectedEnterDate!);
            }

            return matchesPermissionTypeName && matchesDate;
          }).toList();
    });
  }

  bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _clearFilters() {
    setState(() {
      _permissionTypeFilter = '';
      _selectedEnterDate = null;
      _showFilters = false;
    });
    _requestsFuture.then((data) => _applyFilters(data));
  }

  Widget _buildFilterWidget() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Filter toggle button
        IconButton(
          icon: Icon(
            _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              _showFilters = !_showFilters;
            });
          },
        ),

        // Clear filters button (visible when filters are active)
        if (_permissionTypeFilter.isNotEmpty || _selectedEnterDate != null)
          IconButton(
            icon: Icon(Icons.clear, color: Colors.white),
            onPressed: _clearFilters,
          ),
      ],
    );
  }

  Widget _buildFilterSection() {
    if (!_showFilters) return SizedBox.shrink();
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // Vacation name filter - DropdownMenu
          // SizedBox(
          //   height: 46,
          //   child: InputDecorator(
          //     decoration: InputDecoration(
          //       labelText: l.translate('filter_by_vacation_type_name'),
          //       prefixIcon: Icon(Icons.store, size: 20),
          //       border: OutlineInputBorder(
          //         borderRadius: BorderRadius.all(Radius.circular(28)),
          //       ),
          //       contentPadding: EdgeInsets.symmetric(
          //         horizontal: 16,
          //         vertical: 8,
          //       ),
          //     ),
          //     child: DropdownButtonHideUnderline(
          //       child: DropdownButton<String>(
          //         value:
          //             _permissionTypeFilter.isEmpty
          //                 ? null
          //                 : _permissionTypeFilter,
          //         isExpanded: true,
          //         icon: Icon(
          //           Icons.arrow_drop_down,
          //           color: Colors.grey.shade600,
          //         ),
          //         hint: Text(
          //           l.translate('select_vacation_type'),
          //           style: TextStyle(color: Colors.grey.shade600),
          //         ),
          //         items:
          //             _availableVacationTypeNames.map((String vacationType) {
          //               return DropdownMenuItem<String>(
          //                 value: vacationType.isEmpty ? null : vacationType,
          //                 child: Text(
          //                   vacationType.isEmpty
          //                       ? l.translate('all_types')
          //                       : vacationType,
          //                   style: TextStyle(
          //                     color:
          //                         vacationType.isEmpty
          //                             ? Colors.grey.shade500
          //                             : Colors.black87,
          //                   ),
          //                 ),
          //               );
          //             }).toList(),
          //         onChanged: (String? newValue) {
          //           setState(() {
          //             _permissionTypeFilter = newValue ?? '';
          //           });
          //           _requestsFuture.then((data) => _applyFilters(data));
          //         },
          //       ),
          //     ),
          //   ),
          // ),
          //
          // SizedBox(height: 8),

          // Date filter
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _showDatePicker(),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 18),
                        SizedBox(width: 8),
                        Text(
                          _selectedEnterDate == null
                              ? l.translate('filter_by_date')
                              : DateFormat(
                                'yyyy-MM-dd',
                              ).format(_selectedEnterDate!),
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_selectedEnterDate != null) ...[
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _selectedEnterDate = null;
                    });
                    _requestsFuture.then((data) => _applyFilters(data));
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _selectedEnterDate) {
      setState(() {
        _selectedEnterDate = picked;
      });
      _requestsFuture.then((data) => _applyFilters(data));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: CustomAppBar(
        title: l.translate('ExitPermissionApproval'),
        filterWidget: _buildFilterWidget(),
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // Filter section
          _buildFilterSection(),

          // List content
          Expanded(
            child: FutureBuilder<List<ExitPermission>>(
              future: _requestsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: const Color(0xFF7CB9E8),
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l.translate('loading') ?? 'Loading...',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7CB9E8).withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: const Color(0xFF7CB9E8).withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l.translate('noData'),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l.translate('noRequestsAvailable') ??
                              'No requests available',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final allRequests = snapshot.data!;

                // Extract VacationType names when data loads
                if (_availableVacationTypeNames.isEmpty) {
                  _extractPermissionType(allRequests);
                }

                // Apply filters when data loads or when filtered list is empty
                if (_filteredRequests.isEmpty &&
                    _permissionTypeFilter.isEmpty &&
                    _selectedEnterDate == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      _filteredRequests = allRequests;
                    });
                  });
                }
                final displayRequests =
                    _showFilters &&
                            (_permissionTypeFilter.isNotEmpty ||
                                _selectedEnterDate != null)
                        ? _filteredRequests
                        : allRequests;

                // Show filter results info
                if (_showFilters &&
                    (_permissionTypeFilter.isNotEmpty ||
                        _selectedEnterDate != null)) {
                  return Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        color: Colors.blue.shade50,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l.translate(
                                'resultsFound',
                                params: {
                                  "resultLength": "${displayRequests.length}",
                                },
                              ),
                              style: TextStyle(
                                color: Colors.blue.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextButton(
                              onPressed: _clearFilters,
                              child: Text(l.translate('clearFilters')),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          itemCount: displayRequests.length,
                          itemBuilder: (context, index) {
                            return _buildExitPermissionCard(
                              context,
                              displayRequests[index],
                              index,
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: displayRequests.length,
                  itemBuilder: (context, index) {
                    return _buildExitPermissionCard(
                      context,
                      displayRequests[index],
                      index,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExitPermissionCard(
    BuildContext context,
    ExitPermission request,
    int index,
  ) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final cardColor = _cardColors[index % _cardColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder:
                  (_) => PermissionDetailsBottomSheet(
                    request: request,
                    user: widget.user,
                    apiService: _apiService,
                    onDataChanged: _fetchData,
                  ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    color: cardColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, size: 15, color: cardColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              (isArabic ? request.empName : request.empNameE) ??
                                  'N/A',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: cardColor,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ("${request.reasonAr ?? ''}"),
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Colors.black87,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 13,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                (request.authPk2.toString()),
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                request.authPk1.toString() +
                                    " / " +
                                    request.authPk3.toString(),
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.chevron_right,
                  size: 25,
                  color: Colors.grey.shade500,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
