import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:fundvanceai/features/auth/auth_provider.dart';
import 'package:fundvanceai/features/premium/premium_provider.dart';
import 'package:fundvanceai/features/auth/screens/currency_selection_screen.dart';
import 'package:fundvanceai/features/premium/screens/paywall_screen.dart';
import 'package:fundvanceai/shared/models/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();
  bool _isEditingName = false;
  bool _isSavingName = false;
  bool _isUploadingAvatar = false;
  bool _isVerifyingSubscription = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthProvider>().userProfile;
    _nameController.text = profile?.fullName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  // ── Avatar ──────────────────────────────────────────────────────────────
  Future<void> _pickAndUploadAvatar() async {
    final authProvider = context.read<AuthProvider>();
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (file == null) return;

    setState(() => _isUploadingAvatar = true);
    try {
      final bytes = await file.readAsBytes();
      final ok = await authProvider.uploadAvatar(bytes);
      if (!ok && mounted) {
        _showError(authProvider.errorMessage ?? 'Avatar upload failed');
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  // ── Name editing ─────────────────────────────────────────────────────────
  void _startEditing() {
    setState(() => _isEditingName = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocusNode.requestFocus();
    });
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _isSavingName = true;
      _isEditingName = false;
    });

    final authProvider = context.read<AuthProvider>();
    final ok = await authProvider.updateProfile(fullName: name);
    if (mounted) {
      setState(() => _isSavingName = false);
      if (!ok) _showError(authProvider.errorMessage ?? 'Failed to save name');
    }
  }

  void _cancelEditing() {
    final profile = context.read<AuthProvider>().userProfile;
    _nameController.text = profile?.fullName ?? '';
    setState(() => _isEditingName = false);
  }

  // ── Verify subscription ──────────────────────────────────────────
  Future<void> _verifySubscription() async {
    setState(() => _isVerifyingSubscription = true);
    final premiumProvider = context.read<PremiumProvider>();
    final status = await premiumProvider.verifyStripePayment();
    if (mounted) {
      setState(() => _isVerifyingSubscription = false);
      if (status.isPremium) {
        _showMessage('Subscription verified — Pro active!');
      } else if (status.status != null && status.status!.startsWith('error:')) {
        _showError(status.status!.replaceFirst('error:', '').trim());
      } else {
        _showMessage('No active subscription found');
      }
    }
  }

  // ── Change password ───────────────────────────────────────────────────────
  Future<void> _changePassword() async {
    final authProvider = context.read<AuthProvider>();
    final email = authProvider.currentUser?.email;
    if (email == null) return;

    final ok = await authProvider.resetPassword(email);
    if (!mounted) return;
    if (ok) {
      _showMessage('Password reset email sent to $email');
    } else {
      _showError(authProvider.errorMessage ?? 'Failed to send reset email');
    }
  }

  // ── Delete account ────────────────────────────────────────────────────────
  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This permanently deletes your account and ALL your data.\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final authProvider = context.read<AuthProvider>();
    final ok = await authProvider.deleteAccount();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    } else {
      _showError(authProvider.errorMessage ?? 'Failed to delete account');
    }
  }

  // ── Sign out ──────────────────────────────────────────────────────────────
  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await context.read<AuthProvider>().signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _initials(UserProfile? profile, String? email) {
    final name = profile?.fullName;
    if (name != null && name.isNotEmpty) {
      final parts = name.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      }
      return name[0].toUpperCase();
    }
    if (email != null && email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    return '?';
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final premiumProvider = context.watch<PremiumProvider>();
    final isPremium = premiumProvider.isPremium;
    final isInTrial = premiumProvider.isInTrial;
    final trialEnd = premiumProvider.trialEnd;
    final profile = authProvider.userProfile;
    final user = authProvider.currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          if (_isEditingName) ...[
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancel',
              onPressed: _cancelEditing,
            ),
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: 'Save',
              onPressed: _saveName,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Avatar section
            _AvatarSection(
              profile: profile,
              initials: _initials(profile, user?.email),
              isUploading: _isUploadingAvatar,
              onTap: _pickAndUploadAvatar,
            ),

            const SizedBox(height: 24),

            // ── Info card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Column(
                  children: [
                    // Name row
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Display Name'),
                      subtitle: _isEditingName
                          ? TextField(
                              controller: _nameController,
                              focusNode: _nameFocusNode,
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _saveName(),
                            )
                          : _isSavingName
                              ? const Text('Saving…',
                                  style: TextStyle(fontStyle: FontStyle.italic))
                              : Text(profile?.fullName ?? 'Not set'),
                      trailing: _isEditingName
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              tooltip: 'Edit name',
                              onPressed: _startEditing,
                            ),
                    ),

                    const Divider(height: 1),

                    // Email row
                    ListTile(
                      leading: const Icon(Icons.email_outlined),
                      title: const Text('Email'),
                      subtitle: Text(user?.email ?? '—'),
                      trailing: const Icon(Icons.lock_outline,
                          size: 16, color: Colors.grey),
                    ),

                    const Divider(height: 1),

                    // Member since
                    ListTile(
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: const Text('Member Since'),
                      subtitle: Text(
                        profile?.createdAt != null
                            ? DateFormat.yMMMd()
                                .format(profile!.createdAt.toLocal())
                            : '—',
                      ),
                    ),

                    const Divider(height: 1),

                    // Subscription badge
                    ListTile(
                      leading: Icon(
                        isPremium
                            ? (isInTrial
                                ? Icons.hourglass_top
                                : Icons.workspace_premium)
                            : Icons.star_border,
                        color: isPremium ? Colors.amber : null,
                      ),
                      title: const Text('Subscription'),
                      subtitle: isInTrial
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Free Trial',
                                    style: TextStyle(
                                        color: Colors.amber,
                                        fontWeight: FontWeight.w600)),
                                if (trialEnd != null)
                                  Text(
                                    'Trial ends ${DateFormat.yMMMd().format(trialEnd.toLocal())}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                              ],
                            )
                          : Text(isPremium ? 'Pro' : 'Free'),
                      trailing: isPremium
                          ? null
                          : TextButton(
                              onPressed: () {
                                final premiumProvider =
                                    context.read<PremiumProvider>();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PaywallScreen(),
                                  ),
                                ).then((_) {
                                  premiumProvider.verifyStripePayment();
                                });
                              },
                              child: const Text('Upgrade'),
                            ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Preferences card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.language),
                      title: const Text('Currency'),
                      subtitle: Text(authProvider.userCurrency),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CurrencySelectionScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: _isVerifyingSubscription
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.verified_outlined),
                      title: const Text('Verify Subscription'),
                      subtitle: const Text('Sync your subscription status'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap:
                          _isVerifyingSubscription ? null : _verifySubscription,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Account actions card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.lock_reset),
                      title: const Text('Change Password'),
                      subtitle: const Text('Send reset link to your email'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _changePassword,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading:
                          Icon(Icons.logout, color: theme.colorScheme.error),
                      title: Text('Sign Out',
                          style: TextStyle(color: theme.colorScheme.error)),
                      onTap: _signOut,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading:
                          const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text('Delete Account',
                          style: TextStyle(color: Colors.red)),
                      subtitle: const Text(
                        'Permanently deletes your account and all data',
                        style: TextStyle(fontSize: 12),
                      ),
                      onTap: _confirmDeleteAccount,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar section widget
// ─────────────────────────────────────────────────────────────────────────────
class _AvatarSection extends StatelessWidget {
  final UserProfile? profile;
  final String initials;
  final bool isUploading;
  final VoidCallback onTap;

  const _AvatarSection({
    required this.profile,
    required this.initials,
    required this.isUploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: isUploading ? null : onTap,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: Colors.white,
                  child: isUploading
                      ? const CircularProgressIndicator()
                      : profile?.avatarUrl != null
                          ? ClipOval(
                              child: Image.network(
                                profile!.avatarUrl!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Text(
                                  initials,
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            )
                          : Text(
                              initials,
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt,
                      size: 16, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            profile?.fullName ?? 'Your Profile',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap avatar to change photo',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
