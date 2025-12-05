import { Response, NextFunction } from 'express';
import { AuthRequest } from './auth';
import { errorRes } from '../utils/sendResponse';

export function isAdmin(req: AuthRequest, res: Response, next: NextFunction) {
  if (!req.user || req.user.role !== 'admin') {
    return errorRes(res, 'Admin access required', 403);
  }
  next();
}
