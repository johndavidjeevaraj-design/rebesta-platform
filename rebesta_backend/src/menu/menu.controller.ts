import {
  Controller,
  Post,
  Get,
  Patch,
  Delete,
  Body,
  Req,
  Param,
  Query,
  UseGuards,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';

import { FileInterceptor } from '@nestjs/platform-express';

import { MenuService } from './menu.service';
import { CreateMenuDto } from './dto/create-menu.dto';
import { UpdateMenuDto } from './dto/update-menu.dto';

import { JwtAuthGuard } from '../partner-auth/jwt-auth.guard';
import { StorageService } from '../storage/storage.service';


@Controller('menu')
export class MenuController {


  constructor(
    private readonly menuService: MenuService,
    private readonly storageService: StorageService,
  ) {}



  // ===============================
  // CUSTOMER: GET ALL MENU ITEMS
  // ===============================

  @Get()
findAll(
  @Query('category') category?: string,
  @Query('isVeg') isVeg?: string,
) {

  return this.menuService.findAll(
    category,
    isVeg === 'true',
  );

}


// ===============================
  // PARTNER: GET OWN MENU
  // ===============================

  @Get('partner')
@UseGuards(JwtAuthGuard)
getPartnerMenu(@Req() req) {
  console.log('========================================');
  console.log('PARTNER MENU REQUEST');
  console.log('User:', req.user);
  console.log(
    'Restaurant Partner ID:',
    req.user?.restaurantPartnerId,
  );
  console.log('========================================');

  return this.menuService.getPartnerMenu(
    req.user.restaurantPartnerId,
  );
}


  // ===============================
  // CUSTOMER: GET SINGLE MENU ITEM
  // ===============================

  @Get(':id')
  findOne(
    @Param('id') id: string,
  ) {

    return this.menuService.findOne(
      id,
    );

  }




  




  // ===============================
  // PARTNER: CREATE MENU ITEM
  // IMAGE UPLOAD
  // ===============================

  @Post()
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(
    FileInterceptor('image'),
  )
  async createMenu(
    @Req() req,
    @UploadedFile() file: Express.Multer.File,
    @Body() dto: CreateMenuDto,
  ) {


    let imageUrl: string | undefined =
      undefined;


    if (file) {

      imageUrl =
        await this.storageService.uploadImage(
          file,
        );

    }



    // Multer delivers multipart fields as strings -
    // coerce them back to their real types.

    const raw = dto as any;

    const isVeg =
      raw.isVeg === true || raw.isVeg === 'true';

    const isAvailable =
      raw.isAvailable === true ||
      raw.isAvailable === 'true';

    const parsedPrice = Number(raw.price);

    const price =
      raw.price != null && Number.isFinite(parsedPrice)
        ? parsedPrice
        : (dto.price ?? 0);

    return this.menuService.createMenu(
      req.user.restaurantPartnerId,
      {
        ...dto,
        price,
        isVeg,
        isAvailable,
        imageUrl,
      },
    );

  }





  // ===============================
  // PARTNER: UPDATE MENU ITEM
  // ===============================

  @Patch(':id')
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(
    FileInterceptor('image'),
  )
  async updateMenu(
    @Req() req,
    @Param('id') id: string,
    @UploadedFile() file: Express.Multer.File,
    @Body() dto: UpdateMenuDto,
  ) {
    // Optional new photo for the dish

    let imageUrl: string | undefined = undefined;

    if (file) {
      imageUrl = await this.storageService.uploadImage(
        file,
      );
    }

    // Multer delivers multipart fields as strings -
    // coerce them back to their real types.

    const raw = dto as any;

    const isVeg =
      raw.isVeg === true || raw.isVeg === 'true';

    const isAvailable =
      raw.isAvailable === true ||
      raw.isAvailable === 'true';

    const parsedPrice = Number(raw.price);

    const price =
      raw.price != null && Number.isFinite(parsedPrice)
        ? parsedPrice
        : (dto.price ?? 0);

    return this.menuService.updateMenu(
      req.user.restaurantPartnerId,
      id,
      {
        ...dto,
        price,
        isVeg,
        isAvailable,
        ...(imageUrl != null ? { imageUrl } : {}),
      },
    );

  }





  // ===============================
  // PARTNER: TOGGLE AVAILABILITY
  // ===============================

  @Patch(':id/status')
  @UseGuards(JwtAuthGuard)
  toggleAvailability(
    @Req() req,
    @Param('id') id: string,
    @Body() body: {
      isAvailable: boolean;
    },
  ) {


    return this.menuService.toggleAvailability(
      req.user.restaurantPartnerId,
      id,
      body.isAvailable,
    );

  }





  // ===============================
  // PARTNER: DELETE MENU ITEM
  // ===============================

  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  deleteMenu(
    @Req() req,
    @Param('id') id: string,
  ) {


    return this.menuService.deleteMenu(
      req.user.restaurantPartnerId,
      id,
    );

  }


}