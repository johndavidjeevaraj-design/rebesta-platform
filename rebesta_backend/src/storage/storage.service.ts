import { BadRequestException, Injectable, InternalServerErrorException } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { supabase } from '../supabase';

@Injectable()
export class StorageService {
  private validateFile(file: Express.Multer.File, allowedTypes: string[], maxBytes: number) {
    if (!file || !Buffer.isBuffer(file.buffer) || file.buffer.length === 0) {
      throw new BadRequestException('A valid file is required');
    }
    if (file.buffer.length > maxBytes) {
      throw new BadRequestException('File exceeds the allowed size');
    }
    if (!allowedTypes.includes(file.mimetype)) {
      throw new BadRequestException('Unsupported file type');
    }
  }

  async uploadImage(file: Express.Multer.File) {
    this.validateFile(file, ['image/jpeg', 'image/png', 'image/webp'], 5 * 1024 * 1024);
    const extension = file.mimetype === 'image/jpeg' ? 'jpg' : file.mimetype.split('/')[1];
    const fileName = `images/${randomUUID()}.${extension}`;

    const { error } = await supabase.storage.from('food-images').upload(fileName, file.buffer, {
      contentType: file.mimetype,
      upsert: false,
    });
    if (error) throw new InternalServerErrorException('Image upload failed');

    const { data } = supabase.storage.from('food-images').getPublicUrl(fileName);
    return data.publicUrl;
  }

  // KYC documents are stored in a private bucket. Only storage paths are returned.
  async uploadPrivateDocument(file: Express.Multer.File, partnerId: string) {
    if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(partnerId)) {
      throw new BadRequestException('Invalid partner identifier');
    }
    this.validateFile(file, ['image/jpeg', 'image/png', 'application/pdf'], 10 * 1024 * 1024);
    const extension = file.mimetype === 'image/jpeg' ? 'jpg' : file.mimetype === 'image/png' ? 'png' : 'pdf';
    const fileName = `${partnerId}/${randomUUID()}.${extension}`;

    const { error } = await supabase.storage.from('kyc-documents').upload(fileName, file.buffer, {
      contentType: file.mimetype,
      upsert: false,
    });
    if (error) throw new InternalServerErrorException('Document upload failed');
    return fileName;
  }

  async getSignedDocumentUrl(storagePath: string) {
    if (typeof storagePath !== 'string' || storagePath.length > 512 || !/^[0-9a-f-]{36}\\/[a-f0-9-]{36}\\.(jpg|png|pdf)$/i.test(storagePath)) {
      throw new BadRequestException('Invalid document path');
    }
    const { data, error } = await supabase.storage.from('kyc-documents').createSignedUrl(storagePath, 300);
    if (error || !data) throw new InternalServerErrorException('Could not create document access link');
    return data.signedUrl;
  }
}
