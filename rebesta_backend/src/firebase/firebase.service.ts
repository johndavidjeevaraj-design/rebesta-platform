import { Injectable } from '@nestjs/common';
import { initializeApp, cert, getApps } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import * as path from 'path';

@Injectable()
export class FirebaseService {
  constructor() {
    if (!getApps().length) {
      initializeApp({
        credential: cert(
          path.join(
            process.cwd(),
            'firebase-adminsdk.json',
          ),
        ),
      });
    }
  }

  get messaging() {
    return getMessaging();
  }
}