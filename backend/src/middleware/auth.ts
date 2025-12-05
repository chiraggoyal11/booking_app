import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { errorRes } from '../utils/sendResponse';

export interface AuthRequest extends Request {
  user?: {
    userId: string;
    role: 'customer' | 'admin';
  };
}

export function auth(req: AuthRequest, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;

  if (!authHeader?.startsWith('Bearer ')) {
    return errorRes(res, 'No token provided', 401);
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET as string) as {
      userId: string;
      role: 'customer' | 'admin';
    };

    req.user = decoded;
    next();
  } catch (err) {
    return errorRes(res, 'Invalid token', 401);
  }
}
