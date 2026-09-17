import { Controller, Get } from '@nestjs/common';
import { AdminService } from './admin.service';
import { Param, Patch } from '@nestjs/common';

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