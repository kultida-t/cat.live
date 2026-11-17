import {
  CanActivate,
  ExecutionContext,
  HttpStatus,
  Injectable,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import type { Request } from 'express';
import { authError } from './auth.errors.js';

export interface AuthenticatedRequest extends Request {
  user: { id: string };
}

/** ตรวจ access token (Bearer) และแนบ user id ไว้ที่ request.user */
@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(private readonly jwt: JwtService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const header = request.headers.authorization ?? '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : null;
    if (!token) throw authError(HttpStatus.UNAUTHORIZED, 'session_invalid');
    try {
      const payload = await this.jwt.verifyAsync<{ sub: string }>(token);
      request.user = { id: payload.sub };
      return true;
    } catch {
      throw authError(HttpStatus.UNAUTHORIZED, 'session_invalid');
    }
  }
}
