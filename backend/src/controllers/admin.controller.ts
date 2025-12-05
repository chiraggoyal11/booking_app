import { Request, Response } from 'express';
import Booking from '../models/Booking';
import Clinic from '../models/Clinic';
import { ok, errorRes } from '../utils/sendResponse';
import { AuthRequest } from '../middleware/auth';

export async function getTodayBookings(req: AuthRequest, res: Response) {
  try {
    const { clinicId } = req.query;
    if (!clinicId) return errorRes(res, 'clinicId required', 400);
    const clinic = await Clinic.findById(clinicId);
    if (!clinic) return errorRes(res, 'Clinic not found', 404);
    if (clinic.owner.toString() !== req.user!.userId) {
      return errorRes(res, 'Not authorized', 403);
    }
    const today = new Date().toISOString().slice(0, 10);
    const bookings = await Booking.find({ clinic: clinicId, date: today }).populate('customer', 'name email').populate('service', 'name');
    return ok(res, bookings);
  } catch (err) {
    return errorRes(res, 'Server error', 500);
  }
}

export async function getStats(req: AuthRequest, res: Response) {
  try {
    const { clinicId } = req.query;
    if (!clinicId) return errorRes(res, 'clinicId required', 400);
    const clinic = await Clinic.findById(clinicId);
    if (!clinic) return errorRes(res, 'Clinic not found', 404);
    if (clinic.owner.toString() !== req.user!.userId) {
      return errorRes(res, 'Not authorized', 403);
    }
    const totalBookings = await Booking.countDocuments({ clinic: clinicId });
    const today = new Date().toISOString().slice(0, 10);
    const todayBookings = await Booking.countDocuments({ clinic: clinicId, date: today });
    const completedBookings = await Booking.countDocuments({ clinic: clinicId, status: 'completed' });
    return ok(res, { totalBookings, todayBookings, completedBookings });
  } catch (err) {
    return errorRes(res, 'Server error', 500);
  }
}
