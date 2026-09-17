import { Controller, Get } from '@nestjs/common';
import { supabase } from './supabase';

@Controller()
export class AppController {

  @Get()
  getHome() {
    return 'Rebesta Backend Running 🚀';
  }

}