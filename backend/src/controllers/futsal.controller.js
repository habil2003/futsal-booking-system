import { prisma } from "../index.js";
import { generateSlotsForCourt } from "../utils/slotHelpers.js";
import axios from "axios";  // ✅ ADD THIS LINE

// Mock payment function - REPLACE with actual payment gateway later
async function createRegistrationPaymentIntent(futsalId, amount, ownerId) {
  // This is a mock implementation for testing
  // TODO: Replace with Khalti/eSewa/Stripe integration
  console.log(`📝 Creating payment intent for futsal ${futsalId}, amount: ${amount}`);
  return {
    client_secret: `mock_secret_${futsalId}_${Date.now()}`,
    amount: amount,
    futsalId: futsalId
  };
}

async function verifyPayment(paymentIntentId) {
  // This is a mock implementation for testing
  // TODO: Replace with actual payment verification
  console.log(`🔍 Verifying payment: ${paymentIntentId}`);
  return true;
}

/**
 * Get all approved futsals
 */
export const getAllFutsals = async (req, res) => {
  try {
    const { lat, lng, radius } = req.query;

    let whereClause = { 
      status: 'ACTIVE',
      registrationFeePaid: true  // Only show if fee is paid
    };

    if (lat && lng && radius) {
      whereClause = {
        ...whereClause,
        latitude: { not: null },
        longitude: { not: null },
      };
    }

    const futsals = await prisma.futsal.findMany({
      where: whereClause,
      include: {
        reviews: {
          select: { rating: true },
        },
        owner: {
          select: { fullName: true },
        },
        courts: {
          select: {
            id: true,
            courtNumber: true,
            courtType: true,
            basePrice: true,
            peakPrice: true,
            amenities: true,
            isActive: true,
          },
        },
        _count: {
          select: {
            courts: true,
            reviews: true,
          },
        },
      },
      orderBy: {
        createdAt: "desc",
      },
    });

    const futsalsWithRating = futsals.map((futsal) => {
      const avgRating =
        futsal.reviews.length > 0
          ? futsal.reviews.reduce((sum, review) => sum + review.rating, 0) /
            futsal.reviews.length
          : 0;

      const { reviews, ...futsalWithoutReviews } = futsal;

      return {
        ...futsalWithoutReviews,
        averageRating: Math.round(avgRating * 10) / 10,
        courtCount: futsal._count?.courts || 0,
      };
    });

    res.json({
      status: "success",
      results: futsalsWithRating.length,
      futsals: futsalsWithRating,
    });
  } catch (error) {
    console.error("Get all futsals error:", error);
    res.status(500).json({
      status: "error",
      message: "Server error: " + error.message,
    });
  }
};

/**
 * Get futsal by ID
 */
export const getFutsalById = async (req, res) => {
  try {
    const { id } = req.params;

    if (!id) {
      return res.status(400).json({
        status: "error",
        message: "Futsal ID is required",
      });
    }

    const futsalId = parseInt(id);
    if (isNaN(futsalId)) {
      return res.status(400).json({
        status: "error",
        message: "Invalid futsal ID format",
      });
    }

    const futsal = await prisma.futsal.findUnique({
      where: { id: futsalId },
      include: {
        reviews: {
          include: {
            user: {
              select: { id: true, fullName: true },
            },
          },
          orderBy: {
            createdAt: "desc",
          },
        },
        owner: {
          select: { id: true, fullName: true, email: true, phoneNumber: true },
        },
        courts: {
          select: {
            id: true,
            courtNumber: true,
            courtType: true,
            basePrice: true,
            peakPrice: true,
            isActive: true,
          },
        },
      },
    });

    if (!futsal) {
      return res.status(404).json({
        status: "error",
        message: "Futsal not found",
      });
    }

    const avgRating =
      futsal.reviews.length > 0
        ? futsal.reviews.reduce((sum, review) => sum + review.rating, 0) /
          futsal.reviews.length
        : 0;

    const response = {
      ...futsal,
      averageRating: Math.round(avgRating * 10) / 10,
    };

    res.json({
      status: "success",
      futsal: response,
    });
  } catch (error) {
    console.error("Get futsal by ID error:", error);
    res.status(500).json({
      status: "error",
      message: "Server error: " + error.message,
    });
  }
};

