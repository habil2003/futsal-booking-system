import express from 'express';
import {
  getSystemSettings,
  updateSystemSettings,
  getRegistrationFeeSettings,
  updateRegistrationFee,
} from '../controllers/settings.controller.js';
import { authenticate, authorize } from '../middleware/auth.js';

const router = express.Router();

// Public routes (anyone can view settings)
router.get('/', getSystemSettings);

// Admin only routes
router.put('/', authenticate, authorize('ADMIN'), updateSystemSettings);
router.get('/registration-fee', authenticate, authorize('ADMIN'), getRegistrationFeeSettings);
router.put('/registration-fee', authenticate, authorize('ADMIN'), updateRegistrationFee);

export default router;