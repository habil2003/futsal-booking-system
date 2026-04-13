import { prisma } from '../index.js';
import cron from 'node-cron';
import { generateSlotsForCourt } from '../utils/slotHelpers.js';
import { getSlotGenerationDays } from "../utils/settings.js";


/**
 * Release expired slot locks
 * Run this every minute
*/
export const releaseExpiredLocks = async () => {
  try {
    const now = new Date();

    // Find expired locked slots that have NO active booking
    const expiredLockedSlots = await prisma.timeSlot.findMany({
      where: {
        status: 'LOCKED',
        lockedUntil: { lt: now }
      },
      include: {
        bookings: {
          where: { status: { in: ['PENDING', 'CONFIRMED'] } }
        }
      }
    });

    for (const slot of expiredLockedSlots) {
      // ✅ Only release if no active booking exists
      if (slot.bookings.length === 0) {
        await prisma.timeSlot.update({
          where: { id: slot.id },
          data: { status: 'AVAILABLE', lockedUntil: null }
        });
        console.log(`🔓 Released expired lock on slot ${slot.id}`);
      }
    }

  } catch (error) {
    console.error('❌ Error releasing expired locks:', error);
  }
};

/**
 * Cancel expired pending bookings
 * Run this every hour
 */
export const cancelExpiredBookings = async () => {
  try {
    const expiryTime = new Date(Date.now() - 10 * 60 * 1000);

    const expiredBookings = await prisma.booking.findMany({
      where: {
        status: 'PENDING',
        bookingDate: { lt: expiryTime },
        paymentMethod: 'KHALTI',        // ✅ only cancel Khalti bookings
        payment: {
          status: { in: ['PENDING'] }   // ✅ only if payment still pending (never attempted)
        }
      },
      include: { payment: true, slot: true }
    });

    for (const booking of expiredBookings) {
      await prisma.$transaction(async (tx) => {
        await tx.booking.update({
          where: { id: booking.id },
          data: { status: 'CANCELLED' }
        });

        if (booking.payment) {
          await tx.payment.update({
            where: { bookingId: booking.id },
            data: { status: 'FAILED' }
          });
        }

        const freshSlot = await tx.timeSlot.findUnique({
          where: { id: booking.slotId }
        });

        if (freshSlot && freshSlot.status !== 'BOOKED') {
          await tx.timeSlot.update({
            where: { id: booking.slotId },
            data: { status: 'AVAILABLE', lockedUntil: null }
          });
        }
      });

      console.log(`🗑 Cancelled expired Khalti booking ${booking.id}`);
    }

  } catch (error) {
    console.error('❌ Error cancelling expired bookings:', error);
  }
};

/**
 * Auto-generate slots for next 30 days for all active courts
 * Run daily at midnight — ensures slots always exist 30 days ahead
 */
export const generateMissingSlots = async () => {
  try {
    console.log('🔄 Checking for courts needing slot generation...');

    // Get all active courts with their futsal (including operatingHours)
    const courts = await prisma.court.findMany({
      where: { isActive: true, isUnderMaintenance: false },
      include: { 
        futsal: true 
      }
    });

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    const targetDate = new Date(today);
    const generationDays = await getSlotGenerationDays();
    targetDate.setDate(targetDate.getDate() + generationDays);

    let totalGenerated = 0;

    for (const court of courts) {
      // Find the latest slot date for this court
      const latestSlot = await prisma.timeSlot.findFirst({
        where: { courtId: court.id },
        orderBy: { date: 'desc' }
      });

      // Determine start date for generation
      let startDate = latestSlot
        ? new Date(latestSlot.date)
        : new Date(today);
      
      // Move to next day after latest slot
      if (latestSlot) {
        startDate.setDate(startDate.getDate() + 1);
      }
      
      startDate.setHours(0, 0, 0, 0);

      // If already covered 30 days ahead, skip
      if (startDate >= targetDate) continue;

      // Generate missing slots using operating hours
      const slots = await generateSlotsForCourt(court, court.futsal, startDate, targetDate);
      
      if (slots.length > 0) {
        const result = await prisma.timeSlot.createMany({
          data: slots,
          skipDuplicates: true
        });
        totalGenerated += result.count;
        console.log(`✅ Generated ${result.count} slots for court ${court.courtNumber} (${court.futsal.name})`);
      }
    }

    console.log(`🎯 Total slots generated: ${totalGenerated}`);

  } catch (error) {
    console.error('❌ Error generating missing slots:', error);
  }
};