/**
 * Get available slots for a futsal
 */
/**
 * Get available slots for a futsal
 */
export const getFutsalSlots = async (req, res) => {
  try {
    const { id } = req.params;
    const { date } = req.query;

    if (!date) {
      return res.status(400).json({
        status: "error",
        message: "Please provide a date",
      });
    }

    const queryDate = new Date(date);
    queryDate.setHours(0, 0, 0, 0);
    const nextDay = new Date(queryDate);
    nextDay.setDate(nextDay.getDate() + 1);

    // Get current time for today's date
    const now = new Date();
    const isToday = queryDate.toDateString() === now.toDateString();
    const currentHour = now.getHours();
    const currentMinute = now.getMinutes();

    const slots = await prisma.timeSlot.findMany({
      where: {
        court: {
          futsalId: parseInt(id),
        },
        date: {
          gte: queryDate,
          lt: nextDay,
        },
      },
      include: {
        court: {
          select: {
            courtNumber: true,
            courtType: true,
          },
        },
      },
      orderBy: [{ court: { courtNumber: "asc" } }, { startTime: "asc" }],
    });

    // ✅ Filter out past slots for today
    let filteredSlots = slots;
    if (isToday) {
      filteredSlots = slots.filter((slot) => {
        const [hour, minute] = slot.startTime.split(':').map(Number);
        // Hide slots that have already started or passed
        if (hour < currentHour) return false;
        if (hour === currentHour && minute <= currentMinute) return false;
        return true;
      });
    }

    const formattedSlots = filteredSlots.map((slot) => ({
      id: slot.id,
      courtId: slot.courtId,
      courtNumber: slot.court.courtNumber,
      courtType: slot.court.courtType,
      date: slot.date,
      startTime: slot.startTime,
      endTime: slot.endTime,
      price: slot.price,
      status: slot.status,
      lockedUntil: slot.lockedUntil,
    }));

    res.json({
      status: "success",
      results: formattedSlots.length,
      slots: formattedSlots,
    });
  } catch (error) {
    console.error("Get futsal slots error:", error);
    res.status(500).json({
      status: "error",
      message: "Server error: " + error.message,
    });
  }
};

/**
 * Helper function to regenerate future slots when operating hours change
 */
async function regenerateFutureSlots(futsalId) {
  console.log(`🔄 Regenerating future slots for futsal ${futsalId}...`);
  
  const futsal = await prisma.futsal.findUnique({
    where: { id: futsalId },
    include: { courts: { where: { isActive: true } } }
  });
  
  if (!futsal || futsal.courts.length === 0) {
    console.log(`⚠️ No active courts found for futsal ${futsalId}`);
    return;
  }
  
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const thirtyDaysLater = new Date(today);
  thirtyDaysLater.setDate(thirtyDaysLater.getDate() + 30);
  
  let totalGenerated = 0;
  let totalDeleted = 0;
  
  for (const court of futsal.courts) {
    // Delete future available slots (only AVAILABLE ones, keep BOOKED/LOCKED)
    const deleted = await prisma.timeSlot.deleteMany({
      where: {
        courtId: court.id,
        date: { gte: today, lte: thirtyDaysLater },
        status: 'AVAILABLE'
      }
    });
    totalDeleted += deleted.count;
    
    // Generate new slots with updated operating hours
    const slots = await generateSlotsForCourt(court, futsal, today, thirtyDaysLater);
    
    if (slots.length > 0) {
      const result = await prisma.timeSlot.createMany({
        data: slots,
        skipDuplicates: true
      });
      totalGenerated += result.count;
      console.log(`✅ Court ${court.courtNumber}: Deleted ${deleted.count}, Generated ${result.count} slots`);
    }
  }
  
  console.log(`🎯 Total: Deleted ${totalDeleted} slots, Generated ${totalGenerated} slots`);
}

/**
 * Create a new futsal
 */
