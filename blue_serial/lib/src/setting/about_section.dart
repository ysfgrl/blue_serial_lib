part of 'setting.dart';

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  static final _repository = Uri.parse(
    'https://github.com/ysfgrl/blue_serial_lib',
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      key: const Key('setting-about'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr('setting.about'),
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Material(
          color: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.dividerColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Icon(Icons.code_rounded, size: 22, color: colors.primary),
                    Text(
                      'Open Source',
                      style: theme.textTheme.titleSmall,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        context.tr('setting.mitLicense'),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  context.tr('setting.aboutDescription'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  key: const Key('about-github-link'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('GitHub'),
                  subtitle: Text(
                    _repository.toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.primary,
                    ),
                  ),
                  trailing: Icon(
                    Icons.open_in_new_rounded,
                    size: 18,
                    color: colors.primary,
                  ),
                  onTap: () => {},
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          context.tr('setting.madeWithCare'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'ysfgr © 2026',
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium?.copyWith(color: colors.primary),
        ),
      ],
    );
  }
}
