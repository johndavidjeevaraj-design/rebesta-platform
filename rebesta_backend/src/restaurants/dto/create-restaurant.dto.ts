export class CreateRestaurantDto {
  restaurantName!: string;
  ownerName!: string;
  mobile!: string;
  email!: string;
  address!: string;
  city!: string;
  state!: string;
  pincode!: string;
  cuisine!: string;
  restaurantType!: string;
  bankName!: string;
  accountNumber!: string;
  ifsc!: string;

  logoUrl?: string;

  coverImageUrl?: string;

  // NEW
  bannerImageUrl?: string;
}