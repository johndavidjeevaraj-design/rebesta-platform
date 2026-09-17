import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { CategoriesModule } from './categories/categories.module';
import { MenuModule } from './menu/menu.module';
import { RestaurantsModule } from './restaurants/restaurants.module';
import { PartnerAuthModule } from './partner-auth/partner-auth.module';
import { NotificationsModule } from './notifications/notifications.module';
import { StorageModule } from './storage/storage.module';
import { CustomerAuthModule } from './customer-auth/customer-auth.module';
import { CartModule } from './cart/cart.module';
import { OrdersModule } from './orders/orders.module';
import { PartnerOrdersModule } from './partner-orders/partner-orders.module';
import { PartnerDashboardModule } from './partner-dashboard/partner-dashboard.module';
import { AddressesModule } from './addresses/addresses.module';
import { DeliveryAuthModule } from './delivery-auth/delivery-auth.module';
import { DeliveryModule } from './delivery/delivery.module';
import { SocketModule } from './socket/socket.module';
import { AdminModule } from './admin/admin.module';
import { ReviewsModule } from './reviews/reviews.module';
import { FirebaseModule } from './firebase/firebase.module';
import { PaymentsModule } from './payments/payments.module';
import { FcmModule } from './fcm/fcm.module';
import { WalletModule } from './wallet/wallet.module';
import { CouponsModule } from './coupons/coupons.module';
import { BannersModule } from './banners/banners.module';
import { SettingsModule } from './settings/settings.module';
import { SupportModule } from './support/support.module';
import { ConfigModule } from '@nestjs/config';

@Module({
  imports: [
    CategoriesModule,
    MenuModule,
    RestaurantsModule,
    PartnerAuthModule,
    AdminModule,
    PaymentsModule,
    ReviewsModule,
    NotificationsModule,
    FirebaseModule,
    FcmModule,
    WalletModule,
    CouponsModule,
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    
    StorageModule,
    CustomerAuthModule,
    CartModule,
    OrdersModule,
    PartnerOrdersModule,
    PartnerDashboardModule,
    AddressesModule,
    DeliveryAuthModule,
    DeliveryModule,
    SocketModule,
    BannersModule,
    SettingsModule,
    SupportModule
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}