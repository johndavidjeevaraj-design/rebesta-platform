import {
  Body,
  Controller,
  Get,
  Post,
  Req,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';

import { FileInterceptor } from '@nestjs/platform-express';

import { DeliveryJwtGuard } from '../delivery-auth/delivery-jwt.guard';
import { DeliveryKycService } from './delivery-kyc.service';

@Controller('delivery/kyc')
export class DeliveryKycController {

  constructor(
    private readonly deliveryKycService: DeliveryKycService,
  ) {}

  // ============================================================
  // GET KYC STATUS + DOCUMENTS (signed URLs, own documents only)
  // ============================================================

  @Get()
  @UseGuards(DeliveryJwtGuard)
  getKyc(
    @Req() req,
  ) {
    return this.deliveryKycService.getKyc(
      req.user.deliveryPartnerId,
    );
  }

  // ============================================================
  // UPLOAD / REPLACE A DOCUMENT (multipart: document + type)
  // ============================================================

  @Post('documents')
  @UseGuards(DeliveryJwtGuard)
  @UseInterceptors(
    FileInterceptor('document'),
  )
  uploadDocument(
    @Req() req,
    @UploadedFile() file: Express.Multer.File,
    @Body('document_type') documentType: string,
  ) {
    return this.deliveryKycService.uploadDocument(
      req.user.deliveryPartnerId,
      documentType,
      file,
    );
  }
}
