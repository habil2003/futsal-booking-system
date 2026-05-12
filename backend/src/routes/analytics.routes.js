import express from 'express';
import { authenticate, authorize } from '../middleware/auth.js';
import {
  getBookingAnalytics,
  getRevenueAnalytics,
  getGroundPerformance,
  getUserAnalytics,
  getTimeSlotAnalytics,
  getTournamentAnalytics,
  getRevenueOverTime,        // ✅ add
  getBookingsOverTime,       // ✅ add
  getBookingStatusBreakdown, // ✅ add
} from '../controllers/analytics.controller.js';

const router = express.Router();

// All analytics routes are admin-only
router.use(authenticate);
router.use(authorize('ADMIN'));

router.get('/bookings', getBookingAnalytics);
router.get('/revenue', getRevenueAnalytics);
router.get('/grounds', getGroundPerformance);
router.get('/users', getUserAnalytics);
router.get('/timeslots', getTimeSlotAnalytics);
router.get('/tournaments', getTournamentAnalytics);
router.get('/revenue-over-time', getRevenueOverTime);
router.get('/bookings-over-time', getBookingsOverTime);
router.get('/booking-status-breakdown', getBookingStatusBreakdown);

export default router;