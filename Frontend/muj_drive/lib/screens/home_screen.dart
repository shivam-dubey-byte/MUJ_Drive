import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muj_drive/services/token_storage.dart';
import 'package:muj_drive/theme/app_theme.dart';
import 'package:muj_drive/screens/notification_screen.dart';

class TopLeftFabLocation extends FloatingActionButtonLocation {
  final double marginX;
  final double marginY;
  const TopLeftFabLocation({this.marginX = 16, this.marginY = 32});

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry s) {
    return Offset(marginX, s.minInsets.top + marginY);
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _name;
  String? _email;
  int _notificationCount = 3;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('name') ?? 'Guest User';
      _email = prefs.getString('email') ?? '';
    });
  }

  Route _createNotificationRoute() {
    return PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: const NotificationScreen(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      drawer: _buildDrawer(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 80.0,
        title: const Text('MUJ Drive'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications, size: 32),
                  color: Colors.white,
                  onPressed: () {
                    Navigator.of(context).push(_createNotificationRoute());
                  },
                ),
                if (_notificationCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        '$_notificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primary, AppTheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, kToolbarHeight + 24, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 48.0, 16.0, 0.0),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                  children: [
                    TextSpan(text: 'Hello, $_name 👋\n'),
                    const TextSpan(
                      text: '\n Wishing you a smooth and joyful ride experience!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _DashboardTile(
                    icon: Icons.directions_car,
                    label: 'Book a Ride',
                    onTap: () => Navigator.pushNamed(context, '/book-ride'),
                  ),
                  _DashboardTile(
                    icon: Icons.search,
                    label: 'Find Ride',
                    onTap: () => Navigator.pushNamed(context, '/find-ride'),
                  ),
                  _DashboardTile(
                    icon: Icons.local_taxi,
                    label: 'Offer Ride',
                    onTap: () => Navigator.pushNamed(context, '/offer-ride'),
                  ),
                  _DashboardTile(
                    icon: Icons.history,
                    label: 'My Rides',
                    onTap: () => Navigator.pushNamed(context, '/my-rides'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primary,
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        child: const Icon(Icons.menu, size: 32),
      ),
      floatingActionButtonLocation:
          const TopLeftFabLocation(marginX: 16, marginY: 32),
    );
  }

  Drawer _buildDrawer() => Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              accountName: Text(_name ?? ''),
              accountEmail: _email!.isNotEmpty ? Text(_email!) : null,
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.9),
                child: Icon(Icons.person, size: 40, color: AppTheme.primary),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _DrawerTile(
                    icon: Icons.directions_car,
                    label: 'Book a Ride',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/book-ride');
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.search,
                    label: 'Find Ride',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/find-ride');
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.local_taxi,
                    label: 'Offer Ride',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/offer-ride');
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.history,
                    label: 'My Rides',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/my-rides');
                    },
                  ),
                  const Divider(),
                  _DrawerTile(
                    icon: Icons.person,
                    label: 'Profile',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/profile');
                    },
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: _DrawerTile(
                icon: Icons.logout,
                label: 'Logout',
                isDestructive: true,
                onTap: () async {
                  await TokenStorage.clearToken();
                  Navigator.pushReplacementNamed(context, '/');
                },
              ),
            ),
          ],
        ),
      );
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _DrawerTile({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.redAccent : Colors.black87;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      onTap: onTap,
      dense: true,
    );
  }
}

class _DashboardTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DashboardTile({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: AppTheme.primary),
              const SizedBox(height: 12),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
