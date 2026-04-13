import { prisma } from "../index.js";
import axios from "axios";
import { BookingStatus } from "@prisma/client";
import { getCommissionRate, getSlotLockMinutes } from "../utils/settings.js";

// Helper function to create transaction record
async function createTransaction(booking, commission, ownerEarning, paymentMethod) {
  console.log("🔵 createTransaction START for booking:", booking.id, "method:", paymentMethod);
  
  try {
    const slot = await prisma.timeSlot.findUnique({
      where: { id: booking.slotId },
      include: {
        court: {
          include: { futsal: true },
        },
      },
    });

    if (!slot || !slot.court || !slot.court.futsal) {
      console.error("❌ Missing relations for slot:", booking.slotId);
      return null;
    }

    const futsalId = slot.court.futsalId;
    const ownerId = slot.court.futsal.ownerId;
    const requiresPayout = paymentMethod === "KHALTI";

    const result = await prisma.transaction.create({
      data: {
        bookingId: booking.id,
        futsalId: futsalId,
        ownerId: ownerId,
        amount: booking.totalPrice,
        commission: commission,
        ownerEarning: ownerEarning,
        status: paymentMethod === "COD" ? "COMPLETED" : "PENDING",
        type: "BOOKING",
        paymentMethod: paymentMethod,
        requiresPayout: requiresPayout,
      },
    });
    
    console.log("✅ Transaction CREATED successfully:", result.id);
    return result;
    
  } catch (error) {
    console.error("❌ createTransaction ERROR:", error.message);
    return null;
  }
}

// ============================================
// BOOKING CREATION
// ============================================

export const createBooking = async (req, res) => {
  try {
    const { slotId, duration = 1, paymentMethod = "COD" } = req.body;

    if (!slotId) {
      return res.status(400).json({ status: "error", message: "Slot ID is required" });
    }

    const result = await prisma.$transaction(async (tx) => {
      const startSlot = await tx.timeSlot.findUnique({
        where: { id: parseInt(slotId) },
        include: { court: { include: { futsal: true } } },
      });

      if (!startSlot) throw new Error("Slot not found");
      if (startSlot.status !== "LOCKED" || !startSlot.lockedUntil || startSlot.lockedUntil < new Date()) {
        throw new Error("Slot lock expired");
      }

      const futsalId = startSlot.court.futsalId;
      const isBlocked = await tx.block.findFirst({
        where: { playerId: req.user.id, futsalId: futsalId },
      });

      if (isBlocked) {
        await tx.timeSlot.update({
          where: { id: parseInt(slotId) },
          data: { status: "AVAILABLE", lockedUntil: null },
        });
        throw new Error("You are blocked from booking at this futsal");
      }

      let allSlots = [startSlot];

      if (duration > 1) {
        const startHour = parseInt(startSlot.startTime.split(":")[0]);
        const consecutiveSlots = await tx.timeSlot.findMany({
          where: {
            courtId: startSlot.courtId,
            date: startSlot.date,
            startTime: {
              in: Array.from({ length: duration - 1 }, (_, i) => `${String(startHour + i + 1).padStart(2, "0")}:00`),
            },
            status: "AVAILABLE",
          },
          orderBy: { startTime: "asc" },
        });

        if (consecutiveSlots.length < duration - 1) {
          throw new Error("Not enough consecutive slots available");
        }

        allSlots = [startSlot, ...consecutiveSlots];

        const lockMinutes = await getSlotLockMinutes();
        await tx.timeSlot.updateMany({
          where: { id: { in: consecutiveSlots.map((s) => s.id) } },
          data: {
            status: "LOCKED",
            lockedUntil: new Date(Date.now() + lockMinutes * 60000),
          },
        });
      }

      const activeBooking = await tx.booking.findFirst({
        where: {
          slotId: { in: allSlots.map((s) => s.id) },
          status: { in: ["PENDING", "CONFIRMED"] },
        },
      });
      if (activeBooking) throw new Error("One or more slots already booked");

      const totalPrice = allSlots.reduce((sum, s) => sum + s.price, 0);
      const groupId = `GRP_${req.user.id}_${Date.now()}`;

      const bookings = await Promise.all(
        allSlots.map((slot) =>
          tx.booking.create({
            data: {
              userId: req.user.id,
              slotId: slot.id,
              totalPrice: slot.price,
              duration: duration,
              paymentMethod: paymentMethod,
              groupId: groupId,
              status: "PENDING",
            },
            include: {
              slot: { include: { court: { include: { futsal: true } } } },
            },
          }),
        ),
      );

      await tx.timeSlot.updateMany({
        where: { id: { in: allSlots.map((s) => s.id) } },
        data: { status: "BOOKED", lockedUntil: null },
      });

      return { bookings, groupId, totalPrice, primaryBooking: bookings[0] };
    });

    const commissionRate = await getCommissionRate();
    const commission = (result.totalPrice * commissionRate) / 100;
    const ownerEarning = result.totalPrice - commission;
    
    await createTransaction(result.primaryBooking, commission, ownerEarning, paymentMethod);

    res.status(201).json({
      status: "success",
      booking: result.primaryBooking,
      bookingId: result.primaryBooking.id,
      groupId: result.groupId,
      totalPrice: result.totalPrice,
      slotCount: result.bookings.length,
    });
  } catch (error) {
    console.error("❌ CREATE BOOKING ERROR:", error);
    res.status(400).json({ status: "error", message: error.message });
  }
};

