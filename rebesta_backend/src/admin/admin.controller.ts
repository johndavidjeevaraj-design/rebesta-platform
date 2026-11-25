import {
  Controller,
  Get,
  UseGuards,
} from '@nestjs/common';
import { AdminService } from './admin.service';
import { Body, Param, Patch } from '@nestjs/common';
import { AdminGuard } from './admin.guard';
import { RejectDeliveryKycDto } from './dto/reject-delivery-kyc.dto';
import { SettleDeliveryPayoutDto } from './dto/settle-delivery-payout.dto';

// Every admin route requires the x-admin-key header
@UseGuards(AdminGuard)
@Controller('admin')
export class AdminController {
  constructor(
    private readonly adminService: AdminService,
  ) {}

  // ==========================
  // Admin Dashboard
  // ==========================
  @Get('dashboard')
  getDashboard() {
    return this.adminService.getDashboard();
  }

  // ==========================
// All Restaurants
// ==========================
@Get('restaurants')
getRestaurants() {
  return this.adminService.getRestaurants();
}

// ==========================
// Restaurant Details
// ==========================
@Get('restaurants/:id')
getRestaurant(
  @Param('id') id: string,
) {
  return this.adminService.getRestaurant(id);
}

// ==========================
// Approve Restaurant
// ==========================
@Patch('restaurants/:id/approve')
approveRestaurant(
  @Param('id') id: string,
) {
  return this.adminService.approveRestaurant(id);
}

// ==========================
// Reject Restaurant
// ==========================
@Patch('restaurants/:id/reject')
rejectRestaurant(
  @Param('id') id: string,
) {
  return this.adminService.rejectRestaurant(id);
}

// ==========================
// Block Restaurant
// ==========================
@Patch('restaurants/:id/block')
blockRestaurant(
  @Param('id') id: string,
) {
  return this.adminService.blockRestaurant(id);
}

// ==========================
// Unblock Restaurant
// ==========================
@Patch('restaurants/:id/unblock')
unblockRestaurant(
  @Param('id') id: string,
) {
  return this.adminService.unblockRestaurant(id);
}

// ==========================
// Customers
// ==========================
@Get('customers')
getCustomers() {
  return this.adminService.getCustomers();
}
// ==========================
// Delivery Partners
// ==========================
@Get('delivery-partners')
getDeliveryPartners() {
  return this.adminService.getDeliveryPartners();
}
// ==========================
// Delivery Partner Details
// ==========================
@Get('delivery-partners/:id')
getDeliveryPartner(
  @Param('id') id: string,
) {
  return this.adminService.getDeliveryPartner(id);
}

// ==========================
// Approve Delivery Partner
// ==========================
@Patch('delivery-partners/:id/approve')
approveDeliveryPartner(
  @Param('id') id: string,
) {
  return this.adminService.approveDeliveryPartner(id);
}

// ==========================
// Reject Delivery Partner
// ==========================
@Patch('delivery-partners/:id/reject')
rejectDeliveryPartner(
  @Param('id') id: string,
) {
  return this.adminService.rejectDeliveryPartner(id);
}

// ==========================
// Delivery KYC Review
// ==========================

@Get('delivery-kyc')
getDeliveryKycSubmissions() {
  return this.adminService.getDeliveryKycSubmissions();
}

@Patch('delivery-kyc/:id/approve')
approveDeliveryKyc(
  @Param('id') id: string,
) {
  return this.adminService.approveDeliveryKyc(id);
}

@Patch('delivery-kyc/:id/reject')
rejectDeliveryKyc(
  @Param('id') id: string,
  @Body() dto: RejectDeliveryKycDto,
) {
  return this.adminService.rejectDeliveryKyc(id, dto.reason);
}

// ==========================
// Block Delivery Partner
// ==========================
@Patch('delivery-partners/:id/block')
blockDeliveryPartner(
  @Param('id') id: string,
) {
  return this.adminService.blockDeliveryPartner(id);
}

// ==========================
// Unblock Delivery Partner
// ==========================
@Patch('delivery-partners/:id/unblock')
unblockDeliveryPartner(
  @Param('id') id: string,
) {
  return this.adminService.unblockDeliveryPartner(id);
}

// Record a completed manual bank transfer and settle all pending rider earnings.
@Patch('delivery-partners/:id/payout')
settleDeliveryPayout(
  @Param('id') id: string,
  @Body() dto: SettleDeliveryPayoutDto,
) {
  return this.adminService.settleDeliveryPayout(
    id,
    dto.payoutReference,
  );
}
// ==========================
// All Orders
// ==========================
@Get('orders')
getOrders() {
  return this.adminService.getOrders();
}

// ==========================
// Order Details
// ==========================
@Get('orders/:id')
getOrder(
  @Param('id') id: string,
) {
  return this.adminService.getOrder(id);
}

// ==========================
// Cancel Order
// ==========================
@Patch('orders/:id/cancel')
cancelOrder(
  @Param('id') id: string,
) {
  return this.adminService.cancelOrder(id);
}

// ==========================
// Refund Order
// ==========================
@Patch('orders/:id/refund')
refundOrder(
  @Param('id') id: string,
) {
  return this.adminService.refundOrder(id);
}
@Get('analytics')
getAnalytics() {
  return this.adminService.getAnalytics();
}
}