// Add this to createFutsal function
export const createFutsal = async (req, res) => {
  try {
    const {
      name,
      description,
      address,
      images,
      latitude,
      longitude,
      operatingHours,
    } = req.body;

    if (!name || !address) {
      return res.status(400).json({
        status: "error",
        message: "Please provide name and address",
      });
    }

    if (!req.user || !req.user.id) {
      return res.status(401).json({
        status: "error",
        message: "Authentication required",
      });
    }

    // Check if registration fee is enabled
    const settings = await prisma.systemSettings.findFirst();
    const registrationFeeEnabled = settings?.registrationFeeEnabled || false;
    const registrationFeeAmount = settings?.registrationFeeAmount || 500;

    // Determine initial status
    let initialStatus = 'PENDING_PAYMENT';
    if (!registrationFeeEnabled) {
      initialStatus = 'PENDING';
    }

    const futsal = await prisma.futsal.create({
      data: {
        name,
        description,
        address,
        images: images || [],
        latitude: latitude ? parseFloat(latitude) : null,
        longitude: longitude ? parseFloat(longitude) : null,
        operatingHours: operatingHours || null,
        ownerId: req.user.id,
        status: initialStatus,
        registrationFeePaid: !registrationFeeEnabled,
      },
    });

    res.status(201).json({
      status: "success",
      message: registrationFeeEnabled 
        ? "Futsal created. Please pay registration fee to activate."
        : "Futsal created successfully. Waiting for admin approval.",
      requiresPayment: registrationFeeEnabled,
      registrationFeeAmount: registrationFeeAmount,
      futsal: futsal,
    });
  } catch (error) {
    console.error("Create futsal error:", error);
    res.status(500).json({
      status: "error",
      message: "Server error: " + error.message,
    });
  }
};

/**
 * Update futsal details
 */
export const updateFutsal = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      name,
      description,
      address,
      images,
      latitude,
      longitude,
      operatingHours,
      isApproved,
      status,
      toggleActive,
    } = req.body;
    
    const futsalId = parseInt(id);
    
    const existingFutsal = await prisma.futsal.findFirst({
      where: {
        id: futsalId,
        ownerId: req.user.id,
      },
    });

    if (!existingFutsal && req.user.role !== "ADMIN") {
      return res.status(404).json({
        status: "error",
        message: "Futsal not found or you do not have permission",
      });
    }

    // Handle owner toggle active (deactivate/reactivate)
    let newStatus = status;
    if (toggleActive) {
      // Check if admin deactivated this futsal
      if (existingFutsal.deactivatedBy === 'ADMIN') {
        return res.status(403).json({
          status: "error",
          message: "This futsal was deactivated by admin. You cannot reactivate it.",
        });
      }
      
      // Owner toggle
      newStatus = existingFutsal.status === 'ACTIVE' ? 'DEACTIVATED' : 'ACTIVE';
      
      // If deactivating, set deactivatedBy = OWNER
      if (newStatus === 'DEACTIVATED') {
        await prisma.futsal.update({
          where: { id: futsalId },
          data: {
            status: newStatus,
            deactivatedBy: 'OWNER',
            deactivatedAt: new Date(),
          },
        });
        
        return res.json({
          status: "success",
          message: "Futsal deactivated successfully",
          futsal: existingFutsal,
        });
      } else {
        // Reactivating - clear deactivatedBy
        await prisma.futsal.update({
          where: { id: futsalId },
          data: {
            status: newStatus,
            deactivatedBy: null,
            deactivatedAt: null,
          },
        });
        
        return res.json({
          status: "success",
          message: "Futsal activated successfully",
          futsal: existingFutsal,
        });
      }
    }

    // Handle admin status change
    if (isApproved !== undefined && req.user.role === "ADMIN") {
      newStatus = isApproved ? 'ACTIVE' : 'DEACTIVATED';
    }

    // Check if operating hours changed
    const operatingHoursChanged = operatingHours && 
      JSON.stringify(operatingHours) !== JSON.stringify(existingFutsal.operatingHours);

    const futsal = await prisma.futsal.update({
      where: { id: futsalId },
      data: {
        name,
        description,
        address,
        images,
        latitude: latitude ? parseFloat(latitude) : undefined,
        longitude: longitude ? parseFloat(longitude) : undefined,
        operatingHours: operatingHours !== undefined ? operatingHours : undefined,
        status: newStatus !== undefined ? newStatus : undefined,
      },
    });

    // If operating hours changed, regenerate future slots
    if (operatingHoursChanged) {
      await regenerateFutureSlots(futsalId);
    }

    res.json({
      status: "success",
      message: "Futsal updated successfully",
      futsal,
    });
  } catch (error) {
    console.error("Update futsal error:", error);
    res.status(500).json({
      status: "error",
      message: "Server error: " + error.message,
    });
  }
};

