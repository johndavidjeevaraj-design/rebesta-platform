import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/delivery_api_client.dart';

// ============================================================
// KYC VERIFICATION
// ============================================================
//
// Swiggy-style rider verification:
//   1. Upload 4 documents (Aadhaar front/back, driving license,
//      selfie) - camera or gallery
//   2. The last upload submits the KYC for admin review
//   3. Status: pending / submitted / verified / rejected
//   4. Rejection shows the reason and unlocks re-uploads
// ============================================================

class DeliveryKycScreen extends StatefulWidget {
  const DeliveryKycScreen({super.key});

  @override
  State<DeliveryKycScreen> createState() =>
      _DeliveryKycScreenState();
}

class _DeliveryKycScreenState
    extends State<DeliveryKycScreen> {
  // ============================================================
  // STATE
  // ============================================================

  bool _loading = true;

  String? _error;

  String _status = 'pending';

  String? _rejectionReason;

  // document type -> document info

  Map<String, dynamic> _documents = {};

  bool _uploading = false;

  // ============================================================
  // REQUIRED DOCUMENTS
  // ============================================================

  static const List<(String, String, IconData)>
      _documentTypes = [
    (
      'aadhaar_front',
      'Aadhaar Card\n(Front)',
      Icons.badge_outlined,
    ),
    (
      'aadhaar_back',
      'Aadhaar Card\n(Back)',
      Icons.badge_outlined,
    ),
    (
      'driving_license',
      'Driving\nLicense',
      Icons.two_wheeler_outlined,
    ),
    (
      'selfie',
      'Your\nPhoto',
      Icons.person_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadKyc();
  }

  // ============================================================
  // LOAD KYC
  // ============================================================

  Future<void> _loadKyc() async {
    try {
      final options =
          await DeliveryApiClient.authOptions();

      final response =
          await DeliveryApiClient.dio.get(
        ApiConstants.kyc,
        options: options,
      );

      final kyc = response.data['kyc'] ?? {};

      final documents =
          (kyc['documents'] as List?) ?? [];

      final byType = <String, dynamic>{};

      for (final doc in documents) {
        if (doc is Map) {
          byType['${doc['type']}'] = doc;
        }
      }

      if (!mounted) return;

      setState(() {
        _status = '${kyc['status'] ?? 'pending'}';
        _rejectionReason = kyc['rejectionReason'];
        _documents = byType;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      debugPrint(
        '❌ KYC LOAD ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error =
            'Could not load your KYC status. Make sure the '
            'KYC database migration has been run, then retry.';
      });
    }
  }

  // ============================================================
  // UPLOAD DOCUMENT
  // ============================================================

  Future<void> _pickAndUpload(
    String documentType,
  ) async {
    if (_uploading) return;

    final source = await showModalBottomSheet<
            ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),

            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: Color(0xFFFF6B35),
              ),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(sheetContext)
                  .pop(ImageSource.camera),
            ),

            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: Color(0xFFFF6B35),
              ),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(sheetContext)
                  .pop(ImageSource.gallery),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final picker = ImagePicker();

      final file = await picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (file == null) return;

      if (!mounted) return;

      setState(() {
        _uploading = true;
      });

      final options =
          await DeliveryApiClient.authOptionsUpload();

      final form = FormData.fromMap({
        'document_type': documentType,
        'document': await MultipartFile.fromFile(
          file.path,
          filename:
              '$documentType-${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      await DeliveryApiClient.dio.post(
        ApiConstants.kycDocuments,
        data: form,
        options: options,
      );

      if (!mounted) return;

      setState(() {
        _uploading = false;
      });

      await _loadKyc();
    } catch (e) {
      debugPrint(
        '❌ KYC UPLOAD ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _uploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Upload failed: ${_dioError(e)}',
          ),
          backgroundColor: const Color(0xFFC0392B),
        ),
      );
    }
  }

  String _dioError(
    Object error,
  ) {
    if (error is DioException) {
      final data = error.response?.data;

      if (data is Map) {
        return '${data['message'] ?? 'Please try again'}';
      }
    }

    return 'Please try again';
  }

  // ============================================================
  // STATUS BANNER
  // ============================================================

  Widget _statusBanner() {
    final isVerified = _status == 'verified';
    final isSubmitted = _status == 'submitted';
    final isRejected = _status == 'rejected';

    final Color color;
    final IconData icon;
    final String title;
    final String subtitle;

    if (isVerified) {
      color = const Color(0xFF1D9E55);
      icon = Icons.verified_rounded;
      title = 'Verified!';
      subtitle =
          'Your KYC is complete. You are all set to deliver.';
    } else if (isSubmitted) {
      color = const Color(0xFFB7791F);
      icon = Icons.hourglass_top_rounded;
      title = 'Under Review';
      subtitle =
          'We usually verify within 24 hours. '
          'You can keep delivering meanwhile.';
    } else if (isRejected) {
      color = const Color(0xFFC0392B);
      icon = Icons.error_outline_rounded;
      title = 'KYC Rejected';
      subtitle =
          _rejectionReason ??
              'Please re-upload your documents.';
    } else {
      color = const Color(0xFFFF6B35);
      icon = Icons.upload_file_outlined;
      title = 'Complete Your KYC';
      subtitle =
          'Upload all 4 documents to get verified. '
          'Verification unlocks full earnings.';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withAlpha(70),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 30,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF756864),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DOCUMENT SLOT
  // ============================================================

  Widget _documentSlot(
    String type,
    String label,
    IconData icon,
  ) {
    final uploaded = _documents.containsKey(type);

    final locked =
        _status == 'submitted' || _status == 'verified';

    return GestureDetector(
      onTap: (uploaded && !locked) || !uploaded
          ? () => _pickAndUpload(type)
          : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: uploaded
                ? const Color(0xFF1D9E55).withAlpha(90)
                : const Color(0xFFE8DDD6),
            width: uploaded ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: uploaded
                    ? const Color(0xFFE8F7EE)
                    : const Color(0xFFFFE8DC),
                shape: BoxShape.circle,
              ),
              child: Icon(
                uploaded
                    ? Icons.check_rounded
                    : icon,
                color: uploaded
                    ? const Color(0xFF1D9E55)
                    : const Color(0xFFFF6B35),
                size: 26,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2A1D1A),
                height: 1.3,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              uploaded
                  ? (locked ? 'Uploaded' : 'Tap to replace')
                  : 'Tap to upload',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF756864),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F2),

      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8F2),
        elevation: 0,
        title: const Text(
          'KYC Verification',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadKyc,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF6B35),
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.cloud_off_outlined,
                          size: 44,
                          color: Color(0xFFD8CFCB),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF756864),
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadKyc,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: _loadKyc,
                      child: ListView(
                        padding:
                            const EdgeInsets.all(20),
                        children: [
                          // ====================================
                          // STATUS
                          // ====================================

                          _statusBanner(),

                          const SizedBox(height: 20),

                          // ====================================
                          // DOCUMENTS
                          // ====================================

                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.05,
                            children: _documentTypes
                                .map(
                                  (doc) =>
                                      _documentSlot(
                                    doc.$1,
                                    doc.$2,
                                    doc.$3,
                                  ),
                                )
                                .toList(),
                          ),

                          const SizedBox(height: 16),

                          // ====================================
                          // PRIVACY NOTE
                          // ====================================

                          Container(
                            padding:
                                const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(
                                14,
                              ),
                            ),
                            child: Row(
                              children: const [
                                Icon(
                                  Icons
                                      .lock_outline_rounded,
                                  size: 18,
                                  color: Color(
                                    0xFF756864,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Your documents are stored securely '
                                    'and only visible to our verification team.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(
                                        0xFF756864,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),

                    // ======================================
                    // UPLOADING OVERLAY
                    // ======================================

                    if (_uploading)
                      Container(
                        color:
                            Colors.black.withAlpha(90),
                        child: const Center(
                          child: Card(
                            child: Padding(
                              padding:
                                  EdgeInsets.all(24),
                              child:
                                  CircularProgressIndicator(
                                color: Color(
                                  0xFFFF6B35,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}
