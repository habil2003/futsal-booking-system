import { Router } from 'express';
import {
  getDashboardStats,
  getOwnerTodayBookings,        // ✅ Now from owner.controller.js
  getWeeklyRevenue,
  getPeakHours,
  getOwnerUpcomingBookings,     // ✅ From owner.controller.js
  getMonthBookings,
  getEarningsOverview,
  getEarningsBreakdown,
  getEarningsHistory,
  getEarningsChart,
  requestPayout,
  getPayoutHistory
} from '../controllers/owner.controller.js';
import {
  checkInBooking,
  confirmCodPayment,
  userCancelBooking
} from '../controllers/booking.controller.js';
import { authenticate, authorize } from '../middleware/auth.js';

const router = Router();

router.use(authenticate, authorize('OWNER', 'ADMIN'));

// Dashboard
router.get('/dashboard/stats', getDashboardStats);
router.get('/dashboard/today-bookings', getOwnerTodayBookings);  // ✅ Now uses owner.controller
router.get('/dashboard/weekly-revenue', getWeeklyRevenue);
router.get('/dashboard/peak-hours', getPeakHours);

// Bookings list
router.get('/bookings/upcoming', getOwnerUpcomingBookings);
router.get('/bookings/month', getMonthBookings);

// Booking actions
router.put('/bookings/:bookingId/checkin', checkInBooking);
router.put('/bookings/:bookingId/cod-confirm', confirmCodPayment);
router.put('/bookings/:bookingId/cancel', userCancelBooking);

// ============================================
// EARNINGS ROUTES
// ============================================

// Earnings overview
router.get('/earnings/overview', authenticate, authorize('OWNER'), getEarningsOverview);

// Earnings breakdown by futsal
router.get('/earnings/breakdown', authenticate, authorize('OWNER'), getEarningsBreakdown);

// Earnings history
router.get('/earnings/history', authenticate, authorize('OWNER'), getEarningsHistory);

// Earnings chart data
router.get('/earnings/chart', authenticate, authorize('OWNER'), getEarningsChart);

// Payout requests
router.post('/earnings/request-payout', authenticate, authorize('OWNER'), requestPayout);
router.get('/earnings/payouts', authenticate, authorize('OWNER'), getPayoutHistory);

export default router;