// ============================================
// GET BOOKINGS
// ============================================

export const getUserBookings = async (req, res) => {
  try {
    const bookings = await prisma.booking.findMany({
      where: { userId: req.user.id },
      include: {
        slot: { include: { court: { include: { futsal: true } } } },
        payment: true,
      },
      orderBy: { bookingDate: "desc" },
    });

    res.json({
      status: "success",
      results: bookings.length,
      bookings,
    });
  } catch (error) {
    console.error("Get user bookings error:", error);
    res.status(500).json({ status: "error", message: "Server error" });
  }
};

export const getBookingById = async (req, res) => {
  try {
    const { bookingId } = req.params;
    const booking = await prisma.booking.findFirst({
      where: { id: parseInt(bookingId), userId: req.user.id },
      include: {
        slot: { include: { court: { include: { futsal: true } } } },
        payment: true,
      },
    });

    if (!booking)
      return res.status(404).json({ status: "error", message: "Booking not found" });

    res.json({ status: "success", booking });
  } catch (error) {
    console.error("Get booking by ID error:", error);
    res.status(500).json({ status: "error", message: "Server error" });
  }
};

// ============================================
// CANCEL BOOKINGS
// ============================================

export const userCancelBooking = async (req, res) => {
  try {
    const { bookingId } = req.params;
    const booking = await prisma.booking.findUnique({
      where: { id: parseInt(bookingId) },
      include: { payment: true },
    });

    if (!booking) return res.status(404).json({ status: "error", message: "Booking not found" });
    if (booking.userId !== req.user.id) return res.status(403).json({ status: "error", message: "Unauthorized" });

    const groupBookings = booking.groupId
      ? await prisma.booking.findMany({ where: { groupId: booking.groupId } })
      : [booking];

    await prisma.$transaction(async (tx) => {
      await tx.booking.updateMany({
        where: { id: { in: groupBookings.map((b) => b.id) } },
        data: { status: "CANCELLED" },
      });
      await tx.timeSlot.updateMany({
        where: { id: { in: groupBookings.map((b) => b.slotId) } },
        data: { status: "AVAILABLE", lockedUntil: null },
      });
      await tx.transaction.updateMany({
        where: { bookingId: booking.id },
        data: { status: "FAILED" },
      });
    });

    res.json({ status: "success", message: "Booking cancelled successfully" });
  } catch (error) {
    console.error("Cancel booking error:", error);
    res.status(500).json({ status: "error", message: "Server error" });
  }
};

// ============================================
// OWNER BOOKING ACTIONS
// ============================================

