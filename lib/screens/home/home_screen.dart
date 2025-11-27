import 'package:hexcolor/hexcolor.dart';
import 'package:modernapproval/models/dashboard_stats_model.dart';
import 'package:modernapproval/models/form_report_model.dart';
import 'package:modernapproval/screens/approvals/approvals_screen.dart';
import 'package:modernapproval/screens/approved/approved_requests_screen.dart';
import 'package:modernapproval/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modernapproval/screens/rejected/rejected_requests_screen.dart';
import 'package:modernapproval/screens/reports/reports_screen.dart';
import 'package:modernapproval/services/api_service.dart';
import '../../models/user_model.dart';
import '../../app_localizations.dart';
import '../../services/event_bus.dart';
import '../../widgets/home_app_bar.dart';

class HomeScreen extends StatefulWidget {
  final UserModel user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // --- ✅ متغيرات جديدة لجلب البيانات ---
  final ApiService _apiService = ApiService();
  late Future<List<FormReportItem>> _formsReportsFuture;
  late Future<DashboardStats> _statsFuture;
  int _approvalsCount = 0;
  int _reportsCount = 0;
  bool _countsLoading = true;
  DashboardStats? _dashboardStats;
  bool _statsLoading = true;

  // ------------------------------------

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    EventBus.addListener(_loadData);
    _loadData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _countsLoading = true;
      _statsLoading = true;
    });

    try {
      // Wait for both API calls to complete
      final items = await _apiService.getFormsAndReports(widget.user.usersCode);
      final stats = await _apiService.getDashboardStats(widget.user.usersCode);

      if (!mounted) return;
      setState(() {
        _approvalsCount = items.where((item) => item.type == 'F').length;
        _reportsCount = items.where((item) => item.type == 'R').length;
        _dashboardStats = stats;
        _countsLoading = false;
        _statsLoading = false;
      });
    } catch (e) {
      print("Error refreshing data: $e");
      if (!mounted) return;
      setState(() {
        _countsLoading = false;
        _statsLoading = false;
        _approvalsCount = 0;
        _reportsCount = 0;
        _dashboardStats = DashboardStats(countAuth: 0, countReject: 0);
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    EventBus.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() {
      _countsLoading = true;
      _statsLoading = true;
    });

    // Use Future.wait to wait for both API calls
    await Future.wait([_formsReportsFuture, _statsFuture]);

    // The existing .then() callbacks in _loadData will handle the state updates
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      ///uncomment this to make the logo fit more with the design
      // backgroundColor: Color(0xFF6C63FF).withOpacity(1),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Stack(
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: CustomScrollView(
                slivers: [
                  HomeAppBar(user: widget.user),
                  SliverToBoxAdapter(
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildBody(isRtl),
                    ),
                  ),
                ],
              ),
            ),
            // Floating logo card positioned between appbar and content
            // Positioned(
            //   top: 160, // Adjust this to position between appbar and content
            //   left: 20,
            //   right: 20,
            //   child: _buildFloatingLogoCard(isRtl),
            // ),
          ],
        ),
      ),
    );
  }

  //new body with floating card ->

  Widget _buildFloatingLogoCard(bool isRtl) {
    return Transform.translate(
      offset: Offset(0, -25), // Adjust to fine-tune position
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.90),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 25,
              offset: Offset(0, 10),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: AssetImage("assets/images/lo.png"),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment:
                  isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  isRtl ? 'مرحباً بعودتك!' : 'Welcome Back!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6C63FF),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  isRtl
                      ? 'استمر في إدارة طلباتك'
                      : 'Continue managing your requests',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isRtl) {
    final localizations = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 360 ? 16.0 : 20.0;
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF8B5CF6).withOpacity(0.8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
          colors: [Color(0xFF6C63FF), const Color(0xFF8B5CF6)],
          stops: const [0.0, 1.0],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          // color: Colors.red,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(25),
            topLeft: Radius.circular(25),
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          children: [
            SizedBox(height: 16),

            // Main Cards - All 4 buttons in single column
            //with stats card and profile card
            Column(
              children: [
                _buildMinimalCard(
                  title: isRtl ? 'الموافقات' : 'Approvals',
                  icon: Icons.approval_outlined,
                  count: _countsLoading ? '...' : _approvalsCount.toString(),
                  color: Color(0xFF00BFA6),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ApprovalsScreen(user: widget.user),
                      ),
                    );
                  },
                ),
                SizedBox(height: 12),
                _buildMinimalCard(
                  title: isRtl ? 'التقارير' : 'Reports',
                  icon: Icons.analytics_outlined,
                  count: _countsLoading ? '...' : _reportsCount.toString(),
                  color: Color(0xFFFF6B6B),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReportsScreen(user: widget.user),
                      ),
                    );
                  },
                ),
                SizedBox(height: 12),
                _buildMinimalCard(
                  title: isRtl ? 'المعتمدة' : 'Approved',
                  icon: Icons.check_circle_outline,
                  showNotification: false,
                  count:
                      _statsLoading
                          ? '...'
                          : (_dashboardStats?.countAuth.toString() ?? '0'),
                  color: Color(0xFF10B981),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                ApprovedRequestsScreen(user: widget.user),
                      ),
                    );
                  },
                ),
                SizedBox(height: 12),
                _buildMinimalCard(
                  title: isRtl ? 'المرفوضة' : 'Rejected',
                  icon: Icons.highlight_off,
                  showNotification: false,
                  count:
                      _statsLoading
                          ? '...'
                          : (_dashboardStats?.countReject.toString() ?? '0'),
                  color: Color(0xFFFF6B6B),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                RejectedRequestsScreen(user: widget.user),
                      ),
                    );
                  },
                ),
                SizedBox(height: 12),
                _buildStatsCard(isRtl),
                SizedBox(height: 12),
                _buildProfileMinimalCard(isRtl, localizations),
                SizedBox(height: 16), // Add bottom padding
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalCard({
    required String title,
    required IconData icon,
    required String count,
    required Color color,
    required VoidCallback onTap,
    bool showNotification = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, // Ensure full width
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon with notification badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                // Notification badge
                if (count != '0' && count != '...')
                  showNotification
                      ? Positioned(
                        top: -6,
                        right: -6,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(1),
                            shape: BoxShape.circle,
                            // border: Border.all(
                            //   color: Colors.white.withOpacity(0.6),
                            //   width: 2,
                            // ),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Text(
                            count,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                      : SizedBox(),
              ],
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(bool isRtl) {
    final total =
        _statsLoading
            ? 1
            : ((_dashboardStats?.countAuth ?? 0) +
                (_dashboardStats?.countReject ?? 0));
    final approvedCount = _statsLoading ? 0 : (_dashboardStats?.countAuth ?? 0);
    final rejectedCount =
        _statsLoading ? 0 : (_dashboardStats?.countReject ?? 0);
    final approvedPercentage = total > 0 ? (approvedCount / total) : 0.0;
    final rejectedPercentage = total > 0 ? (rejectedCount / total) : 0.0;
    return Container(
      width: double.infinity, // Ensure full width
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isRtl ? 'إحصائيات الطلبات' : 'Request Statistics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatProgress(
                label: isRtl ? 'المعتمدة' : 'Approved',
                value: approvedCount,
                percentage: approvedPercentage,
                color: Color(0xFF10B981),
              ),
              _buildStatProgress(
                label: isRtl ? 'المرفوضة' : 'Rejected',
                value: rejectedCount,
                percentage: rejectedPercentage,
                color: Color(0xFFFF6B6B),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatProgress({
    required String label,
    required int value,
    required double percentage,
    required Color color,
  }) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeWidth: 6,
              ),
            ),
            Positioned.fill(
              child: Center(
                child: Text(
                  '${(percentage * 100).round()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileMinimalCard(bool isRtl, AppLocalizations localizations) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(user: widget.user.usersCode),
          ),
        );
      },
      child: Container(
        width: double.infinity, // Ensure full width
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFF6C63FF).withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFF6C63FF).withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(0xFF6C63FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.person, color: Color(0xFF6C63FF), size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.translate('profile') ??
                        (isRtl ? 'الملف الشخصي' : 'Profile'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6C63FF),
                    ),
                  ),
                  Text(
                    isRtl
                        ? 'إدارة إعدادات حسابك'
                        : 'Manage your account settings',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6C63FF).withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Color(0xFF6C63FF), size: 16),
          ],
        ),
      ),
    );
  }
}
