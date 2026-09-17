export class CreateMenuDto {
  category: string;

  name: string;

  description?: string;

  price: number;

  imageUrl?: string;

  isVeg?: boolean;

  isAvailable?: boolean;
}