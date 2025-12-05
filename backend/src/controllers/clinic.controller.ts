import { Request, Response } from 'express';
import Clinic from '../models/Clinic';
import { ok, errorRes } from '../utils/sendResponse';
import { AuthRequest } from '../middleware/auth';

export async function createClinic(req: AuthRequest, res: Response) {
  try {
    const { name, type, address, city, description, openingTime, closingTime, slotDurationMinutes } = req.body;
    if (!name || !type || !address || !city || !openingTime || !closingTime || !slotDurationMinutes) {
      return errorRes(res, 'All required fields must be provided', 400);
    }
    const clinic = await Clinic.create({
      owner: req.user!.userId,
      name,
      type,
      address,
      city,
      description,
      openingTime,
      closingTime,
      slotDurationMinutes
    });
    return ok(res, clinic, 201);
  } catch (err) {
    return errorRes(res, 'Server error', 500);
  }
}

export async function getClinicById(req: Request, res: Response) {
  try {
    const { id } = req.params;
    const clinic = await Clinic.findById(id).select('-owner');
    if (!clinic) return errorRes(res, 'Clinic not found', 404);
    return ok(res, clinic);
  } catch (err) {
    return errorRes(res, 'Server error', 500);
  }
}

export async function updateClinic(req: AuthRequest, res: Response) {
  try {
    const { id } = req.params;
    const clinic = await Clinic.findById(id);
    if (!clinic) return errorRes(res, 'Clinic not found', 404);
    if (clinic.owner.toString() !== req.user!.userId) {
      return errorRes(res, 'Not authorized', 403);
    }
    const updates = req.body;
    Object.assign(clinic, updates);
    await clinic.save();
    return ok(res, clinic);
  } catch (err) {
    return errorRes(res, 'Server error', 500);
  }
}
