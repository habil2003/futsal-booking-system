import { Router } from 'express';
import {
  register,
  login,
  getMe,
  verifyEmail,
  resendOtp,
  forgotPassword,
  resetPassword,
  changePassword           
} from '../controllers/auth.controller.js';
import { authenticate } from '../middleware/auth.js';

const router = Router();

router.post('/register', register);
router.post('/login', login);
router.get('/me', authenticate, getMe);
router.post('/verify-email', verifyEmail);
router.post('/resend-otp', resendOtp);
router.post('/forgot-password', forgotPassword);
router.post('/reset-password', resetPassword);
router.put('/change-password', authenticate, changePassword);   

export default router;