/**
 * Delete a futsal
 */
export const deleteFutsal = async (req, res) => {
  try {
    const { id } = req.params;
    const futsalId = parseInt(id);

    const existingFutsal = await prisma.futsal.findFirst({
      where: {
        id: futsalId,
        ownerId: req.user.id,
      },
    });

    if (!existingFutsal && req.user.role !== "ADMIN") {
      return res.status(404).json({
        status: "error",
        message: "Futsal not found or you do not have permission",
      });
    }

    // Check for bookings (blocks deletion for ACTIVE futsals)
    const bookingCount = await prisma.booking.count({
      where: {
        slot: {
          court: {
            futsalId: futsalId,
          },
        },
      },
    });

    if (bookingCount > 0) {
      return res.status(400).json({
        status: "error",
        message: "Cannot delete futsal. It has existing bookings.",
        details: { bookings: bookingCount },
      });
    }

    // Check if payment was made (has transaction record)
    const transactionCount = await prisma.transaction.count({
      where: { futsalId: futsalId },
    });

    const hasPayment = transactionCount > 0;

    // For PENDING_PAYMENT (no payment) - Owner can delete
    if (existingFutsal.status === 'PENDING_PAYMENT' && !hasPayment) {
      // Delete favorites first
      await prisma.favorite.deleteMany({ where: { futsalId: futsalId } });
      // Delete the futsal
      await prisma.futsal.delete({ where: { id: futsalId } });
      
      return res.json({
        status: "success",
        message: "Futsal deleted successfully",
      });
    }

    // For PENDING or any status with payment - Only Admin can delete
    if (req.user.role === "ADMIN") {
      // Admin force delete - no refund
      await prisma.$transaction([
        prisma.favorite.deleteMany({ where: { futsalId: futsalId } }),
        prisma.transaction.deleteMany({ where: { futsalId: futsalId } }),
        prisma.futsal.delete({ where: { id: futsalId } }),
      ]);
      
      return res.json({
        status: "success",
        message: "Futsal deleted successfully by admin",
      });
    }

    // Owner trying to delete a futsal that has payment
    return res.status(400).json({
      status: "error",
      message: "Cannot delete futsal after payment. Please contact admin.",
    });
    
  } catch (error) {
    console.error("Delete futsal error:", error);
    res.status(500).json({
      status: "error",
      message: "Server error: " + error.message,
    });
  }
};

/**
 * GET OWNER'S FUTSALS - For Dashboard
 */
export const getMyFutsals = async (req, res) => {
  console.log("\n📍 GET MY FUTSALS API HIT");

  try {
    if (!req.user || !req.user.id) {
      return res.status(401).json({
        status: "error",
        message: "User not authenticated",
      });
    }

    const futsals = await prisma.futsal.findMany({
      where: { ownerId: req.user.id },
      include: {
        _count: {
          select: {
            courts: true,
          },
        },
      },
      orderBy: {
        createdAt: "desc",
      },
    });

    const futsalsWithCount = futsals.map((futsal) => ({
      ...futsal,
      courtCount: futsal._count?.courts || 0,
      needsRegistrationPayment: futsal.status === 'PENDING_PAYMENT',
      registrationFeePaid: futsal.registrationFeePaid,
      registrationFeeAmount: futsal.registrationFeeAmount ?? 10,
      // ✅ Add this flag for frontend
      adminDeactivated: futsal.deactivatedBy === 'ADMIN',
    }));

    res.json({
      status: "success",
      results: futsalsWithCount.length,
      futsals: futsalsWithCount,
    });
  } catch (error) {
    console.error("\n❌ ERROR in getMyFutsals:", error);
    res.status(500).json({
      status: "error",
      message: "Server error: " + error.message,
    });
  }
};

