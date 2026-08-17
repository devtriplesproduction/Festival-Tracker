import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../models/deadline_config.dart';
import '../../providers/app_state.dart';

class DeadlineSettingsScreen extends StatefulWidget {
  const DeadlineSettingsScreen({super.key});

  @override
  State<DeadlineSettingsScreen> createState() => _DeadlineSettingsScreenState();
}

class _DeadlineSettingsScreenState extends State<DeadlineSettingsScreen> {
  late int _design;
  late int _qc;
  late int _ready;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = context.read<AppState>().deadlineConfig;
    _design = c.designDaysBefore;
    _qc = c.qcDaysBefore;
    _ready = c.readyDaysBefore;
  }

  Future<void> _save() async {
    if (_design <= _qc || _qc <= _ready || _ready <= 0) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Invalid offsets'),
          content: const Text(
            'Keep order: Design > QC > Ready > Send (0).\nExample: 3, 2, 1.',
          ),
          actions: [
            CupertinoDialogAction(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    setState(() => _saving = true);
    await context.read<AppState>().saveDeadlineOffsets(
          DeadlineOffsetConfig(
            designDaysBefore: _design,
            qcDaysBefore: _qc,
            readyDaysBefore: _ready,
            sendDaysBefore: 0,
          ),
        );
    if (!mounted) return;
    setState(() {
      _saving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully')),
    );
  }

  void _resetDefaults() {
    setState(() {
      _design = DeadlineOffsetConfig.defaults.designDaysBefore;
      _qc = DeadlineOffsetConfig.defaults.qcDaysBefore;
      _ready = DeadlineOffsetConfig.defaults.readyDaysBefore;
    });
  }

  Widget _buildTimelinePreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Workflow timeline preview', style: AppFonts.montserrat(size: 16, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('This is how your workflow looks before the event day.', style: AppFonts.helvetica(size: 13, color: AppColors.textSecondary)),
              ],
            ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.remove_red_eye, size: 16, color: AppColors.purple),
              label: Text('View example', style: AppFonts.poppins(color: AppColors.purple, weight: FontWeight.w600, size: 13)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.purpleSoft),
                backgroundColor: AppColors.purpleSoft,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TimelineNode(title: 'Design', days: _design, color: AppColors.accent, icon: CupertinoIcons.paintbrush_fill),
                const _TimelineConnector(),
                _TimelineNode(title: 'QC Review', days: _qc, color: AppColors.purple, icon: CupertinoIcons.search),
                const _TimelineConnector(),
                _TimelineNode(title: 'Ready', days: _ready, color: AppColors.teal, icon: CupertinoIcons.cube_box_fill),
                const _TimelineConnector(),
                _TimelineNode(title: 'Send', days: 0, color: AppColors.textSecondary, icon: CupertinoIcons.location_fill),
                const _TimelineConnector(),
                const _EventDayNode(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final isCompact = context.isCompact;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.pagePadding,
        vertical: isCompact ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.borderSubtle)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _resetDefaults,
                icon: const Icon(Icons.refresh, size: 18, color: AppColors.textPrimary),
                label: Text(
                  isCompact ? 'Reset' : 'Reset to defaults',
                  style: AppFonts.montserrat(color: AppColors.textPrimary, size: 14, weight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: isCompact ? 14 : 16),
                  side: const BorderSide(color: AppColors.borderSubtle),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined, size: 18, color: Colors.white),
                label: Text(
                  isCompact ? 'Save & recalculate' : 'Save & recalculate jobs',
                  style: AppFonts.montserrat(color: Colors.white, size: 14, weight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  padding: EdgeInsets.symmetric(vertical: isCompact ? 14 : 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = context.pagePadding;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Deadline Settings',
          style: AppFonts.montserrat(size: 18, weight: FontWeight.w700),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: ResponsiveContent(
        maxWidth: 840,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(padding),
                children: [
                  Text(
                    'Deadline Configuration',
                    style: AppFonts.montserrat(size: context.isCompact ? 20 : 22, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Configure when each stage should be completed before the festival date.',
                    style: AppFonts.helvetica(size: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  _buildTimelinePreview(),
                  const SizedBox(height: 32),
                  Text('Workflow stages', style: AppFonts.montserrat(size: 18, weight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Adjust the number of days for each stage.', style: AppFonts.helvetica(size: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  _WorkflowStageCard(
                    title: 'Design',
                    subtitle: 'Designer completes the artwork',
                    days: _design,
                    icon: CupertinoIcons.paintbrush_fill,
                    color: AppColors.accent,
                    min: 1,
                    max: 30,
                    onChanged: (v) {
                      if (v > _qc) setState(() => _design = v);
                    },
                    showAutoUpdateBadge: true,
                  ),
                  const SizedBox(height: 14),
                  _WorkflowStageCard(
                    title: 'QC Review',
                    subtitle: 'Review and approve the poster',
                    days: _qc,
                    icon: CupertinoIcons.search,
                    color: AppColors.purple,
                    min: 1,
                    max: 30,
                    onChanged: (v) {
                      if (v < _design && v > _ready) setState(() => _qc = v);
                    },
                  ),
                  const SizedBox(height: 14),
                  _WorkflowStageCard(
                    title: 'Ready',
                    subtitle: 'Poster ready for client delivery',
                    days: _ready,
                    icon: CupertinoIcons.cube_box_fill,
                    color: AppColors.teal,
                    min: 1,
                    max: 30,
                    onChanged: (v) {
                      if (v < _qc && v > 0) setState(() => _ready = v);
                    },
                  ),
                  const SizedBox(height: 14),
                  const _FixedSendCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }
}

class _TimelineNode extends StatelessWidget {
  const _TimelineNode({required this.title, required this.days, required this.color, required this.icon});
  final String title;
  final int days;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppFonts.montserrat(color: color, size: 12, weight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              '$days d',
              style: AppFonts.montserrat(color: color, size: 11, weight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'before event',
            textAlign: TextAlign.center,
            style: AppFonts.helvetica(size: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _EventDayNode extends StatelessWidget {
  const _EventDayNode();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.overdueSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.calendar, color: AppColors.overdue, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            'Event Day',
            textAlign: TextAlign.center,
            style: AppFonts.montserrat(color: AppColors.textPrimary, size: 12, weight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.overdueSoft,
            ),
            child: Text(
              'Day 0',
              style: AppFonts.montserrat(color: AppColors.overdue, size: 11, weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineConnector extends StatelessWidget {
  const _TimelineConnector();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 2,
      margin: const EdgeInsets.only(top: 22),
      color: AppColors.borderSubtle,
    );
  }
}

class _WorkflowStageCard extends StatelessWidget {
  const _WorkflowStageCard({
    required this.title,
    required this.subtitle,
    required this.days,
    required this.icon,
    required this.color,
    required this.min,
    required this.max,
    required this.onChanged,
    this.showAutoUpdateBadge = false,
  });

  final String title;
  final String subtitle;
  final int days;
  final IconData icon;
  final Color color;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final bool showAutoUpdateBadge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 540;

          final badgeWidget = showAutoUpdateBadge
              ? Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.purpleSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sync, size: 14, color: AppColors.purple),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Auto-updates all future assignments',
                          style: AppFonts.helvetica(size: 11, color: AppColors.purple, weight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink();

          final stepperWidget = Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderSubtle),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: days > min ? () => onChanged(days - 1) : null,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Icon(Icons.remove, size: 16, color: days > min ? AppColors.textPrimary : AppColors.borderSubtle),
                  ),
                ),
                Container(width: 1, height: 22, color: AppColors.borderSubtle),
                InkWell(
                  onTap: days < max ? () => onChanged(days + 1) : null,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Icon(Icons.add, size: 16, color: days < max ? AppColors.textPrimary : AppColors.borderSubtle),
                  ),
                ),
              ],
            ),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: AppFonts.montserrat(size: 15, weight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(subtitle, style: AppFonts.helvetica(size: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text('$days', style: AppFonts.montserrat(size: 22, weight: FontWeight.w700, color: color)),
                            const SizedBox(width: 3),
                            Text('days', style: AppFonts.helvetica(size: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                        Text('before event', style: AppFonts.helvetica(size: 10, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
                if (showAutoUpdateBadge) badgeWidget,
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                        ),
                        child: Slider(
                          value: days.toDouble(),
                          min: 1,
                          max: 30,
                          activeColor: color,
                          inactiveColor: AppColors.borderSubtle,
                          onChanged: (v) => onChanged(v.toInt()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    stepperWidget,
                  ],
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppFonts.montserrat(size: 16, weight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppFonts.helvetica(size: 13, color: AppColors.textSecondary)),
                    if (showAutoUpdateBadge) badgeWidget,
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Days before event', style: AppFonts.helvetica(size: 12, color: AppColors.textSecondary)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('$days', style: AppFonts.montserrat(size: 26, weight: FontWeight.w700, color: color)),
                      const SizedBox(width: 4),
                      Text('days', style: AppFonts.helvetica(size: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 130,
                        child: Slider(
                          value: days.toDouble(),
                          min: 1,
                          max: 30,
                          activeColor: color,
                          inactiveColor: AppColors.borderSubtle,
                          onChanged: (v) => onChanged(v.toInt()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      stepperWidget,
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FixedSendCard extends StatelessWidget {
  const _FixedSendCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 540;

          final fixedBadge = Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.successSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 14, color: AppColors.success),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Fixed', style: AppFonts.montserrat(size: 11, weight: FontWeight.w700, color: AppColors.success)),
                    Text('Cannot be changed', style: AppFonts.helvetica(size: 10, color: AppColors.success)),
                  ],
                ),
              ],
            ),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.borderSubtle.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(CupertinoIcons.location_fill, color: AppColors.textSecondary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Send', style: AppFonts.montserrat(size: 15, weight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text('Fixed day for final send to client', style: AppFonts.helvetica(size: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text('0', style: AppFonts.montserrat(size: 22, weight: FontWeight.w700, color: AppColors.textSecondary)),
                            const SizedBox(width: 3),
                            Text('days', style: AppFonts.helvetica(size: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                        Text('before event', style: AppFonts.helvetica(size: 10, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                fixedBadge,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.borderSubtle.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(CupertinoIcons.location_fill, color: AppColors.textSecondary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Send', style: AppFonts.montserrat(size: 16, weight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('Fixed day for final send to client', style: AppFonts.helvetica(size: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Days before event', style: AppFonts.helvetica(size: 12, color: AppColors.textSecondary)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('0', style: AppFonts.montserrat(size: 26, weight: FontWeight.w700, color: AppColors.textSecondary)),
                      const SizedBox(width: 4),
                      Text('days', style: AppFonts.helvetica(size: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  fixedBadge,
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
