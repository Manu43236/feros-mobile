import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../controllers/supervisor_profile_controller.dart';

class SupervisorProfileDocsView extends StatefulWidget {
  const SupervisorProfileDocsView({super.key});

  @override
  State<SupervisorProfileDocsView> createState() => _State();
}

class _State extends State<SupervisorProfileDocsView> {
  final _ctrl = Get.find<SupervisorProfileController>();
  final _api  = Get.find<ApiClient>();

  List<Map<String, dynamic>> _docTypes = [];

  @override
  void initState() {
    super.initState();
    _ctrl.fetchDocuments();
    _loadDocTypes();
  }

  Future<void> _loadDocTypes() async {
    try {
      final res = await _api.get(ApiEndpoints.documentTypes);
      setState(() {
        _docTypes = ((res.data as Map<String, dynamic>)['data'] as List)
            .cast<Map<String, dynamic>>()
            .where((t) => t['applicableFor'] != 'VEHICLE')
            .toList();
      });
    } catch (_) {}
  }

  void _showAddSheet() => showModalBottomSheet(
        useSafeArea: true,
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => _AddDocSheet(ctrl: _ctrl, docTypes: _docTypes),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        title: const Text('My Documents',
            style: TextStyle(color: Colors.white, fontFamily: 'Inter',
                fontWeight: FontWeight.w600, fontSize: 16)),
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showAddSheet,
          ),
        ],
      ),
      body: Obx(() {
        if (_ctrl.isLoadingDocs.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.navy));
        }
        final docs = _ctrl.documents;
        if (docs.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.folder_outlined, size: 52, color: AppColors.mutedText),
              const SizedBox(height: 12),
              Text('No documents yet',
                  style: AppTextStyles.body.copyWith(color: AppColors.mutedText)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _showAddSheet,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Document'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ]),
          );
        }
        return RefreshIndicator(
          color: AppColors.navy,
          onRefresh: _ctrl.fetchDocuments,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (_, i) => _DocCard(doc: docs[i]),
          ),
        );
      }),
    );
  }
}

// ── Doc Card ──────────────────────────────────────────────────────────────────
class _DocCard extends StatelessWidget {
  final Map<String, dynamic> doc;
  const _DocCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final typeName    = doc['documentTypeName'] as String? ?? '—';
    final docNumber   = doc['documentNumber']   as String?;
    final expiryDate  = doc['expiryDate']        as String?;
    final fileUrl     = doc['fileUrl']            as String?;
    final isVerified  = doc['isVerified']         as bool? ?? false;

    Color? expiryColor;
    String? expiryLabel;
    if (expiryDate != null) {
      final exp = DateTime.tryParse(expiryDate);
      if (exp != null) {
        final days = exp.difference(DateTime.now()).inDays;
        if (days < 0) {
          expiryColor = AppColors.error; expiryLabel = 'Expired';
        } else if (days <= 30) {
          expiryColor = const Color(0xFFF59E0B); expiryLabel = 'Due soon';
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: AppColors.navy.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.description_outlined, color: AppColors.navy, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(typeName,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.navy,
                  fontWeight: FontWeight.w600)),
          if (docNumber != null) ...[
            const SizedBox(height: 2),
            Text(docNumber,
                style: AppTextStyles.caption.copyWith(color: AppColors.mutedText)),
          ],
          if (expiryDate != null) ...[
            const SizedBox(height: 2),
            Row(children: [
              Text('Exp: $expiryDate',
                  style: AppTextStyles.caption.copyWith(
                      color: expiryColor ?? AppColors.mutedText)),
              if (expiryLabel != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: expiryColor!.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(expiryLabel,
                      style: TextStyle(fontFamily: 'Inter', fontSize: 10,
                          fontWeight: FontWeight.w600, color: expiryColor)),
                ),
              ],
            ]),
          ],
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min,
            children: [
          if (isVerified)
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.verified, size: 14, color: Color(0xFF16A34A)),
              const SizedBox(width: 3),
              Text('Verified',
                  style: AppTextStyles.caption.copyWith(color: const Color(0xFF16A34A),
                      fontWeight: FontWeight.w600)),
            ]),
          if (fileUrl != null) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => launchUrl(Uri.parse(fileUrl),
                  mode: LaunchMode.externalApplication),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.open_in_new, size: 14, color: AppColors.navy),
                const SizedBox(width: 3),
                Text('View', style: AppTextStyles.caption.copyWith(
                    color: AppColors.navy, fontWeight: FontWeight.w600)),
              ]),
            ),
          ],
        ]),
      ]),
    );
  }
}

