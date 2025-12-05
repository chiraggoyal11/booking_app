import { Router } from 'express';
import { createClinic, getClinicById, updateClinic } from '../controllers/clinic.controller';
import { auth } from '../middleware/auth';
import { isAdmin } from '../middleware/isAdmin';

const router = Router();

router.post('/', auth, isAdmin, createClinic);
router.get('/:id', getClinicById);
router.put('/:id', auth, isAdmin, updateClinic);

export default router;
