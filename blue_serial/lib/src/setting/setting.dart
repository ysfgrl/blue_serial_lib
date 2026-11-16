import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../extensions/flag.dart';
import '../helper/command_card.dart';
import '../helper/serial.dart';
import '../models/input_mode.dart';
import '../models/serial_command.dart';
import '../store/serial.dart';

part 'saved_commands_section.dart';
part 'edit_saved_command_dialog.dart';
part 'delete_command.dart';
part 'about_section.dart';

class Setting extends StatelessWidget {
  const Setting({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: BackButton(onPressed: () => context.go('/')),
      title: Text(context.tr('setting.title')),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                context.tr('setting.applicationLanguage'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Locale>(
                initialValue: context.locale,
                decoration: InputDecoration(
                  labelText: context.tr('setting.language'),
                  prefixIcon: const Icon(Icons.language),
                ),
                items: [
                  for (final locale in context.supportedLocales)
                    DropdownMenuItem(
                      value: locale,
                      child: Text('${locale.flag()} ${locale.name()}'),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  context.setLocale(value);
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Divider(height: 1),
              ),
              const _SavedCommandsSection(),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Divider(height: 1),
              ),
              const _AboutSection(),
            ],
          ),
        ),
      ),
    ),
  );
}
