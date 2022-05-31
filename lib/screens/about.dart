import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '/widgets/custom_list_tile.dart';
import '/commons/app_config.dart' as app_config;
import '/commons/routes.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  static const String _urlCode = 'https://github.com/OPENER-next';
  static const String _urlContributors = 'https://github.com/OPENER-next/OpenStop/graphs/contributors';
  static const String _urlIdea = 'https://www.tu-chemnitz.de/etit/sse';
  static const String _urlLicense = 'https://github.com/OPENER-next/OpenStop/blob/master/LICENSE';
  static const String _urlVersion = 'https://github.com/OPENER-next/OpenStop/releases';

  Future<void> _launchUrl(String url) async {
    if (!await launchUrlString(
      url,
      mode: LaunchMode.externalApplication,
    )) throw '$url kann nicht aufgerufen werden';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Über'),
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
              const Padding(
                padding: EdgeInsets.only(bottom: 20.0),
                child: Text(
                  '"Nächster Halt: Barrierefreiheit"',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
              CustomListTile(
                leadingIcon: Icons.info,
                trailingIcon: Icons.open_in_new,
                title: 'Version',
                subtitle: app_config.appVersion,
                onTap: () => _launchUrl(_urlVersion),
              ),
              CustomListTile(
                leadingIcon: Icons.supervisor_account,
                trailingIcon: Icons.open_in_new,
                title: 'Autoren',
                subtitle: '${app_config.appName} Mitwirkende',
                onTap: () => _launchUrl(_urlContributors),
              ),
              CustomListTile(
                isThreeLine: true,
                leadingIcon: Icons.lightbulb,
                trailingIcon: Icons.open_in_new,
                title: 'Idee',
                subtitle: 'Technische Universität Chemnitz\n'
                    'Professur Schaltkreis- und Systementwurf',
                onTap: () => _launchUrl(_urlIdea),
              ),
              CustomListTile(
                leadingIcon: Icons.code,
                trailingIcon: Icons.open_in_new,
                title: 'Quellcode',
                subtitle: 'https://github.com/OPENER-next',
                onTap: () => _launchUrl(_urlCode),
              ),
              CustomListTile(
                leadingIcon: Icons.copyright,
                trailingIcon: Icons.open_in_new,
                title: 'Lizenz',
                subtitle: 'GPL-3.0',
                onTap: () => _launchUrl(_urlLicense),
              ),
              CustomListTile(
                leadingIcon: Icons.privacy_tip,
                trailingIcon: Icons.arrow_forward_ios_rounded,
                title: 'Datenschutzerklärung',
                onTap: () => Navigator.push(context, Routes.privacyPolicy),
              ),
              CustomListTile(
                leadingIcon: Icons.text_snippet,
                trailingIcon: Icons.arrow_forward_ios_rounded,
                title: 'Lizenzen verwendeter Pakete',
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
                              'assets/images/logos/BMDV_Fz_2021_Office_Farbe_de.png'),
                        )),
                    Flexible(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20.0, 50.0, 20.0, 50.0),
                          child: Image.asset(
                              'assets/images/logos/mFUND_Logo_sRGB.png'),
                        )
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      )
    );
  }
}
