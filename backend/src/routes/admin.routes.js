import express from "express";
import { authenticate, authorize } from "../middleware/auth.js";

import {
  getDashboardStats,
  getUsers,
  approveOwner,
  toggleUserStatus,         // ✅ new
  getPendingFutsals,
  getAllFutsals,            // ✅ new
  approveFutsal,
  rejectFutsal,
  generateReport,            // ✅ new
  getAllBookings,
  getAdminAnalytics,
   getAdminProfile,      // ✅ Add this
  updateAdminProfile,
  getRevenueOverview,
  getCommissionBreakdown,
  getRevenueTrends,
  getPayoutRequests,
  processPayout,
  getCommissionRate,
  updateCommissionRate,
  deleteFutsal,
  adminDeactivateFutsal,
  adminActivateFutsal,
} from "../controllers/admin.controller.js";

const router = express.Router();

/* Dashboard */
router.get("/dashboard", authenticate, authorize("ADMIN"), getDashboardStats);

/* Users */
router.get("/users", authenticate, authorize("ADMIN"), getUsers);
router.patch("/users/:id/approve-owner", authenticate, authorize("ADMIN"), approveOwner);
router.patch("/users/:id/toggle-status", authenticate, authorize("ADMIN"), toggleUserStatus); // ✅ block/unblock

/* Futsal approvals */
router.get("/futsals/pending", authenticate, authorize("ADMIN"), getPendingFutsals);
router.get("/futsals", authenticate, authorize("ADMIN"), getAllFutsals); // ✅ all futsals tab
router.patch("/futsals/:id/approve", authenticate, authorize("ADMIN"), approveFutsal);
router.patch("/futsals/:id/reject", authenticate, authorize("ADMIN"), rejectFutsal);

// Add this with other futsal routes
// These should be present
router.patch("/futsals/:id/admin-deactivate", authenticate, authorize("ADMIN"), adminDeactivateFutsal);
router.patch("/futsals/:id/admin-activate", authenticate, authorize("ADMIN"), adminActivateFutsal);
router.delete("/futsals/:id", authenticate, authorize("ADMIN"), deleteFutsal);
/* Reports */
router.get("/reports", authenticate, authorize("ADMIN"), generateReport); // ✅ report endpoint

router.get("/bookings", authenticate, authorize("ADMIN"), getAllBookings);
router.get("/analytics", authenticate, authorize("ADMIN"), getAdminAnalytics);

/* Admin Profile */
router.get("/profile", authenticate, authorize("ADMIN"), getAdminProfile);
router.put("/profile", authenticate, authorize("ADMIN"), updateAdminProfile);

// ============================================
// REVENUE ROUTES
// ============================================

// Revenue overview
router.get('/revenue/overview', authenticate, authorize('ADMIN'), getRevenueOverview);

// Commission breakdown
router.get('/revenue/commission-breakdown', authenticate, authorize('ADMIN'), getCommissionBreakdown);

// Revenue trends
router.get('/revenue/trends', authenticate, authorize('ADMIN'), getRevenueTrends);

// Payout requests
router.get('/revenue/payouts', authenticate, authorize('ADMIN'), getPayoutRequests);
router.post('/revenue/payouts/:id/process', authenticate, authorize('ADMIN'), processPayout);

// Commission rate settings
router.get('/revenue/commission-rate', authenticate, authorize('ADMIN'), getCommissionRate);
router.put('/revenue/commission-rate', authenticate, authorize('ADMIN'), updateCommissionRate);

export default router;