import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
    final isDark = theme.brightness == Brightness.dark;
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          child: Column(
            children: [
              // Profile Card
              TweenAnimationBuilder(
                duration: const Duration(milliseconds: 600),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, double value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: GlassContainer(
                  padding: const EdgeInsets.all(24),
                  borderRadius: 32,
                  blur: 20,
                  opacity: isDark ? 0.08 : 0.05,
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                )
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                              child: photoUrl != null && photoUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(50),
                                      child: CachedNetworkImage(
                                        imageUrl: photoUrl,
                                        placeholder: (context, url) => const CircularProgressIndicator(),
                                        errorWidget: (context, url, error) => Text(
                                          name[0].toUpperCase(),
                                          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
                                        ),
                                      ),
                                    )
                                  : Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        name,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Settings Groups
              _buildSettingsGroup(
                title: 'Account',
                isDark: isDark,
                children: [
                  _buildSettingsTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Personal Info',
                    color: Colors.blueAccent,
                    onTap: () => context.push('/profile'),
                  ),
                  _buildSettingsTile(
                    icon: Icons.shield_outlined,
                    title: 'Privacy & Security',
                    color: Colors.greenAccent,
                    onTap: () => context.push('/privacy'),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              _buildSettingsGroup(
                title: 'Preferences',
                isDark: isDark,
                children: [
                  _buildSwitchTile(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    value: notificationsEnabled,
                    color: Colors.orangeAccent,
                    onChanged: (val) => box.put('notifications', val),
                  ),
                  _buildSwitchTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'Dark Appearance',
                    value: darkModeEnabled,
                    color: Colors.purpleAccent,
                    onChanged: (val) => box.put('darkMode', val),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Logout Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ElevatedButton(
                  onPressed: () {
                    context.read<AuthBloc>().add(AuthSignOutRequested());
                    context.go('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent.withOpacity(0.1),
                    foregroundColor: Colors.redAccent,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded),
                      SizedBox(width: 12),
                      Text('Sign Out Account', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!widget.showAppBar) {
      return content;
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: content,
    );
  }

  Widget _buildSettingsGroup({required String title, required List<Widget> children, required bool isDark}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: AppTheme.primaryColor.withOpacity(0.8),
              letterSpacing: 1.5,
            ),
          ),
        ),
        GlassContainer(
          borderRadius: 24,
          blur: 10,
          opacity: isDark ? 0.05 : 0.03,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({required IconData icon, required String title, required Color color, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({required IconData icon, required String title, required bool value, required Color color, required Function(bool) onChanged}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      trailing: Switch.adaptive(
        value: value,
        activeColor: AppTheme.primaryColor,
        onChanged: onChanged,
      ),
    );
  }
}
