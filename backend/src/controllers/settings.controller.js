import { prisma } from '../index.js';

/**
 * Get system settings
 */
export const getSystemSettings = async (req, res) => {
  try {
    // Get settings from database
    let settings = await prisma.systemSettings.findFirst();
    
    // Create default settings if not exist
    if (!settings) {
      settings = await prisma.systemSettings.create({
        data: {
          autoApproveOwners: false,
          autoApproveFutsals: false,
          maintenanceMode: false,
          bookingCancellationHours: 2,
          slotLockMinutes: 5,
          slotGenerationDays: 30,
          commissionRate: 5.0,
          minPayoutAmount: 1000,
          registrationFeeAmount: 500.0,
          registrationFeeEnabled: false,
        }
      });
    }
    
    res.json({ 
      status: 'success', 
      data: settings 
    });
  } catch (error) {
    console.error('Get system settings error:', error);
    res.status(500).json({ 
      status: 'error', 
      message: 'Failed to fetch settings' 
    });
  }
};

/**
 * Update system settings
 */
export const updateSystemSettings = async (req, res) => {
  try {
    const {
      autoApproveOwners,
      autoApproveFutsals,
      maintenanceMode,
      bookingCancellationHours,
      slotLockMinutes,
      slotGenerationDays,
      commissionRate,
      minPayoutAmount,
      registrationFeeAmount,
      registrationFeeEnabled
    } = req.body;
    
    // Get existing settings
    const existing = await prisma.systemSettings.findFirst();
    
    if (!existing) {
      // Create if not exists
      const settings = await prisma.systemSettings.create({
        data: {
          autoApproveOwners: autoApproveOwners ?? false,
          autoApproveFutsals: autoApproveFutsals ?? false,
          maintenanceMode: maintenanceMode ?? false,
          bookingCancellationHours: bookingCancellationHours ?? 2,
          slotLockMinutes: slotLockMinutes ?? 5,
          slotGenerationDays: slotGenerationDays ?? 30,
          commissionRate: commissionRate ?? 5.0,
          minPayoutAmount: minPayoutAmount ?? 1000,
          registrationFeeAmount: registrationFeeAmount ?? 500.0,
          registrationFeeEnabled: registrationFeeEnabled ?? false,
        }
      });
      return res.json({ status: 'success', data: settings });
    }
    
    // Update existing
    const settings = await prisma.systemSettings.update({
      where: { id: existing.id },
      data: {
        autoApproveOwners,
        autoApproveFutsals,
        maintenanceMode,
        bookingCancellationHours,
        slotLockMinutes,
        slotGenerationDays,
        commissionRate,
        minPayoutAmount,
        registrationFeeAmount,
        registrationFeeEnabled,
      }
    });
    
    res.json({ 
      status: 'success', 
      message: 'Settings updated successfully',
      data: settings 
    });
  } catch (error) {
    console.error('Update system settings error:', error);
    res.status(500).json({ 
      status: 'error', 
      message: 'Failed to update settings' 
    });
  }
};

/**
 * Get registration fee settings (NEW)
 */
export const getRegistrationFeeSettings = async (req, res) => {
  try {
    const settings = await prisma.systemSettings.findFirst();
    
    res.json({
      status: 'success',
      data: {
        registrationFeeAmount: settings?.registrationFeeAmount ?? 500.0,
        registrationFeeEnabled: settings?.registrationFeeEnabled ?? false,
      }
    });
  } catch (error) {
    console.error('Get registration fee settings error:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to fetch registration fee settings'
    });
  }
};

/**
 * Update registration fee (NEW)
 */
export const updateRegistrationFee = async (req, res) => {
  try {
    const { amount, enabled } = req.body;
    
    const existing = await prisma.systemSettings.findFirst();
    
    if (!existing) {
      const settings = await prisma.systemSettings.create({
        data: {
          registrationFeeAmount: amount ?? 500.0,
          registrationFeeEnabled: enabled ?? false,
          autoApproveOwners: false,
          autoApproveFutsals: false,
          maintenanceMode: false,
          bookingCancellationHours: 2,
          slotLockMinutes: 5,
          slotGenerationDays: 30,
          commissionRate: 5.0,
          minPayoutAmount: 1000,
        }
      });
      return res.json({
        status: 'success',
        data: {
          registrationFeeAmount: settings.registrationFeeAmount,
          registrationFeeEnabled: settings.registrationFeeEnabled,
        }
      });
    }
    
    const settings = await prisma.systemSettings.update({
      where: { id: existing.id },
      data: {
        registrationFeeAmount: amount,
        registrationFeeEnabled: enabled,
      }
    });
    
    res.json({
      status: 'success',
      data: {
        registrationFeeAmount: settings.registrationFeeAmount,
        registrationFeeEnabled: settings.registrationFeeEnabled,
      }
    });
  } catch (error) {
    console.error("Update registration fee error:", error);
    res.status(500).json({
      status: "error",
      message: "Server error: " + error.message
    });
  }
};