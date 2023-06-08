import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '/widgets/custom_list_tile.dart';
import '/commons/app_config.dart' as app_config;
import '/commons/routes.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static final _urlCode = Uri.parse('https://github.com/OPENER-next');
  static final _urlContributors = Uri.parse('https://github.com/OPENER-next/OpenStop/graphs/contributors');
  static final _urlIdea = Uri.parse('https://www.tu-chemnitz.de/etit/sse');
  static final _urlLicense = Uri.parse('https://github.com/OPENER-next/OpenStop/blob/master/LICENSE');
  static final _urlVersion = Uri.parse('https://github.com/OPENER-next/OpenStop/releases');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.aboutTitle),
      ),
      body: Scrollbar(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Image.asset(
                  'assets/images/app_icon_android.png',
                  height: 120,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 20.0),
                child: Text(
                  AppLocalizations.of(context)!.aboutSlogan,
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
              CustomListTile(
                leadingIcon: Icons.info,
                trailingIcon: Icons.open_in_new,
                title: AppLocalizations.of(context)!.aboutVersion,
                subtitle: app_config.appVersion,
                onTap: () => launchUrl(_urlVersion),
              ),
              CustomListTile(
                leadingIcon: Icons.supervisor_account,
                trailingIcon: Icons.open_in_new,
                title: AppLocalizations.of(context)!.aboutAuthorsLabel,
                subtitle: AppLocalizations.of(context)!.aboutAuthorsDescription(app_config.appName),
                onTap: () => launchUrl(_urlContributors),
              ),
              CustomListTile(
                isThreeLine: true,
                leadingIcon: Icons.lightbulb,
                trailingIcon: Icons.open_in_new,
                title: AppLocalizations.of(context)!.aboutIdeaLabel,
                subtitle: AppLocalizations.of(context)!.aboutIdeaDescription,
                onTap: () => launchUrl(_urlIdea),
              ),
              CustomListTile(
                leadingIcon: Icons.code,
                trailingIcon: Icons.open_in_new,
                title: AppLocalizations.of(context)!.aboutSourceCodeLabel,
                subtitle: 'https://github.com/OPENER-next',
                onTap: () => launchUrl(_urlCode),
              ),
              CustomListTile(
                leadingIcon: Icons.copyright,
                trailingIcon: Icons.open_in_new,
                title: AppLocalizations.of(context)!.aboutLicenseLabel,
                subtitle: 'GPL-3.0',
                onTap: () => launchUrl(_urlLicense),
              ),
              CustomListTile(
                leadingIcon: Icons.privacy_tip,
                trailingIcon: Icons.arrow_forward_ios_rounded,
                title: AppLocalizations.of(context)!.aboutPrivacyPolicyLabel,
                onTap: () => Navigator.push(context, Routes.privacyPolicy),
              ),
              CustomListTile(
                leadingIcon: Icons.text_snippet,
                trailingIcon: Icons.arrow_forward_ios_rounded,
                title: AppLocalizations.of(context)!.aboutLicensePackageLabel,
                onTap: () => Navigator.push(context, Routes.licenses),
              ),
              Container(
                color: Colors.white,
                height: 160,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Image.asset(
                          'assets/images/logos/BMDV_Fz_2021_Office_Farbe_de.png',
                        ),
                      ),
                    ),
                    Flexible(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20.0, 50.0, 20.0, 50.0),
                        child: Image.asset(
                          'assets/images/logos/mFUND_Logo_sRGB.png',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
