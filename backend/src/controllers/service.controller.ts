import { Request, Response } from 'express';
import Service from '../models/Service';
import Clinic from '../models/Clinic';
import { ok, errorRes } from '../utils/sendResponse';
import { AuthRequest } from '../middleware/auth';

export async function getServicesForClinic(req: Request, res: Response) {
  try {
    const { clinicId } = req.params;
    const services = await Service.find({ clinic: clinicId, isActive: true });
    return ok(res, services);
  } catch (err) {
    return errorRes(res, 'Server error', 500);
  }
}

export async function createService(req: AuthRequest, res: Response) {
  try {
    const { clinicId, name, description, price, durationMinutes, isActive } = req.body;
    if (!clinicId || !name || !price || !durationMinutes) {
      return errorRes(res, 'All required fields must be provided', 400);
    }
    const clinic = await Clinic.findById(clinicId);
    if (!clinic) return errorRes(res, 'Clinic not found', 404);
    if (clinic.owner.toString() !== req.user!.userId) {
      return errorRes(res, 'Not authorized', 403);
    }
    const service = await Service.create({
      clinic: clinicId,
      name,
      description,
      price,
      durationMinutes,
      isActive: isActive !== undefined ? isActive : true
    });
    return ok(res, service, 201);
  } catch (err) {
    return errorRes(res, 'Server error', 500);
  }
}

export async function updateService(req: AuthRequest, res: Response) {
  try {
    const { id } = req.params;
    const service = await Service.findById(id);
    if (!service) return errorRes(res, 'Service not found', 404);
    const clinic = await Clinic.findById(service.clinic);
    if (!clinic || clinic.owner.toString() !== req.user!.userId) {
      return errorRes(res, 'Not authorized', 403);
    }
    Object.assign(service, req.body);
    await service.save();
    return ok(res, service);
  } catch (err) {
    return errorRes(res, 'Server error', 500);
  }
}

export async function deleteService(req: AuthRequest, res: Response) {
  try {
    const { id } = req.params;
    const service = await Service.findById(id);
    if (!service) return errorRes(res, 'Service not found', 404);
    const clinic = await Clinic.findById(service.clinic);
    if (!clinic || clinic.owner.toString() !== req.user!.userId) {
      return errorRes(res, 'Not authorized', 403);
    }
    await service.deleteOne();
    return okMsg(res, 'Service deleted');
  } catch (err) {
    return errorRes(res, 'Server error', 500);
  }
}
