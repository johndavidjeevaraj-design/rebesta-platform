import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';

import { NotificationsService } from './notifications.service';

import { CustomerJwtGuard } from '../customer-auth/customer-jwt.guard';

import { CreateNotificationDto } from './dto/create-notification.dto';

@Controller('notifications')
export class NotificationsController {

  constructor(
    private readonly notificationsService: NotificationsService,
  ) {}

  // Create

  @Post()
  create(
    @Body()
    dto: CreateNotificationDto,
  ) {
    return this.notificationsService.create(dto);
  }

  // Customer Notifications

  @Get()
  @UseGuards(CustomerJwtGuard)
  getCustomerNotifications(
    @Req() req,
  ) {
    return this.notificationsService.getCustomerNotifications(
      req.user.customerId,
    );
  }

  // Mark Read

  @Patch(':id/read')
  markRead(
    @Param('id')
    id: string,
  ) {
    return this.notificationsService.markRead(id);
  }

  // Delete

  @Delete(':id')
  delete(
    @Param('id')
    id: string,
  ) {
    return this.notificationsService.delete(id);
  }

}