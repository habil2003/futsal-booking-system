import express from 'express';
import {
  createTournament,
  getAllTournaments,
  updateTournament,
  deleteTournament,
  getPublishedTournaments,
  getFutsalsForDropdown,
} from '../controllers/tournamentController.js';
import adUpload from '../middleware/adUpload.js';
import { authenticate, authorize } from '../middleware/auth.js';

const router = express.Router();

// Public
router.get('/published', getPublishedTournaments);

// Admin only
router.use(authenticate);
router.use(authorize('ADMIN'));

router.get('/futsals/dropdown', getFutsalsForDropdown);
router.post('/', adUpload.single('image'), createTournament);
router.get('/', getAllTournaments);
router.put('/:id', adUpload.single('image'), updateTournament);
router.patch('/:id', adUpload.single('image'), updateTournament);
router.delete('/:id', deleteTournament);

export default router;