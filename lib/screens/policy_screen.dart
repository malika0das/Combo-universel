import 'package:flutter/material.dart';

enum PolicyKind { privacy, terms }

/// In-app copy of the policy documents. Play Console also requires a public
/// URL - publish the same text at https://combouniversal.com/privacy-policy/.
class PolicyScreen extends StatelessWidget {
  const PolicyScreen({super.key, required this.kind});

  final PolicyKind kind;

  static const _privacy = '''
Privacy Policy — Combo Universal
Last updated: 7 September 2026

1. What we collect
Combo Universal does not ask you to create an account and does not collect your name, phone number, email, contacts, photos, location or files.

2. Data stored on your device
Recent searches, saved lists, theme choice and the downloaded compatibility list are stored only on your device using local storage. Uninstalling the app deletes them. This data is never uploaded to us.

3. Network use
The app downloads an updated compatibility list from our server. This request contains no personal identifiers beyond the standard information every internet request includes (such as your IP address, handled by our hosting provider).

4. Advertising
We show ads from Google AdMob to keep the app free. Google may use a device advertising identifier to serve and measure ads. You can switch to non-personalised ads at any time in Settings, and you can reset or delete the advertising ID in your Android settings. Google's practices are described at https://policies.google.com/technologies/ads

5. Children
The app is intended for mobile repair professionals and shop owners and is not directed at children under 13.

6. Security
We use HTTPS for all network requests. No personal data is transmitted to our servers.

7. Your choices
Clear recent searches and saved lists from within the app, disable personalised ads in Settings, or uninstall the app to remove all locally stored data.

8. Changes
Any change to this policy will be published in the app and on our website with an updated date.

9. Contact
Makund Mobile, Lathor, Bolangir, Odisha, India 767038
WhatsApp: +91 72057 02493
Website: https://combouniversal.com/
''';

  static const _terms = '''
Terms of Use & Disclaimer — Combo Universal
Last updated: 7 September 2026

1. Purpose
Combo Universal provides reference information about which mobile display, combo, battery, tempered glass, sub-board and frame parts are commonly interchangeable between models.

2. Accuracy disclaimer
The compatibility data is community contributed and provided "as is" for guidance only. Manufacturers change panels, connectors and flex layouts within the same model name. Always physically verify the connector type, flex length, frame fit and touch calibration before fitting a part.

3. No liability
We are not liable for any loss, damaged part, damaged device or business loss arising from the use of this information. The final decision to fit a part is yours.

4. No affiliation
Brand names such as Samsung, Xiaomi, Redmi, Vivo, iQOO, Oppo, Realme, OnePlus, Apple, Motorola, Infinix, Tecno, Itel, Lava and Honor are trademarks of their respective owners. This app is an independent reference tool and is not endorsed by or affiliated with any of them. Brand names are used only to describe part compatibility.

5. Acceptable use
Do not scrape, resell or redistribute the data as your own product.

6. Ads
The app is free and supported by advertising. Ad content is served by Google and is not selected or endorsed by us.

7. Contact
WhatsApp: +91 72057 02493
''';

  @override
  Widget build(BuildContext context) {
    final privacy = kind == PolicyKind.privacy;
    return Scaffold(
      appBar: AppBar(
          title: Text(privacy ? 'Privacy policy' : 'Terms & disclaimer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: SelectableText(
          privacy ? _privacy : _terms,
          style: const TextStyle(height: 1.5),
        ),
      ),
    );
  }
}
