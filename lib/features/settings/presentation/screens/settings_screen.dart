import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class SettingsScreen extends StatefulWidget {
  final bool showAppBar;
  const SettingsScreen({super.key, this.showAppBar = true});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final Box _settingsBox;

  @override
  void initState() {
    super.initState();
    _settingsBox = Hive.box('settings');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.watch<AuthBloc>().state;

    String name = 'User';
    String email = 'Not Signed In';
    String? photoUrl;

    if (authState is AuthAuthenticated) {
      name = authState.user.name;
      email = authState.user.email;
      photoUrl = authState.user.photoUrl;
    }

    final Widget content = ValueListenableBuilder(
      valueListenable: _settingsBox.listenable(),
      builder: (context, Box box, _) {
        final notificationsEnabled = box.get('notifications', defaultValue: true);
        final darkModeEnabled = box.get('darkMode', defaultValue: false);

        return SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Profile Header
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                          ? NetworkImage(photoUrl)
                          : null,
                      child: photoUrl == null || photoUrl.isEmpty
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              // Settings Options
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Edit Profile'),
                subtitle: const Text('Change photo, name, and profile info'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/profile'),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.notifications_none_outlined),
                title: const Text('Notifications'),
                subtitle: const Text('Enable or disable system notifications'),
                value: notificationsEnabled,
                activeColor: AppTheme.primaryColor,
                onChanged: (val) {
                  box.put('notifications', val);
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('Dark Mode'),
                subtitle: const Text('Switch between light and dark themes'),
                value: darkModeEnabled,
                activeColor: AppTheme.primaryColor,
                onChanged: (val) {
                  box.put('darkMode', val);
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Privacy'),
                subtitle: const Text('Control account visibility and status'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/privacy'),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: const Text('App Version'),
                subtitle: const Text('1.0.0'),
                onTap: () {},
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<AuthBloc>().add(AuthSignOutRequested());
                    context.go('/login');
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );

    if (!widget.showAppBar) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: content,
    );
  }
}
