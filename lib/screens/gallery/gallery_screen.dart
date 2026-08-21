import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../models/assignment.dart';
import '../../providers/app_state.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  int? _selectedYear;
  String? _selectedFestivalId;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    // 1. Get unique years from all festivals
    final uniqueYears = state.festivals
        .map((f) => f.date.year)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // Descending

    if (_selectedYear == null && uniqueYears.isNotEmpty) {
      _selectedYear = uniqueYears.first;
    }

    // 2. Get festivals for selected year
    final festivalsForYear = state.festivals
        .where((f) => f.date.year == _selectedYear)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Ensure selected festival is valid for this year
    if (_selectedFestivalId != null &&
        !festivalsForYear.any((f) => f.id == _selectedFestivalId)) {
      _selectedFestivalId = null;
    }

    // Default to 'all' if none selected
    if (_selectedFestivalId == null && festivalsForYear.isNotEmpty) {
      _selectedFestivalId = 'all';
    }

    // 3. Filter assignments with posters for the selected year & festival
    List<Assignment> galleryItems = [];
    if (_selectedFestivalId != null) {
      galleryItems = state.assignments.where((a) {
        if (!a.hasPoster) return false;
        if (_selectedFestivalId == 'all') {
          return festivalsForYear.any((f) => f.id == a.festivalId);
        }
        return a.festivalId == _selectedFestivalId;
      }).toList();
    }

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: const CupertinoNavigationBar(backgroundColor: Color(0x00000000), border: null, leading: AppBackButton(margin: EdgeInsets.only(left: 8))),
      child: SafeArea(
        bottom: false,
        child: ResponsiveContent(
          child: Column(
            children: [
            PageHeader(
              title: 'Design Gallery',
              subtitle: 'View all uploaded designs by year and festival',
              trailing: galleryItems.isNotEmpty
                  ? NavBarActionButton(
                      label: 'Download All',
                      icon: CupertinoIcons.arrow_down_circle,
                      onPressed: () async {
                        for (final assignment in galleryItems) {
                          if (assignment.posterUrl != null && assignment.posterUrl!.isNotEmpty) {
                            String url = assignment.posterUrl!;
                            if (url.contains('res.cloudinary.com') && url.contains('/upload/')) {
                              url = url.replaceFirst('/upload/', '/upload/fl_attachment/');
                            }
                            final uri = Uri.parse(url);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                              // Delay to prevent browser from blocking multiple popups/downloads
                              await Future.delayed(const Duration(milliseconds: 600));
                            }
                          }
                        }
                      },
                    )
                  : null,
            ),
            
            // Year Selector
            if (uniqueYears.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.pagePadding, vertical: 8),
                child: SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: uniqueYears.length,
                    itemBuilder: (context, index) {
                      final year = uniqueYears[index];
                      return FilterChipPill(
                        label: year.toString(),
                        selected: _selectedYear == year,
                        onTap: () {
                          setState(() {
                            _selectedYear = year;
                            _selectedFestivalId = null;
                          });
                        },
                      );
                    },
                  ),
                ),
              ),

            // Festival Selector
            if (festivalsForYear.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.pagePadding, vertical: 8),
                child: SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      FilterChipPill(
                        label: 'All Festivals',
                        selected: _selectedFestivalId == 'all',
                        onTap: () {
                          setState(() {
                            _selectedFestivalId = 'all';
                          });
                        },
                      ),
                      ...festivalsForYear.map((fest) {
                        return FilterChipPill(
                          label: fest.name,
                          selected: _selectedFestivalId == fest.id,
                          onTap: () {
                            setState(() {
                              _selectedFestivalId = fest.id;
                            });
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ),

            Expanded(
              child: _selectedFestivalId == null
                  ? const EmptyState(
                      icon: CupertinoIcons.calendar,
                      title: 'No festivals',
                      message: 'Select a year with festivals to view designs.',
                    )
                  : (galleryItems.isEmpty && !state.hasMoreAssignments)
                      ? const EmptyState(
                          icon: CupertinoIcons.photo_on_rectangle,
                          title: 'No designs yet',
                          message: 'Designs uploaded for this festival will appear here.',
                        )
                      : GridView.builder(
                          padding: EdgeInsets.fromLTRB(
                            context.pagePadding,
                            8,
                            context.pagePadding,
                            context.listBottomPadding,
                          ),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: context.screenWidth > 800 ? 4 : context.screenWidth > 500 ? 3 : 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: galleryItems.length + 1,
                          itemBuilder: (context, index) {
                            if (index == galleryItems.length) {
                              if (state.hasMoreAssignments) {
                                return GestureDetector(
                                  onTap: () => state.loadMoreAssignments(),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.borderSubtle),
                                    ),
                                    child: Center(
                                      child: state.loadingMoreAssignments
                                          ? const CupertinoActivityIndicator()
                                          : Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(CupertinoIcons.arrow_down, color: AppColors.accent),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Load More',
                                                  style: AppFonts.poppins(size: 13, weight: FontWeight.w600, color: AppColors.accent),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                );
                              } else {
                                return const SizedBox.shrink();
                              }
                            }

                            final assignment = galleryItems[index];
                            final client = state.clientById(assignment.clientId);
                            return _GalleryItemCard(
                              assignment: assignment,
                              clientName: client?.name ?? 'Unknown Client',
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    ),
  );
}
}

class _GalleryItemCard extends StatelessWidget {
  const _GalleryItemCard({
    required this.assignment,
    required this.clientName,
  });

  final Assignment assignment;
  final String clientName;

  @override
  Widget build(BuildContext context) {
    final hasUrl = assignment.posterUrl != null && assignment.posterUrl!.isNotEmpty;
    return GestureDetector(
      onTap: () async {
        if (hasUrl) {
          final uri = Uri.parse(assignment.posterUrl!);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: AppShadows.soft,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: hasUrl
                  ? Image.network(
                      assignment.posterUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(CupertinoIcons.photo, size: 40, color: AppColors.textTertiary),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CupertinoActivityIndicator());
                      },
                    )
                  : const Center(
                      child: Icon(CupertinoIcons.photo, size: 40, color: AppColors.textTertiary),
                    ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              color: AppColors.surfaceMuted,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clientName,
                    style: AppFonts.poppins(size: 13, weight: FontWeight.w600, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    assignment.status.label,
                    style: AppFonts.helvetica(size: 11, color: AppColors.textTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


