import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../models/user_role.dart';
import '../../providers/app_state.dart';
import '../../providers/auth_state.dart';
import '../../widgets/ui_kit.dart';
import '../clients/clients_screen.dart';
import '../gallery/gallery_screen.dart';
import '../packages/packages_screen.dart';
import '../settings/deadline_settings_screen.dart';
import '../team/team_screen.dart';

/// Consolidated Studio Management hub holding Clients, Packages, Gallery, Team & Deadline Settings.
class StudioManagementScreen extends StatelessWidget {
  const StudioManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final app = context.watch<AppState>();
    final role = auth.role ?? UserRole.designer;
    final p = context.pagePadding;

    final clientCount = app.clients.length;
    final packageCount = app.clientPackages.length;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(leading: const AppBackButton(margin: EdgeInsets.only(left: 8)), 
        backgroundColor: AppColors.surface.withValues(alpha: 0.92),
        border: const Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.6),
        ),
        middle: Text(
          'Studio Management',
          style: AppFonts.montserrat(
            size: 17,
            weight: FontWeight.w700,
          ),
        ),
      ),
      child: SafeArea(
        child: ResponsiveContent(
          maxWidth: 800,
          child: ListView(
            padding: EdgeInsets.fromLTRB(p, 16, p, context.listBottomPadding),
            children: [
              // Hero Overview Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.accent,
                      Color(0xFF88003E),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0x2EFFFFFF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            CupertinoIcons.square_grid_2x2_fill,
                            color: Color(0xFFFFFFFF),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Studio Operations',
                                style: AppFonts.montserrat(
                                  size: 18,
                                  weight: FontWeight.w800,
                                  color: const Color(0xFFFFFFFF),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Configure clients, team, packages & schedules',
                                style: AppFonts.poppins(
                                  size: 12,
                                  color: const Color(0xDDFFFFFF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'MANAGEMENT MODULES',
                style: AppFonts.montserrat(
                  size: 12,
                  weight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),

              // Modules List / Grid
              if (role.canViewClients) ...[
                _ManagementCard(
                  icon: CupertinoIcons.person_2_fill,
                  title: 'Clients',
                  subtitle: 'Manage client accounts, preferences & contacts',
                  badge: clientCount > 0 ? '$clientCount Active' : null,
                  badgeColor: const Color(0xFF0284C7),
                  gradientColors: const [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
                  iconColor: const Color(0xFF0284C7),
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(builder: (_) => const ClientsScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],

              if (role.canViewPackages) ...[
                _ManagementCard(
                  icon: CupertinoIcons.cube_box_fill,
                  title: 'Packages',
                  subtitle: 'Client festival packages, pricing & delivery quotas',
                  badge: packageCount > 0 ? '$packageCount Configured' : null,
                  badgeColor: const Color(0xFF7C3AED),
                  gradientColors: const [Color(0xFFF3E8FF), Color(0xFFE9D5FF)],
                  iconColor: const Color(0xFF7C3AED),
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(builder: (_) => const PackagesScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],

              if (role.canManageTeam) ...[
                _ManagementCard(
                  icon: CupertinoIcons.photo_fill_on_rectangle_fill,
                  title: 'Poster Gallery',
                  subtitle: 'Browse & preview all completed festival posters',
                  gradientColors: const [Color(0xFFFCE7F3), Color(0xFFFBCFE8)],
                  iconColor: const Color(0xFFDB2777),
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(builder: (_) => const GalleryScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),

                _ManagementCard(
                  icon: CupertinoIcons.person_3_fill,
                  title: 'Team Members',
                  subtitle: 'Invite and manage designers, managers & roles',
                  gradientColors: const [Color(0xFFDCFCE7), Color(0xFFBBF7D0)],
                  iconColor: const Color(0xFF16A34A),
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(builder: (_) => const TeamScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],

              if (role.canManageSettings) ...[
                _ManagementCard(
                  icon: CupertinoIcons.slider_horizontal_3,
                  title: 'Deadline Settings',
                  subtitle: 'Configure automated production lead times (Design/QC/Ready)',
                  gradientColors: const [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                  iconColor: const Color(0xFFD97706),
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(builder: (_) => const DeadlineSettingsScreen()),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ManagementCard extends StatelessWidget {
  const _ManagementCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.iconColor,
    required this.onTap,
    this.badge,
    this.badgeColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final Color iconColor;
  final VoidCallback onTap;
  final String? badge;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider, width: 1.2),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          splashColor: iconColor.withValues(alpha: 0.08),
          highlightColor: iconColor.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: AppFonts.montserrat(
                                size: 16,
                                weight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: (badgeColor ?? iconColor).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                badge!,
                                style: AppFonts.poppins(
                                  size: 11,
                                  weight: FontWeight.w600,
                                  color: badgeColor ?? iconColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: AppFonts.poppins(
                          size: 12.5,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    CupertinoIcons.chevron_forward,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

