import { Router } from 'express';
import multer from 'multer';
import { CloudinaryStorage } from 'multer-storage-cloudinary';
import cloudinary from '../config/cloudinary.js';
import { authenticate } from '../middleware/auth.js';
import { prisma } from '../index.js';

import {
  listAddresses,
  createAddress,
  updateAddress,
  deleteAddress,
} from '../controllers/address.controller.js';

const router = Router();

// ───── Profile image upload (PLAYER etc.) ─────
const profileStorage = new CloudinaryStorage({
  cloudinary,
  params: (req, file) => ({
    folder: 'futsal-system/profiles',
    allowed_formats: ['jpg', 'jpeg', 'png', 'webp'],
    transformation: [
      { width: 400, height: 400, crop: 'limit' },
      { quality: 'auto' },
    ],
    public_id: `profile_${req.user ? req.user.id : Date.now()}_${Date.now()}`,
  }),
});

const profileUpload = multer({
  storage: profileStorage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) cb(null, true);
    else cb(new Error('Only images allowed'), false);
  },
});

router.post(
  '/profile/image',
  authenticate,
  profileUpload.single('image'),
  async (req, res) => {
    try {
      if (!req.file) {
        return res.status(400).json({ status: 'error', message: 'No image provided' });
      }
      const userId = req.user.id;
      const profileImage = req.file.path;

      await prisma.user.update({
        where: { id: userId },
        data: { profileImage },
      });

      res.json({
        status: 'success',
        message: 'Profile picture updated',
        profileImage,
      });
    } catch (error) {
      console.error('Profile image upload error:', error);
      res.status(500).json({ status: 'error', message: 'Upload failed' });
    }
  }
);

// ───── Addresses ─────
router.get('/addresses', authenticate, listAddresses);
router.post('/addresses', authenticate, createAddress);
router.put('/addresses/:id', authenticate, updateAddress);
router.delete('/addresses/:id', authenticate, deleteAddress);

export default router;
