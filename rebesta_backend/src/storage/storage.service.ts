import { Injectable } from '@nestjs/common';
import { supabase } from '../supabase';


@Injectable()
export class StorageService {


  async uploadImage(
    file: Express.Multer.File,
  ) {

    const fileName =
      `${Date.now()}-${file.originalname}`;


    const { error } = await supabase
      .storage
      .from('food-images')
      .upload(
        fileName,
        file.buffer,
        {
          contentType: file.mimetype,
        },
      );


    if (error) {
      throw new Error(error.message);
    }


    const { data } =
      supabase
        .storage
        .from('food-images')
        .getPublicUrl(fileName);


    return data.publicUrl;
  }


  // ============================================================
  // KYC documents: PRIVATE bucket (PII - never public URLs).
  // Returns the storage path; signed URLs are handed out
  // on demand via getSignedDocumentUrl.
  // ============================================================

  async uploadPrivateDocument(
    file: Express.Multer.File,
    partnerId: string,
  ) {

    const fileName =
      `${partnerId}/${Date.now()}-${file.originalname}`;


    const { error } = await supabase
      .storage
      .from('kyc-documents')
      .upload(
        fileName,
        file.buffer,
        {
          contentType: file.mimetype,
        },
      );


    if (error) {
      throw new Error(error.message);
    }


    return fileName;
  }


  async getSignedDocumentUrl(
    storagePath: string,
  ) {

    const { data, error } = await supabase
      .storage
      .from('kyc-documents')
      .createSignedUrl(
        storagePath,
        3600,
      );


    if (error || !data) {
      throw new Error(error?.message ?? 'Could not sign document url');
    }


    return data.signedUrl;
  }

}