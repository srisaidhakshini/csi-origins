import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
                    backgroundImage: NetworkImage(AppSession.userPicture!),
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
