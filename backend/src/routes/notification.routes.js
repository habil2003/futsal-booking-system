import express from 'express';
import { authenticate, authorize } from '../middleware/auth.js';   // your auth middleware
import {
  getMyNotifications,
  markAsRead,
  markAllAsRead,
  broadcastToUsers,
} from '../controllers/notification.controller.js';

const router = express.Router();

// All logged‑in users (Player, Owner, Admin) can access these
router.get('/my', authenticate, getMyNotifications);
router.patch('/:id/read', authenticate, markAsRead);
router.patch('/read-all', authenticate, markAllAsRead);

// Only Admin can broadcast
router.post('/broadcast', authenticate, authorize('ADMIN'), broadcastToUsers);

export default router;