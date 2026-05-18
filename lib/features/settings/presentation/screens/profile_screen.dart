import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_state.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/extensions.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _imagePicker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _nameController.text = authState.user.name;
    }
  }

  Future<void> _pickAndUploadImage(String uid) async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isLoading = true);
    try {
      final ref = FirebaseStorage.instance.ref().child('avatars/$uid.jpg');
      await ref.putFile(File(image.path));
      final url = await ref.getDownloadURL();
      
      await FirebaseFirestore.instance
          .collection(AppConstants.USERS)
          .doc(uid)
          .update({'photoUrl': url});
          
      if (mounted) context.showSnackBar('Profile picture updated');
    } catch (e) {
      if (mounted) context.showSnackBar('Error uploading image: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile(String uid) async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.USERS)
          .doc(uid)
          .update({'name': _nameController.text.trim()});
      if (mounted) context.showSnackBar('Profile saved');
    } catch (e) {
      if (mounted) context.showSnackBar('Error saving profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) return const Scaffold();
        final user = state.user;

        return Scaffold(
          appBar: AppBar(title: const Text('Edit Profile')),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => _pickAndUploadImage(user.id),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: user.photoUrl != null
                            ? CachedNetworkImageProvider(user.photoUrl!)
                            : null,
                        child: user.photoUrl == null ? const Icon(Icons.person, size: 50) : null,
                      ),
                      if (_isLoading)
                        const Positioned.fill(child: CircularProgressIndicator()),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          radius: 15,
                          child: const Icon(Icons.camera_alt, size: 15, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _saveProfile(user.id),
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
