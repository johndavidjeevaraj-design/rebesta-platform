import { BadRequestException, Injectable } from '@nestjs/common';

import { supabase } from '../supabase';
import { StorageService } from '../storage/storage.service';

// ============================================================
// RIDER KYC
// ============================================================
//
// Swiggy-style rider verification:
//
//   pending   -> rider has not uploaded all documents yet
//   submitted -> all 4 documents in, waiting for admin review
//   verified  -> admin approved
//   rejected  -> admin rejected (reason shown to the rider,
//                re-upload unlocks)
//
// Documents live in a PRIVATE storage bucket; riders only ever
// receive short-lived signed URLs to their own files.
//
// Requires supabase/migrations/20260926_add_delivery_kyc.sql.
// ============================================================

const REQUIRED_DOCUMENTS = [
  'aadhaar_front',
  'aadhaar_back',
  'driving_license',
  'selfie',
] as const;

@Injectable()
export class DeliveryKycService {

  constructor(
    private readonly storageService: StorageService,
  ) {}

  // ============================================================
  // GET KYC STATUS + DOCUMENTS
  // ============================================================

  async getKyc(
    deliveryPartnerId: string,
  ) {
    const { data: partner, error } = await supabase
      .from('delivery_partners')
      .select(`
        id,
        name,
        kyc_status,
        kyc_rejection_reason
      `)
      .eq('id', deliveryPartnerId)
      .single();

    if (error || !partner) {
      throw new BadRequestException(
        'Delivery partner not found',
      );
    }

    const { data: documents } = await supabase
      .from('delivery_kyc_documents')
      .select(`
        document_type,
        storage_path,
        created_at
      `)
      .eq('delivery_partner_id', deliveryPartnerId);

    const docs: any[] = [];

    for (const doc of documents ?? []) {
      const url = await this.storageService
        .getSignedDocumentUrl(doc.storage_path)
        .catch(() => null);

      docs.push({
        type: doc.document_type,
        uploadedAt: doc.created_at,
        url,
      });
    }

    const uploadedTypes = new Set(
      docs.map((d) => d.type),
    );

    return {
      success: true,

      kyc: {
        status: partner.kyc_status ?? 'pending',

        rejectionReason:
          partner.kyc_rejection_reason ?? null,

        requiredDocuments: [...REQUIRED_DOCUMENTS],

        documents: docs,

        allUploaded: (
          REQUIRED_DOCUMENTS as readonly string[]
        ).every((t) => uploadedTypes.has(t)),
      },
    };
  }

  // ============================================================
  // UPLOAD / REPLACE A DOCUMENT
  // ============================================================

  async uploadDocument(
    deliveryPartnerId: string,
    documentType: string,
    file: Express.Multer.File,
  ) {
    if (!file) {
      throw new BadRequestException(
        'No document file provided',
      );
    }

    if (
      !(
        REQUIRED_DOCUMENTS as readonly string[]
      ).includes(documentType)
    ) {
      throw new BadRequestException(
        `Invalid document type: ${documentType}`,
      );
    }

    // ------------------------------------------------------------
    // Lock uploads once submitted / verified
    // ------------------------------------------------------------

    const { data: partner } = await supabase
      .from('delivery_partners')
      .select('id, kyc_status')
      .eq('id', deliveryPartnerId)
      .single();

    if (!partner) {
      throw new BadRequestException(
        'Delivery partner not found',
      );
    }

    if (
      partner.kyc_status === 'submitted' ||
      partner.kyc_status === 'verified'
    ) {
      throw new BadRequestException(
        `KYC is ${partner.kyc_status} - document uploads are locked`,
      );
    }

    // ------------------------------------------------------------
    // Upload to the private bucket (private path, never a URL)
    // ------------------------------------------------------------

    const storagePath =
      await this.storageService.uploadPrivateDocument(
        file,
        deliveryPartnerId,
      );

    // ------------------------------------------------------------
    // Upsert: the latest upload for a type wins
    // ------------------------------------------------------------

    const { error: upsertError } = await supabase
      .from('delivery_kyc_documents')
      .upsert(
        {
          delivery_partner_id: deliveryPartnerId,
          document_type: documentType,
          storage_path: storagePath,
        },
        {
          onConflict:
            'delivery_partner_id,document_type',
        },
      );

    if (upsertError) {
      throw new BadRequestException(upsertError.message);
    }

    // ------------------------------------------------------------
    // All documents in? -> submit for review
    // ------------------------------------------------------------

    const { data: documents } = await supabase
      .from('delivery_kyc_documents')
      .select('document_type')
      .eq('delivery_partner_id', deliveryPartnerId);

    const types = new Set(
      (documents ?? []).map(
        (d) => d.document_type as string,
      ),
    );

    const allUploaded = (
      REQUIRED_DOCUMENTS as readonly string[]
    ).every((t) => types.has(t));

    let status =
      (partner.kyc_status as string) ?? 'pending';

    if (allUploaded) {
      await supabase
        .from('delivery_partners')
        .update({
          kyc_status: 'submitted',
          kyc_rejection_reason: null,
        })
        .eq('id', deliveryPartnerId);

      status = 'submitted';
    }

    return {
      success: true,

      message: allUploaded
        ? 'All documents uploaded - KYC submitted for review'
        : 'Document uploaded',

      kyc: {
        status,
        allUploaded,
      },
    };
  }
}
