part of 'serial_monitor.dart';

class MonitorHeader extends StatelessWidget {
  const MonitorHeader({
    super.key,
    required this.type,
    required this.onTypeChanged,
    this.compact = false,
  });

  final MonitorType type;
  final ValueChanged<MonitorType>? onTypeChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            context.tr('global.appTitle'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 18 : 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -.6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 88,
          child: SegmentedButton<MonitorType>(
            key: const Key('monitor-type'),
            expandedInsets: EdgeInsets.zero,
            segments: [
              ButtonSegment(
                value: MonitorType.normal,
                icon: const Icon(Icons.list_alt_rounded, size: 18),
                tooltip: context.tr('global.normal'),
              ),
              ButtonSegment(
                value: MonitorType.terminal,
                icon: const Icon(Icons.terminal_rounded, size: 18),
                tooltip: context.tr('global.terminal'),
              ),
            ],
            selected: {type},
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              maximumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 4),

              tapTargetSize: MaterialTapTargetSize.padded,
            ),
            onSelectionChanged: onTypeChanged == null
                ? null
                : (selection) => onTypeChanged!(selection.single),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          key: const Key('monitor-settings-button'),
          tooltip: context.tr('setting.title'),
          onPressed: () => context.go('/setting'),
          icon: const Icon(Icons.settings_outlined, size: 20),
        ),
      ],
    );
  }
}
