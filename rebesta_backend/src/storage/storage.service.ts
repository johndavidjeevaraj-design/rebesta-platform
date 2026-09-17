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

}