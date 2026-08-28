import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _smsEnabled = false;
  bool _gmailEnabled = false;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    final userId = AppSession.userId;
    if (userId == null) return;
    
    // Check Gmail status
    final gmailStatus = await ApiService.getGoogleStatus(userId: userId);
    if (gmailStatus != null) {
      setState(() {
        _gmailEnabled = gmailStatus['isConnected'] == true;
      });
    }

    // Since we don't have a direct route to fetch only user preferences easily here in the frontend 
    // besides fetching the whole profile, we'll just optimistically rely on the DB update.
    // In a real app we'd fetch the user profile here and read user.smsEnabled.
  }

  void _updateSmsPreference(bool value) async {
    setState(() => _smsEnabled = value);
    final userId = AppSession.userId;
    if (userId != null) {
      await ApiService.updatePreferences(userId: userId, smsEnabled: value);
    }
  }

  void _toggleGmail(bool value) async {
    final userId = AppSession.userId;
    setState(() => _gmailEnabled = value);

    if (userId != null) {
      await ApiService.updatePreferences(userId: userId, gmailEnabled: value);
    }

    if (!value) {
      if (userId != null) {
        await ApiService.disconnectGoogle(userId: userId);
      }
    } else {
      // Launch Google OAuth
      final uid = userId ?? '';
      AudioService.openUrl('${ApiService.baseUrl}/auth/google/connect-gmail?state=$uid', usePopup: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D32B2),
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 20),
          Center(
            child: AppSession.userPicture != null && AppSession.userPicture!.isNotEmpty
                ? CircleAvatar(
                    backgroundImage: NetworkImage('http://localhost:3000/api/image-proxy?url=${Uri.encodeComponent(AppSession.userPicture!)}'),
                    radius: 40,
                  )
                : const CircleAvatar(
                    backgroundColor: Colors.white24,
                    radius: 40,
                    child: Icon(Icons.person, color: Colors.white, size: 40),
                  ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              AppSession.userName ?? 'User',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0A1628)),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              AppSession.userEmail ?? '',
              style: const TextStyle(fontSize: 14, color: Color(0xFF5A6E85)),
            ),
          ),
          const SizedBox(height: 40),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('DATA SYNC PREFERENCES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Enable Gmail Parsing', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Automatically extract bills and transactions', style: TextStyle(fontSize: 12)),
                  value: _gmailEnabled,
                  onChanged: _toggleGmail,
                  activeColor: const Color(0xFF1548DC),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  title: const Text('Enable SMS Interception', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Monitor bank SMS messages in real-time', style: TextStyle(fontSize: 12)),
                  value: _smsEnabled,
                  onChanged: _updateSmsPreference,
                  activeColor: const Color(0xFF1548DC),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: () {
                AppSession.userId = null;
                AppSession.userName = null;
                AppSession.userEmail = null;
                AppSession.userPicture = null;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
