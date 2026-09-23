import { prisma } from '../index.js';

export const listAddresses = async (req, res) => {
  try {
    const userId = req.user.id;
    const addresses = await prisma.address.findMany({
      where: { userId },
      orderBy: [{ isDefault: 'desc' }, { createdAt: 'desc' }],
    });
    res.json({ status: 'success', addresses });
  } catch (error) {
    console.error('List addresses error:', error);
    res.status(500).json({ status: 'error', message: 'Server error' });
  }
};

export const createAddress = async (req, res) => {
  try {
    const userId = req.user.id;
    const { label, fullAddress, city, phone, latitude, longitude, isDefault } = req.body;

    if (!label || !String(label).trim()) {
      return res.status(400).json({ status: 'error', message: 'Label is required' });
    }
    if (!fullAddress || !String(fullAddress).trim()) {
      return res.status(400).json({ status: 'error', message: 'Address is required' });
    }

    const shouldDefault = isDefault === true;
    if (shouldDefault) {
      await prisma.address.updateMany({
        where: { userId },
        data: { isDefault: false },
      });
    }

    const address = await prisma.address.create({
      data: {
        userId,
        label: String(label).trim(),
        fullAddress: String(fullAddress).trim(),
        city: city ? String(city).trim() : null,
        phone: phone ? String(phone).trim() : null,
        latitude: latitude != null ? Number(latitude) : null,
        longitude: longitude != null ? Number(longitude) : null,
        isDefault: shouldDefault,
      },
    });

    res.status(201).json({ status: 'success', message: 'Address added', address });
  } catch (error) {
    console.error('Create address error:', error);
    res.status(500).json({ status: 'error', message: 'Server error' });
  }
};

export const updateAddress = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;
    const { label, fullAddress, city, phone, latitude, longitude, isDefault } = req.body;

    const existing = await prisma.address.findFirst({ where: { id: Number(id), userId } });
    if (!existing) {
      return res.status(404).json({ status: 'error', message: 'Address not found' });
    }

    const shouldDefault = isDefault === true;
    if (shouldDefault) {
      await prisma.address.updateMany({
        where: { userId },
        data: { isDefault: false },
      });
    }

    const address = await prisma.address.update({
      where: { id: existing.id },
      data: {
        label: label !== undefined ? String(label).trim() : undefined,
        fullAddress: fullAddress !== undefined ? String(fullAddress).trim() : undefined,
        city: city !== undefined ? (city ? String(city).trim() : null) : undefined,
        phone: phone !== undefined ? (phone ? String(phone).trim() : null) : undefined,
        latitude: latitude !== undefined ? (latitude != null ? Number(latitude) : null) : undefined,
        longitude: longitude !== undefined ? (longitude != null ? Number(longitude) : null) : undefined,
        isDefault: shouldDefault,
      },
    });

    res.json({ status: 'success', message: 'Address updated', address });
  } catch (error) {
    console.error('Update address error:', error);
    res.status(500).json({ status: 'error', message: 'Server error' });
  }
};

export const deleteAddress = async (req, res) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const existing = await prisma.address.findFirst({ where: { id: Number(id), userId } });
    if (!existing) {
      return res.status(404).json({ status: 'error', message: 'Address not found' });
    }

    await prisma.address.delete({ where: { id: existing.id } });
    res.json({ status: 'success', message: 'Address deleted' });
  } catch (error) {
    console.error('Delete address error:', error);
    res.status(500).json({ status: 'error', message: 'Server error' });
  }
};
