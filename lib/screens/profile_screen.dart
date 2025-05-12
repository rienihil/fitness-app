import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../service/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? name;
  String? email;
  bool _isDarkMode = false;
  bool _isGuestMode = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('name') ?? "User";
      email = prefs.getString('email') ?? "user@example.com";
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _isGuestMode = prefs.getBool('isGuestMode') ?? false;
    });
  }

  Future<void> _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = value;
    await prefs.setBool('isDarkMode', _isDarkMode);
    MyApp.of(context)?.setThemeMode(_isDarkMode ? ThemeMode.dark : ThemeMode.light);
    setState(() {});
  }

  Widget _buildListTile(IconData icon, String title, VoidCallback onTap, {bool disabled = false}) {
    return ListTile(
      leading: Icon(icon, color: disabled ? Colors.grey : null),
      title: Text(
        title,
        style: TextStyle(color: disabled ? Colors.grey : null),
      ),
      trailing: disabled
          ? const Icon(Icons.lock, size: 16, color: Colors.grey)
          : const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: disabled ? () => _showGuestRestrictionDialog() : onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: Theme.of(context).cardColor,
    );
  }

  void _showGuestRestrictionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Feature Restricted'),
        content: const Text(
            'This feature is not available in guest mode. Please sign in with a registered account to access all features.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _signOut();
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    await _authService.signOut();

    if (!mounted) return;

    // Update the login state
    MyApp.of(context)?.setLoggedIn(false);

    // Navigate back to login screen
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PROFILE', style: TextStyle(fontWeight: FontWeight.bold)),
        // actions: [
        //   if (!_isGuestMode)
            // IconButton(
            //   icon: const Icon(Icons.edit),
            //   onPressed: () {
            //     ScaffoldMessenger.of(context).showSnackBar(
            //       const SnackBar(content: Text("Редактирование пока не реализовано")),
            //     );
            //   },
            // ),
        // ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                    radius: 28,
                    backgroundColor: _isGuestMode ? Colors.grey : null,
                    child: Text(_isGuestMode ? "G" : "A")
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        name ?? '',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(height: 4),
                    Text(
                        email ?? '',
                        style: const TextStyle(color: Colors.grey)
                    ),
                    if (_isGuestMode)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: const Text(
                          'GUEST MODE',
                          style: TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Guest mode banner if applicable
          if (_isGuestMode)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber),
                      SizedBox(width: 8),
                      Text(
                        'Limited Access Mode',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You are using the app in guest mode. Some features are restricted. Sign in to access all features.',
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _signOut,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Sign In Now'),
                  ),
                ],
              ),
            ),

          _buildListTile(Icons.person, 'Account', () {}, disabled: _isGuestMode),
          _buildListTile(Icons.language, 'Language', () {}),
          _buildListTile(Icons.notifications, 'Notifications', () {}, disabled: _isGuestMode),
          _buildListTile(Icons.delete, 'Delete Account', () {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Удаление пока не реализовано'))
            );
          }, disabled: _isGuestMode),
          _buildListTile(Icons.logout, 'Sign Out', () {
            Navigator.of(context).pop();
            _signOut();
          }),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(_isDarkMode ? Icons.nightlight_round : Icons.wb_sunny),
                const SizedBox(width: 12),
                const Text("Dark theme", style: TextStyle(fontSize: 16)),
              ]),
              Switch(
                value: _isDarkMode,
                onChanged: _toggleTheme,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LogoutScreen extends StatelessWidget {
  const LogoutScreen({Key? key}) : super(key: key);

  Future<void> _clearPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  @override
  Widget build(BuildContext context) {
    _clearPrefs();

    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: const Text('Войти снова'),
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/');
          },
        ),
      ),
    );
  }
}