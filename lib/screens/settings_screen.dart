import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_scope.dart';
import '../widgets/ui.dart';
import 'policy_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _site = 'https://combouniversal.com/';
  static const _support = 'https://combosupport.in/';
  static const _whatsapp = 'https://wa.me/917205702493';
  static const _playUrl =
      'https://play.google.com/store/apps/details?id=com.makund.combouniversal';

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([scope.prefs, scope.catalog, scope.ads]),
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const SectionHeader(title: 'Appearance'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Dark theme'),
                    secondary: const Icon(Icons.dark_mode_outlined),
                    value: scope.prefs.dark,
                    onChanged: scope.prefs.setDark,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.format_size_rounded),
                    title: Text('Text size · ${(scope.prefs.fontScale * 100).round()}%'),
                    subtitle: Slider(
                      value: scope.prefs.fontScale,
                      min: 0.85,
                      max: 1.5,
                      divisions: 13,
                      label: '${(scope.prefs.fontScale * 100).round()}%',
                      onChanged: scope.prefs.setFontScale,
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Personalised ads'),
                    subtitle: const Text(
                        'Turn off to see only non-personalised ads. The app stays free either way.'),
                    secondary: const Icon(Icons.ads_click_rounded),
                    value: scope.prefs.personalizedAds,
                    onChanged: (v) {
                      scope.prefs.setPersonalizedAds(v);
                      scope.ads.setPersonalized(v);
                    },
                  ),
                  // Google requires EEA/UK users to be able to revisit their
                  // consent choice at any time from a persistent control.
                  if (scope.ads.privacyOptionsRequired) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: const Text('Privacy options'),
                      subtitle: const Text(
                          'Review or change your ad consent choices.'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => scope.ads.showPrivacyOptions(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Data & links'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.sync_rounded),
                    title: const Text('Check for list update'),
                    subtitle: Text(
                        'Current version ${scope.catalog.catalog?.version ?? '-'} (${scope.catalog.source})'),
                    trailing: scope.catalog.refreshing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      final updated = await scope.catalog
                          .refreshFromRemote(userInitiated: true);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(updated
                              ? 'List updated.'
                              : 'You already have the latest list.'),
                        ));
                      }
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.public_rounded),
                    title: const Text('Combo Universal website'),
                    onTap: () => _open(_site),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.support_agent_rounded),
                    title: const Text('Combo Support'),
                    onTap: () => _open(_support),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.chat_rounded),
                    title: const Text('Contact on WhatsApp'),
                    onTap: () => _open(_whatsapp),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.star_rate_rounded),
                    title: const Text('Rate this app'),
                    onTap: () => _open(_playUrl),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Legal'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Privacy policy'),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const PolicyScreen(kind: PolicyKind.privacy),
                    )),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.gavel_rounded),
                    title: const Text('Terms & disclaimer'),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const PolicyScreen(kind: PolicyKind.terms),
                    )),
                  ),
                  const Divider(height: 1),
                  // The SIL OFL and Apache-2.0 both require their notices to be
                  // viewable by the end user, not just present in the bundle.
                  ListTile(
                    leading: const Icon(Icons.workspace_premium_outlined),
                    title: const Text('Open source licences'),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          const PolicyScreen(kind: PolicyKind.licences),
                    )),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snap) => Center(
                child: Text(
                  snap.hasData
                      ? 'Version ${snap.data!.version} (${snap.data!.buildNumber})'
                      : '',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