// Add this to futsal.controller.js
export const confirmRegistrationPayment = async (req, res) => {
  try {
    const { futsalId, paymentIntentId } = req.body;
    
    // Verify payment with your payment gateway
    const paymentVerified = await verifyPayment(paymentIntentId);
    
    if (!paymentVerified) {
      return res.status(400).json({
        status: "error",
        message: "Payment verification failed"
      });
    }
    
    // Update futsal
    const futsal = await prisma.futsal.update({
      where: { id: parseInt(futsalId) },
      data: {
        registrationFeePaid: true,
        registrationPaidAt: new Date(),
        status: 'PENDING'  // Now ready for admin approval
      }
    });
    
    // Record in PlatformRevenue
    const settings = await prisma.systemSettings.findFirst();
    await prisma.platformRevenue.create({
      data: {
        amount: settings?.registrationFeeAmount || 500,
        type: 'REGISTRATION',
        description: `Registration fee for futsal ID: ${futsalId}`,
        bookingId: null
      }
    });
    
    res.json({
      status: "success",
      message: "Payment confirmed. Futsal is now pending admin approval.",
      futsal
    });
  } catch (error) {
    console.error("Confirm registration payment error:", error);
    res.status(500).json({
      status: "error",
      message: "Server error: " + error.message
    });
  }
};

// ============================================
// KHALTI PAYMENT FOR REGISTRATION FEE
// ============================================

export const initiateRegistrationPayment = async (req, res) => {
  try {
    const { futsalId } = req.body;
    const userId = req.user.id;

    // Check if futsal exists and belongs to this owner
    const futsal = await prisma.futsal.findFirst({
      where: { 
        id: parseInt(futsalId),
        ownerId: userId
      }
    });

    if (!futsal) {
      return res.status(404).json({ message: "Futsal not found" });
    }

    // Check if registration fee already paid
    if (futsal.registrationFeePaid) {
      return res.status(400).json({ message: "Registration fee already paid" });
    }

    // Get registration fee amount
    const settings = await prisma.systemSettings.findFirst();
    const amount = settings?.registrationFeeAmount || 500;
    const amountInPaisa = Math.round(amount * 100);

    // Create Khalti payment payload
    const payload = {
      return_url: `${process.env.BACKEND_URL}/api/futsals/registration-payment/callback`,
      purchase_order_id: `REG_${futsal.id}_${Date.now()}`,
      purchase_order_name: `Futsal Registration Fee - ${futsal.name}`,
      amount: amountInPaisa,
      website_url: process.env.FRONTEND_URL,
      customer_info: {
        name: req.user.fullName || req.user.email,
        email: req.user.email,
        phone: req.user.phoneNumber || "9800000000",
      },
    };

    console.log("📝 Khalti registration payment payload:", payload);

    const response = await axios.post(
      "https://dev.khalti.com/api/v2/epayment/initiate/",
      payload,
      {
        headers: {
          Authorization: `Key ${process.env.KHALTI_SECRET_KEY}`,
          "Content-Type": "application/json",
        },
      }
    );

    if (!response.data?.pidx || !response.data?.payment_url) {
      return res.status(400).json({ 
        message: "Invalid Khalti response", 
        details: response.data 
      });
    }

    // Store payment info in a temporary record or session
    // You can create a RegistrationPayment model or use existing Payment model
    // For now, store in a variable or create a new model

    return res.json({ 
      paymentUrl: response.data.payment_url, 
      pidx: response.data.pidx,
      futsalId: futsal.id
    });

  } catch (error) {
    console.error("Registration payment initiation error:", error);
    return res.status(500).json({ 
      message: "Server error", 
      error: error.message 
    });
  }
};