export const checkInBooking = async (req, res) => {
  try {
    const { bookingId } = req.params;

    console.log("🔵 CHECK IN - Booking ID:", bookingId);

    const booking = await prisma.booking.findUnique({
      where: { id: parseInt(bookingId) },
      include: {
        slot: { include: { court: { include: { futsal: true } } } },
        payment: true,
      },
    });

    if (!booking) {
      console.log("❌ Booking not found:", bookingId);
      return res.status(404).json({ status: "error", message: "Booking not found" });
    }

    console.log("🔵 Booking found - Status:", booking.status, "PaymentMethod:", booking.paymentMethod);

    if (booking.slot.court.futsal.ownerId !== req.user.id) {
      console.log("❌ Unauthorized - Owner mismatch");
      return res.status(403).json({ status: "error", message: "Unauthorized" });
    }

    if (booking.status === "CANCELLED") {
      return res.status(400).json({ status: "error", message: "Cannot check in a cancelled booking" });
    }

    if (booking.checkInTime) {
      return res.status(400).json({ status: "error", message: "Already checked in" });
    }

    const isKhalti = booking.paymentMethod === "KHALTI";
    const isPaid = booking.payment?.status === "COMPLETED";
    
    console.log("🔵 isKhalti:", isKhalti, "isPaid:", isPaid);

    let newStatus;
    if (isKhalti && isPaid) {
      newStatus = "COMPLETED";
      console.log("🔵 Khalti paid booking - marking as COMPLETED");
    } else {
      newStatus = "CONFIRMED";
      console.log("🔵 COD or unpaid Khalti - marking as CONFIRMED");
    }

    // Update booking
    const updated = await prisma.booking.update({
      where: { id: parseInt(bookingId) },
      data: {
        status: newStatus,
        checkInTime: new Date(),
      },
    });

    console.log("✅ Booking updated to:", updated.status);

    // Update transaction if Khalti and completing
    if (isKhalti && isPaid && newStatus === "COMPLETED") {
      try {
        const txUpdate = await prisma.transaction.updateMany({
          where: { bookingId: booking.id },
          data: { status: "COMPLETED" }
        });
        console.log("✅ Transaction updated, count:", txUpdate.count);
      } catch (txError) {
        console.log("⚠️ Transaction update failed:", txError.message);
        // Don't fail the check-in if transaction update fails
      }
    }

    res.json({
      status: "success",
      message: "Customer checked in",
      booking: updated,
    });
  } catch (error) {
    console.error("❌ Check in error:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
};

export const ownerCancelBooking = async (req, res) => {
  try {
    const { bookingId } = req.params;

    const booking = await prisma.booking.findUnique({
      where: { id: parseInt(bookingId) },
      include: {
        slot: { include: { court: { include: { futsal: true } } } },
      },
    });

    if (!booking) return res.status(404).json({ status: "error", message: "Booking not found" });
    if (booking.slot.court.futsal.ownerId !== req.user.id) return res.status(403).json({ status: "error", message: "Unauthorized" });

    const groupBookings = booking.groupId
      ? await prisma.booking.findMany({ where: { groupId: booking.groupId } })
      : [booking];

    await prisma.$transaction(async (tx) => {
      await tx.booking.updateMany({
        where: { id: { in: groupBookings.map((b) => b.id) } },
        data: { status: "CANCELLED" },
      });
      await tx.timeSlot.updateMany({
        where: { id: { in: groupBookings.map((b) => b.slotId) } },
        data: { status: "AVAILABLE", lockedUntil: null },
      });
      await tx.transaction.updateMany({
        where: { bookingId: booking.id },
        data: { status: "FAILED" },
      });
    });

    res.json({ status: "success", message: "Booking cancelled successfully" });
  } catch (error) {
    console.error("Owner cancel error:", error);
    res.status(500).json({ status: "error", message: "Server error" });
  }
};

export const confirmCodPayment = async (req, res) => {
  try {
    const { bookingId } = req.params;

    const booking = await prisma.booking.findUnique({
      where: { id: parseInt(bookingId) },
      include: {
        payment: true,
        slot: { include: { court: { include: { futsal: true } } } },
      },
    });

    if (!booking) return res.status(404).json({ status: "error", message: "Booking not found" });
    if (booking.slot.court.futsal.ownerId !== req.user.id) return res.status(403).json({ status: "error", message: "Unauthorized" });
    if (booking.status === "COMPLETED") return res.status(400).json({ status: "error", message: "Booking already completed" });

    await prisma.$transaction(async (tx) => {
      if (booking.payment) {
        await tx.payment.update({ where: { bookingId: booking.id }, data: { status: "COMPLETED" } });
      } else {
        await tx.payment.create({
          data: {
            bookingId: booking.id,
            amount: booking.totalPrice,
            method: "COD",
            status: "COMPLETED",
            transactionId: `COD_${booking.id}_${Date.now()}`,
          },
        });
      }

      await tx.booking.update({
        where: { id: parseInt(bookingId) },
        data: { status: "COMPLETED", checkOutTime: new Date(), commissionPaid: true },
      });

      await tx.transaction.updateMany({
        where: { bookingId: booking.id },
        data: { status: "COMPLETED" }
      });
    });

    res.json({ status: "success", message: "Payment confirmed and booking completed" });
  } catch (error) {
    console.error("COD confirm error:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
};

// ============================================
// KHALTI PAYMENT METHODS
// ============================================

export const initiatePayment = async (req, res) => {
  const { bookingId, paymentMethod } = req.body;
  const userId = req.user.id;

  try {
    const booking = await prisma.booking.findFirst({
      where: { id: parseInt(bookingId), userId },
      include: {
        payment: true,
        slot: { include: { court: { include: { futsal: true } } } },
      },
    });

    if (!booking) return res.status(404).json({ message: "Booking not found" });
    if (booking.status !== "PENDING") return res.status(400).json({ message: "Booking already confirmed or cancelled" });

    const existingPayment = await prisma.payment.findFirst({
      where: { bookingId: booking.id, status: "PENDING" },
    });
    if (existingPayment) return res.json({ payment: existingPayment });

    if (paymentMethod === "KHALTI") {
      const amountInPaisa = Math.round(booking.totalPrice * 100);
      const payload = {
        return_url: `${process.env.BACKEND_URL}/api/bookings/payment/callback`,
        purchase_order_id: `BOOKING_${booking.id}`,
        purchase_order_name: `${booking.slot.court.futsal.name} - Booking (${booking.slot.startTime})`,
        amount: amountInPaisa,
        website_url: process.env.FRONTEND_URL,
        customer_info: {
          name: req.user.fullName || req.user.email,
          email: req.user.email,
          phone: req.user.phoneNumber || "9800000000",
        },
      };

      const resp = await axios.post("https://dev.khalti.com/api/v2/epayment/initiate/", payload, {
        headers: {
          Authorization: `Key ${process.env.KHALTI_SECRET_KEY}`,
          "Content-Type": "application/json",
        },
      });

      if (!resp.data?.pidx || !resp.data?.payment_url) {
        return res.status(400).json({ message: "Invalid Khalti response", details: resp.data });
      }

      const payment = await prisma.payment.create({
        data: {
          bookingId: booking.id,
          amount: booking.totalPrice,
          method: "KHALTI",
          status: "PENDING",
          transactionId: resp.data.pidx,
        },
      });

      return res.json({ paymentUrl: resp.data.payment_url, payment });
    }

    if (paymentMethod === "COD") {
      const [payment] = await prisma.$transaction([
        prisma.payment.create({
          data: {
            bookingId: booking.id,
            amount: booking.totalPrice,
            method: "COD",
            status: "COMPLETED",
          },
        }),
        prisma.booking.update({
          where: { id: booking.id },
          data: { status: "CONFIRMED" },
        }),
      ]);

      return res.json({ message: "Booking placed successfully", payment });
    }

    return res.status(400).json({ message: "Unsupported payment method" });
  } catch (error) {
    console.error("Payment initiation error:", error);
    return res.status(500).json({ message: "Server error", error: error.message });
  }
};

export const verifyPayment = async (req, res) => {
  const { pidx } = req.body;

  try {
    const payment = await prisma.payment.findFirst({
      where: { transactionId: pidx },
      include: { booking: true },
    });

    if (!payment) return res.status(404).json({ message: "Payment not found" });

    if (payment.status === "COMPLETED") {
      return res.json({ success: true, message: "Payment already verified", bookingId: payment.bookingId });
    }

    const response = await axios.post(
      "https://a.khalti.com/api/v2/epayment/lookup/",
      { pidx },
      { headers: { Authorization: `Key ${process.env.KHALTI_SECRET_KEY}` } }
    );

    const status = response.data.status?.toString().toLowerCase();
    const isSuccess = status === "completed" || status === "success";

    if (isSuccess) {
      const [updatedPayment, updatedBooking] = await prisma.$transaction([
        prisma.payment.update({
          where: { id: payment.id },
          data: { status: "COMPLETED", transactionId: response.data.transaction_id || payment.transactionId },
        }),
        prisma.booking.update({
          where: { id: payment.bookingId },
          data: { status: "CONFIRMED", paymentStatus: "PAID" },
        }),
        prisma.transaction.updateMany({
          where: { bookingId: payment.bookingId },
          data: { status: "COMPLETED" }
        }),
      ]);

      return res.json({ success: true, message: "Payment verified successfully", bookingId: updatedBooking.id });
    } else {
      await prisma.$transaction([
        prisma.payment.update({ where: { id: payment.id }, data: { status: "FAILED" } }),
        prisma.booking.update({ where: { id: payment.bookingId }, data: { paymentMethod: "COD", status: "PENDING" } }),
        prisma.transaction.updateMany({ where: { bookingId: payment.bookingId }, data: { status: "FAILED" } }),
      ]);

      return res.json({
        success: false,
        message: "Payment failed. Booking converted to COD. Please pay at venue.",
        bookingId: payment.bookingId,
        convertedToCOD: true,
      });
    }
  } catch (error) {
    console.error("Payment verification error:", error);
    return res.status(400).json({ success: false, message: "Payment verification failed" });
  }
};

export const paymentCallback = async (req, res) => {
  const { pidx, booking_id } = req.query;
  const frontendUrl = process.env.FRONTEND_URL || "http://localhost:3000";

  try {
    if (!pidx) {
      return res.redirect(`${frontendUrl}/payment-status?status=error&message=No payment ID received`);
    }

    const response = await axios.post(
      "https://a.khalti.com/api/v2/epayment/lookup/",
      { pidx },
      { headers: { Authorization: `Key ${process.env.KHALTI_SECRET_KEY}` } }
    );

    const payment = await prisma.payment.findFirst({ where: { transactionId: pidx } });
    if (!payment) {
      return res.redirect(`${frontendUrl}/payment-status?status=error&message=Payment not found`);
    }

    const status = response.data.status?.toString().toLowerCase();
    const isSuccess = status === "completed" || status === "success";

    if (isSuccess && payment.status !== "COMPLETED") {
      await prisma.$transaction([
        prisma.payment.update({ where: { id: payment.id }, data: { status: "COMPLETED" } }),
        prisma.booking.update({ where: { id: payment.bookingId }, data: { status: "CONFIRMED" } }),
      ]);
      return res.redirect(`${frontendUrl}/payment-status?status=success&booking_id=${booking_id}`);
    } else {
      await prisma.$transaction([
        prisma.payment.update({ where: { id: payment.id }, data: { status: "FAILED" } }),
        prisma.booking.update({ where: { id: payment.bookingId }, data: { paymentMethod: "COD", status: "PENDING" } }),
      ]);
      return res.redirect(`${frontendUrl}/payment-status?status=failed&converted_to_cod=true&booking_id=${booking_id}`);
    }
  } catch (error) {
    console.error("Callback error:", error);
    return res.redirect(`${frontendUrl}/payment-status?status=error&message=${encodeURIComponent(error.message)}`);
  }
};

// ============================================
// OWNER DASHBOARD METHODS
// ============================================

export const getOwnerTodayBookings = async (req, res) => {
  try {
    const { futsalId } = req.query;
    
    const today = new Date();
    const startOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate());
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate());
    endOfDay.setHours(23, 59, 59, 999);

    const bookings = await prisma.booking.findMany({
      where: {
        slot: { court: { futsalId: parseInt(futsalId) }, date: { gte: startOfDay, lte: endOfDay } },
        status: { in: ["PENDING", "CONFIRMED"] },
      },
      include: {
        slot: { include: { court: true } },
        user: { select: { fullName: true, phoneNumber: true, email: true } },
        payment: true,
      },
      orderBy: { slot: { startTime: "asc" } },
    });

    res.json({ bookings: bookings });
  } catch (error) {
    console.error("Get today bookings error:", error);
    res.status(500).json({ status: "error", message: "Server error" });
  }
};

export const getOwnerUpcomingBookings = async (req, res) => {
  try {
    const { futsalId } = req.query;

    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const startOfTomorrow = new Date(tomorrow.getFullYear(), tomorrow.getMonth(), tomorrow.getDate());
    startOfTomorrow.setHours(0, 0, 0, 0);

    const bookings = await prisma.booking.findMany({
      where: {
        slot: { court: { futsalId: parseInt(futsalId) }, date: { gte: startOfTomorrow } },
        status: { in: ["PENDING", "CONFIRMED"] },
      },
      include: {
        slot: { include: { court: true } },
        user: { select: { fullName: true, phoneNumber: true, email: true } },
        payment: true,
      },
      orderBy: [{ slot: { date: "asc" } }, { slot: { startTime: "asc" } }],
    });

    res.json({ bookings: bookings });
  } catch (error) {
    console.error("Get upcoming bookings error:", error);
    res.status(500).json({ status: "error", message: "Server error" });
  }
};

export const getOwnerMonthBookings = async (req, res) => {
  try {
    const { year, month } = req.params;
    const { futsalId } = req.query;
    const futsalIdInt = parseInt(futsalId);
    const yearInt = parseInt(year);
    const monthInt = parseInt(month);

    const startDate = new Date(yearInt, monthInt - 1, 1);
    startDate.setHours(0, 0, 0, 0);
    const endDate = new Date(yearInt, monthInt, 0);
    endDate.setHours(23, 59, 59, 999);

    const bookings = await prisma.booking.findMany({
      where: {
        slot: { court: { futsalId: futsalIdInt }, date: { gte: startDate, lte: endDate } },
      },
      include: {
        slot: { include: { court: true } },
        user: { select: { fullName: true, phoneNumber: true, email: true } },
        payment: true,
      },
      orderBy: { slot: { date: "asc" } },
    });

    res.json({ bookings: bookings });
  } catch (error) {
    console.error("Get month bookings error:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
};

export const getOwnerBookings = async (req, res) => {
  try {
    const { futsalId, status, courtId, date } = req.query;

    const where = {
      slot: { court: { futsalId: parseInt(futsalId) } },
    };

    if (status) where.status = status;
    if (courtId) where.slot.courtId = parseInt(courtId);
    if (date) {
      const filterDate = new Date(date);
      filterDate.setHours(0, 0, 0, 0);
      where.slot.date = filterDate;
    }

    const bookings = await prisma.booking.findMany({
      where,
      include: {
        slot: { include: { court: true } },
        user: { select: { fullName: true, phoneNumber: true, email: true } },
        payment: true,
      },
      orderBy: { bookingDate: "desc" },
    });

    res.json({ bookings: bookings });
  } catch (error) {
    console.error("Get owner bookings error:", error);
    res.status(500).json({ status: "error", message: "Server error" });
  }
};