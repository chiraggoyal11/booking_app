import { Router } from 'express';
import { getServicesForClinic, createService, updateService, deleteService } from '../controllers/service.controller';
import { auth } from '../middleware/auth';
import { isAdmin } from '../middleware/isAdmin';

const router = Router();

router.get('/:clinicId/services', getServicesForClinic);
router.post('/', auth, isAdmin, createService);
router.put('/:id', auth, isAdmin, updateService);
router.delete('/:id', auth, isAdmin, deleteService);

export default router;
