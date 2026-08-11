import 'package:flutter/material.dart';
import 'package:pure_music/core/design_tokens.dart';

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.description,
    required this.action,
    this.subtitle,
  });

  final String description;
  final String? subtitle;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final descriptionView = _SettingsTileDescription(
      description: description,
      subtitle: subtitle,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: descriptionView),
        const SizedBox(width: 16.0),
        Flexible(
          child: Align(
            alignment: Alignment.centerRight,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: action,
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsTileDescription extends StatelessWidget {
  const _SettingsTileDescription({
    required this.description,
    required this.subtitle,
  });

  final String description;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          description,
          style: TextStyle(color: scheme.onSurface, fontSize: AppType.sectionTitle),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              subtitle!,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: AppType.body,
              ),
            ),
          ),
      ],
    );
  }
}