// ── Add Doc Sheet ─────────────────────────────────────────────────────────────
class _AddDocSheet extends StatefulWidget {
  final SupervisorProfileController ctrl;
  final List<Map<String, dynamic>> docTypes;
  const _AddDocSheet({required this.ctrl, required this.docTypes});

  @override
  State<_AddDocSheet> createState() => _AddDocSheetState();
}

class _AddDocSheetState extends State<_AddDocSheet> {
  int?    _docTypeId;
  String  _docNumber  = '';
  String  _issueDate  = '';
  String  _expiryDate = '';
  // ignore: prefer_final_fields
  String  _remarks    = '';
  File?   _file;

  Future<void> _pickFile() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _file = File(picked.path));
  }

  Future<void> _submit() async {
    if (_docTypeId == null) return;
    final ok = await widget.ctrl.addDocument(
      documentTypeId: _docTypeId!,
      documentNumber: _docNumber,
      issueDate: _issueDate,
      expiryDate: _expiryDate,
      remarks: _remarks,
      file: _file,
    );
    if (ok && mounted) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16,
          16 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4,
            decoration: BoxDecoration(color: AppColors.border,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 14),
        Text('Add Document',
            style: AppTextStyles.heading3.copyWith(color: AppColors.navy)),
        const SizedBox(height: 16),

        // document type
        InputDecorator(
          decoration: InputDecoration(
            labelText: 'Document Type *',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            isDense: true,
          ),
          child: DropdownButton<int>(
            value: _docTypeId,
            isExpanded: true,
            underline: const SizedBox(),
            hint: const Text('Select type',
                style: TextStyle(fontFamily: 'Inter', fontSize: 14)),
            items: widget.docTypes.map((t) => DropdownMenuItem<int>(
              value: t['id'] as int?,
              child: Text(t['name'] as String? ?? '',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14)),
            )).toList(),
            onChanged: (v) => setState(() => _docTypeId = v),
          ),
        ),
        const SizedBox(height: 12),

        TextField(
          onChanged: (v) => _docNumber = v,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            labelText: 'Document Number',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),

        Row(children: [
          Expanded(child: _datePicker(context, 'Issue Date', _issueDate,
              (v) => setState(() => _issueDate = v))),
          const SizedBox(width: 10),
          Expanded(child: _datePicker(context, 'Expiry Date', _expiryDate,
              (v) => setState(() => _expiryDate = v))),
        ]),
        const SizedBox(height: 12),

        // file picker
        GestureDetector(
          onTap: _pickFile,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              border: Border.all(color: _file != null ? AppColors.navy : AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              Icon(_file != null ? Icons.attach_file : Icons.upload_outlined,
                  size: 18, color: _file != null ? AppColors.navy : AppColors.mutedText),
              const SizedBox(width: 8),
              Expanded(child: Text(
                _file != null ? _file!.path.split('/').last : 'Attach file (optional)',
                style: AppTextStyles.caption.copyWith(
                    color: _file != null ? AppColors.navy : AppColors.mutedText),
                overflow: TextOverflow.ellipsis,
              )),
            ]),
          ),
        ),
        const SizedBox(height: 20),

        Obx(() => SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_docTypeId != null && !widget.ctrl.isAddingDoc.value)
                ? _submit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.navy.withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: widget.ctrl.isAddingDoc.value
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save Document',
                    style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
          ),
        )),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _datePicker(BuildContext context, String label, String value,
      ValueChanged<String> onChanged) =>
      GestureDetector(
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: value.isNotEmpty
                ? DateTime.tryParse(value) ?? DateTime.now()
                : DateTime.now(),
            firstDate: DateTime(1950),
            lastDate: DateTime(2100),
          );
          if (d != null) onChanged(d.toIso8601String().substring(0, 10));
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 14),
          ),
          child: Text(value.isEmpty ? '—' : value,
              style: AppTextStyles.body.copyWith(
                  color: value.isEmpty ? AppColors.mutedText : AppColors.bodyText)),
        ),
      );
}
