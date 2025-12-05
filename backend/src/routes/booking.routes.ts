import { Router } from 'express';
import { getAvailableSlots, createBooking, getMyBookings, cancelBooking, updateBookingStatus } from '../controllers/booking.controller';
import { auth } from '../middleware/auth';

const router = Router();

router.get('/slots', getAvailableSlots);
router.post('/', auth, createBooking);
router.get('/my', auth, getMyBookings);
router.patch('/:id/cancel', auth, cancelBooking);
router.patch('/:id/status', auth, updateBookingStatus);

export default router;
