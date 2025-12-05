import { Request, Response } from 'express';
import Booking from '../models/Booking';
import Clinic from '../models/Clinic';
import Service from '../models/Service';
import { ok, errorRes, okMsg } from '../utils/sendResponse';
import { AuthRequest } from '../middleware/auth';
import { generateSlots } from '../utils/timeUtils';

export async function getAvailableSlots(req: Request, res: Response) {
  try {
    const { clinicId, date } = req.query;
    if (!clinicId || !date) return errorRes(res, 'clinicId and date required', 400);
    const clinic = await Clinic.findById(clinicId);
    if (!clinic) return errorRes(res, 'Clinic not found', 404);
    const allSlots = generateSlots(clinic.openingTime, clinic.closingTime, clinic.slotDurationMinutes);
    const bookings = await Booking.find({ clinic: clinicId, date, status: { $ne: 'cancelled' } });
    const bookedTimes = bookings.map(b => b.startTime);
    const availableSlots = allSlots.filter(slot => !bookedTimes.includes(slot));
    return ok(res, { date, slots: availableSlots });
  } catch (err) {
    return errorRes(res, 'Server error', 500);
  }
}

export async function createBooking(req: AuthRequest, res: Response) {
  try {
    const { clinicId, serviceId, date, startTime, endTime, notes } = req.body;
    if (!clinicId || !serviceId || !date || !startTime) {
      return errorRes(res, 'All required fields must be provided', 400);
    }
    const clinic = await Clinic.findById(clinicId);
    if (!clinic) return errorRes(res, 'Clinic not found', 404);
    const service = await Service.findById(serviceId);
    if (!service || service.clinic.toString() !== clinicId) {
      return errorRes(res, 'Service not found or does not belong to clinic', 400);
    }
    const exists = await Booking.findOne({ clinic: clinicId, date, startTime, status: { $ne: 'cancelled' } });
    if (exists) return errorRes(res, 'Slot already booked', 409);
    const computedEndTime = endTime || generateEndTime(startTime, service.durationMinutes);
    const booking = await Booking.create({
      clinic: clinicId,
      customer: req.user!.userId,
      service: serviceId,
      date,
      startTime,
      endTime: computedEndTime,
      notes,
      status: 'pending'
    });
    return ok(res, booking, 201);
  } catch (err) {
    return errorRes(res, 'Server error', 500);
  }
}

function generateEndTime(startTime: string, duration: number): string {
  const [h, m] = startTime.split(':').map(Number);
  const total = h * 60 + m + duration;
  const endH = Math.floor(total / 60);
  const endM = total % 60;
  return `${String(endH).padStart(2, '0')}:${String(endM).padStart(2, '0')}`;
}

export async function getMyBookings(req: AuthRequest, res: Response) {
  try {
    const bookings = await Booking.find({ customer: req.user!.userId }).sort({ date: -1 }).populate('clinic', 'name city').populate('service', 'name');
    return ok(res, bookings);
  } catch (err) {
    return errorRes(res, 'Server error', 500);
  }
}

export async function cancelBooking(req: AuthRequest, res: Response) {
  try {
    const { id } = req.params;
    const booking = await Booking.findById(id);
    if (!booking) return errorRes(res, 'Booking not found', 404);
    if (booking.customer.toString() !== req.user!.userId && req.user!.role !== 'admin') {
      return errorRes(res, 'Not authorized', 403);
    }
    if (booking.status === 'completed') {
      return errorRes(res, 'Cannot cancel completed booking', 400);
    }
    booking.status = 'cancelled';
    await booking.save();
    return okMsg(res, 'Booking cancelled');
  } catch (err) {
    return errorRes(res, 'Server error', 500);
  }
}

export async function updateBookingStatus(req: AuthRequest, res: Response) {
  try {
    const { id } = req.params;
    const { status } = req.body;
    const booking = await Booking.findById(id).populate('clinic');
    if (!booking) return errorRes(res, 'Booking not found', 404);
    if (req.user!.role !== 'admin' || booking.clinic.owner.toString() !== req.user!.userId) {
      return errorRes(res, 'Not authorized', 403);
    }
    if (!['pending', 'confirmed', 'completed', 'cancelled'].includes(status)) {
      return errorRes(res, 'Invalid status', 400);
    }
    booking.status = status;
    await booking.save();
    return okMsg(res, 'Booking status updated');
  } catch (err) {
    return errorRes(res, 'Server error', 500);
  }
}
