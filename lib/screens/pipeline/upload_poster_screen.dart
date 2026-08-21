import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show LinearProgressIndicator;
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../models/assignment.dart';
import '../../models/client.dart';
import '../../models/festival.dart';
import '../../providers/app_state.dart';
import '../../providers/auth_state.dart';
import '../../services/share_download_service.dart';
import '../../services/upload_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/app_card.dart';
import '../../widgets/ui_kit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UploadPosterScreen extends StatefulWidget {
  const UploadPosterScreen({
    super.key,
    required this.assignment,
    this.client,
    this.festival,
  });

  final Assignment assignment;
  final Client? client;
  final Festival? festival;

  @override
  State<UploadPosterScreen> createState() => _UploadPosterScreenState();
}

class _UploadPosterScreenState extends State<UploadPosterScreen> {
  final UploadService _uploadService = UploadService();
  late final TextEditingController _notesCtrl;
  bool _uploading = false;
  double _progress = 0.0;
  bool _isDriveConnected = true;

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController(text: widget.assignment.designerNotes ?? '');
    _checkDriveConnection();
  }

  Future<void> _checkDriveConnection() async {
    final connected = await _uploadService.isDriveConnected();
    if (mounted) {
      setState(() => _isDriveConnected = connected);
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _startUpload() async {

    setState(() {
      _uploading = true;
      _progress = 0.0;
    });

    final authState = context.read<AuthState>();
    final user = authState.user;
    if (user == null) {
      _showError('Must be logged in to upload');
      setState(() => _uploading = false);
      return;
    }

    try {
      await _uploadService.startUpload(
        assignment: widget.assignment,
        festivalName: widget.festival?.name ?? 'Unknown Festival',
        festivalYear: widget.festival?.date.year.toString() ?? DateTime.now().year.toString(),
        clientName: widget.client?.name ?? 'Unknown Client',
        currentUser: user,
        onProgress: (progress) {
          if (mounted) {
            setState(() => _progress = progress);
          }
        },
      );
      
      // Save notes if any
      if (_notesCtrl.text.isNotEmpty) {
        await FirebaseFirestore.instance.collection('assignments').doc(widget.assignment.id).update({
          'designerNotes': _notesCtrl.text,
        });
      }

      // Success handled by streaming updates in UI or just closing
      // We don't await the full upload task anymore, so uploading is false
      setState(() => _uploading = false);

    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        _showError(e.toString());
      }
    }
  }

  void _showError(String message) {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Upload Error'),
        content: Text(message.replaceFirst('Exception: ', '')),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientName = widget.client?.name ?? 'Client';
    final festivalName = widget.festival?.name ?? 'Festival';

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(leading: const AppBackButton(margin: EdgeInsets.only(left: 8)), 
        backgroundColor: AppColors.background.withValues(alpha: 0.94),
        border: null,
        middle: Text(
          'Upload Poster',
          style: AppFonts.montserrat(size: 17, weight: FontWeight.w700),
        ),
      ),
      child: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('assignments').doc(widget.assignment.id).snapshots(),
          builder: (context, snapshot) {
            // Rebuild UI based on backend processing status
            String? status;
            String? previewUrl;
            String? errorMsg;
            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              status = data['posterUploadStatus'] as String?;
              previewUrl = data['posterUrl'] as String? ?? data['posterPreviewPath'] as String?;
              if (status == 'failed') {
                errorMsg = data['posterUploadError'] as String? ?? 'An unknown error occurred';
              }
            }

            final isUploading = status == 'uploading';
            final isProcessing = status == 'processing';
            final isSuccess = status == 'success';
            
            return ListView(
              padding: EdgeInsets.all(context.pagePadding),
              children: [
                Text(
                  '$clientName · $festivalName',
                  style: AppFonts.montserrat(size: 15, weight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                AppCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (previewUrl != null && previewUrl.isNotEmpty) ...[
                        if (previewUrl.toLowerCase().contains('.pdf'))
                           Container(
                             height: 160,
                             alignment: Alignment.center,
                             decoration: BoxDecoration(
                               color: AppColors.surfaceMuted,
                               borderRadius: BorderRadius.circular(16),
                             ),
                             child: Column(
                               mainAxisAlignment: MainAxisAlignment.center,
                               children: [
                                 const Icon(CupertinoIcons.doc_fill, size: 48, color: AppColors.accent),
                                 const SizedBox(height: 8),
                                 Text('PDF Document', style: AppFonts.helvetica(size: 13, color: AppColors.textTertiary)),
                                 if (previewUrl.startsWith('http') || previewUrl.startsWith('https')) 
                                    CupertinoButton(
                                      child: const Text("Open PDF"), 
                                      onPressed: () => launchUrl(Uri.parse(previewUrl!))
                                    )
                               ]
                             )
                           )
                        else 
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                                 previewUrl, 
                                 height: 220,
                                 fit: BoxFit.cover,
                                 errorBuilder: (_, __, ___) => _fallbackPreview(),
                            ),
                          ),
                        const SizedBox(height: 12),
                      ],
                      
                      if (isSuccess) ...[
                        const InfoBanner(
                          message: 'Upload completed successfully!',
                          icon: CupertinoIcons.checkmark_seal_fill,
                          color: AppColors.success,
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (errorMsg != null) ...[
                        InfoBanner(
                          message: 'Backend failed: $errorMsg',
                          icon: CupertinoIcons.xmark_circle_fill,
                          color: AppColors.overdue,
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (_uploading) ...[
                        Text('Uploading to temp storage...', style: AppFonts.helvetica(size: 13, color: AppColors.textTertiary)),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(value: _progress, color: AppColors.accent, backgroundColor: AppColors.surfaceMuted),
                        const SizedBox(height: 24),
                      ] else if (isProcessing) ...[
                        const CupertinoActivityIndicator(),
                        const SizedBox(height: 8),
                        Text('Processing in cloud...', style: AppFonts.helvetica(size: 13, color: AppColors.textTertiary), textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                      ] else ...[
                        PrimaryButton(
                          label: isSuccess ? 'Replace Poster' : (errorMsg != null ? 'Retry Upload' : 'Pick Image & Upload'),
                          icon: CupertinoIcons.photo_on_rectangle,
                          onPressed: _startUpload,
                        ),
                        if (isSuccess || previewUrl != null) ...[
                          const SizedBox(height: 12),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(CupertinoIcons.trash, size: 18, color: AppColors.overdue),
                                SizedBox(width: 8),
                                Text('Delete Design', style: TextStyle(color: AppColors.overdue, fontSize: 15, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            onPressed: () async {
                              final confirm = await showCupertinoDialog<bool>(
                                context: context,
                                builder: (ctx) => CupertinoAlertDialog(
                                  title: const Text('Delete Design?'),
                                  content: const Text('Are you sure you want to remove this design?'),
                                  actions: [
                                    CupertinoDialogAction(
                                      child: const Text('Cancel'),
                                      onPressed: () => Navigator.pop(ctx, false),
                                    ),
                                    CupertinoDialogAction(
                                      isDestructiveAction: true,
                                      child: const Text('Delete'),
                                      onPressed: () => Navigator.pop(ctx, true),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await UploadService().deletePoster(widget.assignment.id);
                              }
                            },
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],
                      
                      FormFieldBlock(
                        label: 'Notes for QC / manager',
                        child: AppTextField(
                          controller: _notesCtrl,
                          placeholder: 'Optional notes (will be saved automatically)',
                          maxLines: 3,
                          onChanged: (val) {
                            if (isSuccess) {
                              FirebaseFirestore.instance.collection('assignments').doc(widget.assignment.id).update({
                                'designerNotes': val,
                              });
                            }
                          }
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
        ),
      ),
    );
  }

  Widget _fallbackPreview() {
    return Container(
      height: 120,
      alignment: Alignment.center,
      color: AppColors.surfaceMuted,
      child: Text(
        'Preview unavailable',
        textAlign: TextAlign.center,
        style: AppFonts.helvetica(size: 13, color: AppColors.textTertiary),
      ),
    );
  }
}