export const verifyRegistrationPayment = async (req, res) => {
  const { pidx, futsalId } = req.body;

  try {
    console.log("🔍 Verifying registration payment:", { pidx, futsalId });

    const response = await axios.post(
      "https://a.khalti.com/api/v2/epayment/lookup/",
      { pidx },
      { 
        headers: { 
          Authorization: `Key ${process.env.KHALTI_SECRET_KEY}` 
        } 
      }
    );

    const status = response.data.status?.toString().toLowerCase();
    const isSuccess = status === "completed" || status === "success";

    if (isSuccess) {
      const futsal = await prisma.futsal.findUnique({
        where: { id: parseInt(futsalId) }
      });
      
      if (!futsal) {
        return res.status(404).json({ success: false, message: "Futsal not found" });
      }
      
      const settings = await prisma.systemSettings.findFirst();
      const registrationFeeAmount = settings?.registrationFeeAmount || 500;

      await prisma.futsal.update({
        where: { id: parseInt(futsalId) },
        data: {
          registrationFeePaid: true,
          registrationPaidAt: new Date(),
          status: 'PENDING'
        }
      });

      await prisma.platformRevenue.create({
        data: {
          amount: registrationFeeAmount,
          type: 'REGISTRATION',
          description: `Registration fee for futsal ID: ${futsalId}`,
          bookingId: null
        }
      });

      // ✅ REMOVED bookingId
      await prisma.transaction.create({
        data: {
          futsalId: parseInt(futsalId),
          ownerId: futsal.ownerId,
          amount: registrationFeeAmount,
          commission: 0,
          ownerEarning: 0,
          status: 'COMPLETED',
          type: 'REGISTRATION_FEE',
          paymentMethod: 'KHALTI',
          requiresPayout: false
        }
      });

      return res.json({ 
        success: true, 
        message: "Registration fee paid successfully"
      });
    } else {
      return res.json({
        success: false,
        message: "Payment failed. Please try again.",
      });
    }
  } catch (error) {
    console.error("Registration payment verification error:", error);
    return res.status(400).json({ 
      success: false, 
      message: "Payment verification failed: " + error.message
    });
  }
};

export const registrationPaymentCallback = async (req, res) => {
  const { pidx, purchase_order_id } = req.query;
  const frontendUrl = process.env.FRONTEND_URL || "http://localhost:3000";

  try {
    console.log("📞 Registration payment callback:", { pidx, purchase_order_id });

    if (!pidx) {
      return res.redirect(`${frontendUrl}/futsal-registration-status?status=error&message=No payment ID received`);
    }

    // Extract futsalId from purchase_order_id (format: REG_{futsalId}_{timestamp})
    const futsalId = parseInt(purchase_order_id.split('_')[1]);
    
    // FIRST, get the futsal to find the ownerId
    const futsal = await prisma.futsal.findUnique({
      where: { id: futsalId }
    });
    
    if (!futsal) {
      return res.redirect(`${frontendUrl}/futsal-registration-status?status=error&message=Futsal not found`);
    }
    
    // Verify payment
    const response = await axios.post(
      "https://a.khalti.com/api/v2/epayment/lookup/",
      { pidx },
      { 
        headers: { 
          Authorization: `Key ${process.env.KHALTI_SECRET_KEY}` 
        } 
      }
    );

    const status = response.data.status?.toString().toLowerCase();
    const isSuccess = status === "completed" || status === "success";

    if (isSuccess) {
      const settings = await prisma.systemSettings.findFirst();
      const registrationFeeAmount = settings?.registrationFeeAmount || 500;

      // ✅ REMOVED bookingId from transaction creation
      await prisma.$transaction([
        prisma.futsal.update({
          where: { id: futsalId },
          data: {
            registrationFeePaid: true,
            registrationPaidAt: new Date(),
            status: 'PENDING'
          }
        }),
        prisma.platformRevenue.create({
          data: {
            amount: registrationFeeAmount,
            type: 'REGISTRATION',
            description: `Registration fee for futsal ID: ${futsalId}`,
            bookingId: null
          }
        }),
        prisma.transaction.create({
          data: {
            // bookingId is OMITTED (will be null)
            futsalId: futsalId,
            ownerId: futsal.ownerId,
            amount: registrationFeeAmount,
            commission: 0,
            ownerEarning: 0,
            status: 'COMPLETED',
            type: 'REGISTRATION_FEE',
            paymentMethod: 'KHALTI',
            requiresPayout: false
          }
        })
      ]);

      return res.redirect(`${frontendUrl}/futsal-registration-status?status=success&futsal_id=${futsalId}`);
    } else {
      return res.redirect(`${frontendUrl}/futsal-registration-status?status=failed&futsal_id=${futsalId}`);
    }
  } catch (error) {
    console.error("Registration payment callback error:", error);
    return res.redirect(`${frontendUrl}/futsal-registration-status?status=error&message=${encodeURIComponent(error.message)}`);
  }
};