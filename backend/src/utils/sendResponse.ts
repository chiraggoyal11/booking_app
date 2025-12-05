import { Response } from 'express';

export function ok(res: Response, data: any, status = 200) {
  return res.status(status).json({ success: true, data });
}

export function okMsg(res: Response, message: string, status = 200) {
  return res.status(status).json({ success: true, message });
}

export function errorRes(res: Response, message: string, status = 400) {
  return res.status(status).json({ success: false, message });
}
