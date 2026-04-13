import { prisma } from "../index.js";

let cachedSettings = null;
let lastFetch = null;
const CACHE_DURATION = 60000; // 1 minute

export async function getSystemSettings() {
  const now = Date.now();
  
  if (cachedSettings && lastFetch && (now - lastFetch) < CACHE_DURATION) {
    return cachedSettings;
  }
  
  let settings = await prisma.systemSettings.findFirst();
  
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
      },
    });
  }
  
  cachedSettings = settings;
  lastFetch = now;
  
  return settings;
}

export async function getSlotLockMinutes() {
  const settings = await getSystemSettings();
  return settings.slotLockMinutes;
}

export async function getSlotGenerationDays() {
  const settings = await getSystemSettings();
  return settings.slotGenerationDays;
}

export async function getCommissionRate() {
  const settings = await getSystemSettings();
  return settings.commissionRate;
}

export async function getMinPayoutAmount() {
  const settings = await getSystemSettings();
  return settings.minPayoutAmount;
}

export async function invalidateSettingsCache() {
  cachedSettings = null;
  lastFetch = null;
}