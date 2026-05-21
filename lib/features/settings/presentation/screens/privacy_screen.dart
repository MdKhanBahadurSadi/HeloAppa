import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy & Security',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage who can see your personal info and status.',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            _buildOption(
              context,
              icon: Icons.visibility_outlined,
              title: 'Last Seen & Online',
              subtitle: 'Everyone',
            ),
            _buildOption(
              context,
              icon: Icons.photo_camera_front_outlined,
              title: 'Profile Photo',
              subtitle: 'My contacts',
            ),
            _buildOption(
              context,
              icon: Icons.info_outline,
              title: 'About info',
              subtitle: 'Everyone',
            ),
            _buildOption(
              context,
              icon: Icons.block_outlined,
              title: 'Blocked Contacts',
              subtitle: 'None',
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'These privacy options are coming soon in a future update.',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: () {
          // Placeholder action
        },
      ),
    );
  }
}
