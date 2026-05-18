import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_event.dart';
import '../../auth/presentation/bloc/auth_state.dart';
import '../../../../core/router/app_router.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) return const SizedBox();
        final user = state.user;

        return ListView(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.transparent),
              currentAccountPicture: CircleAvatar(
                backgroundImage: user.photoUrl != null
                    ? CachedNetworkImageProvider(user.photoUrl!)
                    : null,
                child: user.photoUrl == null ? const Icon(Icons.person) : null,
              ),
              accountName: Text(user.name, style: const TextStyle(color: Colors.black)),
              accountEmail: Text(user.email, style: const TextStyle(color: Colors.black54)),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Edit Profile'),
              onTap: () => context.push('/profile'),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.notifications_none),
              title: const Text('Notifications'),
              value: true,
              onChanged: (val) {},
            ),
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('Dark Mode'),
              value: false,
              onChanged: (val) {},
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Privacy'),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              onTap: () {
                context.read<AuthBloc>().add(AuthSignOutRequested());
                context.go(AppRouter.login);
              },
            ),
          ],
        );
      },
    );
  }
}
