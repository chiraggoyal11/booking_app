import { Router } from 'express';
import { getTodayBookings, getStats } from '../controllers/admin.controller';
import { auth } from '../middleware/auth';
import { isAdmin } from '../middleware/isAdmin';

const router = Router();

router.get('/bookings/today', auth, isAdmin, getTodayBookings);
router.get('/stats', auth, isAdmin, getStats);

export default router;
