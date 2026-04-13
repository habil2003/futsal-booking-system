import { prisma } from "../index.js";
import { getMinPayoutAmount } from "../utils/settings.js";

/**
 * Get dashboard statistics for an owner's futsal
 * @route   GET /api/owner/dashboard/stats?futsalId=:id
 */
export const getDashboardStats = async (req, res) => {
  try {
    const { futsalId } = req.query;

    if (!futsalId) {
      return res.status(400).json({
        status: "error",
        message: "Please provide futsal ID",
      });
    }

    // Verify the futsal belongs to this owner
    const futsal = await prisma.futsal.findFirst({
      where: {
        id: parseInt(futsalId),
        ownerId: req.user.id,
      },
    });

    if (!futsal) {
      return res.status(404).json({
        status: "error",
        message: "Futsal not found or you do not have permission",
      });
    }

    // Get total courts
    const totalCourts = await prisma.court.count({
      where: { futsalId: parseInt(futsalId) },
    });

    // Get today's bookings
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const todayBookings = await prisma.booking.count({
      where: {
        slot: {
          date: { gte: today, lt: tomorrow }, // ← slot date only
          court: {
            futsalId: parseInt(futsalId),
          },
        },
        status: { in: ["CONFIRMED", "PENDING", "COMPLETED"] },
      },
    });

    // Get today's revenue
    const todayRevenue = await prisma.booking.aggregate({
      where: {
        slot: {
          date: { gte: today, lt: tomorrow }, // ← slot date only
          court: {
            futsalId: parseInt(futsalId),
          },
        },
        status: { in: ["CONFIRMED", "COMPLETED"] },
      },
      _sum: {
        totalPrice: true,
      },
    });

    // Get pending approvals (for futsal itself)
    const pendingApprovals = futsal.isApproved ? 0 : 1;

    res.json({
      status: "success",
      totalCourts,
      todayBookings,
      todayRevenue: todayRevenue._sum?.totalPrice || 0,
      pendingApprovals,
    });
  } catch (error) {
    console.error("Get dashboard stats error:", error);
    res.status(500).json({
      status: "error",
      message: "Server error: " + error.message,
    });
  }
};

export const getOwnerTodayBookings = async (req, res) => {
  try {
    const { futsalId } = req.query;

    // Get today's date range (start to end of day)
    const today = new Date();
    const startOfDay = new Date(
      today.getFullYear(),
      today.getMonth(),
      today.getDate(),
    );
    startOfDay.setHours(0, 0, 0, 0);

    const endOfDay = new Date(
      today.getFullYear(),
      today.getMonth(),
      today.getDate(),
    );
    endOfDay.setHours(23, 59, 59, 999);

    console.log("🔵 TODAY TAB - Date range:", { startOfDay, endOfDay });

    const bookings = await prisma.booking.findMany({
      where: {
        slot: {
          court: { futsalId: parseInt(futsalId) },
          date: {
            gte: startOfDay,
            lte: endOfDay,
          },
        },
        status: { not: "CANCELLED" },
      },
      include: {
        slot: { include: { court: true } },
        user: { select: { fullName: true, phoneNumber: true, email: true } },
        payment: true,
      },
      orderBy: { slot: { startTime: "asc" } },
    });

    console.log("🔵 TODAY TAB - Found bookings:", bookings.length);
    res.json({ bookings: bookings });
  } catch (error) {
    console.error("Get today bookings error:", error);
    res.status(500).json({ status: "error", message: "Server error" });
  }
};

/**
 * Get weekly revenue data for charts
 * @route   GET /api/owner/dashboard/weekly-revenue?futsalId=:id
 */
export const getWeeklyRevenue = async (req, res) => {
  try {
    const { futsalId } = req.query;

    if (!futsalId) {
      return res.status(400).json({
        status: "error",
        message: "Please provide futsal ID",
      });
    }

    // Verify ownership
    const futsal = await prisma.futsal.findFirst({
      where: {
        id: parseInt(futsalId),
        ownerId: req.user.id,
      },
    });

    if (!futsal) {
      return res.status(404).json({
        status: "error",
        message: "Futsal not found or you do not have permission",
      });
    }

    // Get last 7 days
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const weeklyRevenue = [];

    for (let i = 6; i >= 0; i--) {
      const date = new Date(today);
      date.setDate(date.getDate() - i);
      const nextDate = new Date(date);
      nextDate.setDate(nextDate.getDate() + 1);

      const revenue = await prisma.booking.aggregate({
        where: {
          slot: {
            date: {
              // ← filter by slot date not booking date
              gte: date,
              lt: nextDate,
            },
            court: {
              futsalId: parseInt(futsalId),
            },
          },
          status: { in: ["CONFIRMED", "COMPLETED"] }, // ← include COMPLETED too
        },
        _sum: {
          totalPrice: true,
        },
      });
      weeklyRevenue.push(revenue._sum?.totalPrice || 0);
    }

    res.json({
      status: "success",
      revenue: weeklyRevenue,
    });
  } catch (error) {
    console.error("Get weekly revenue error:", error);
    res.status(500).json({
      status: "error",
      message: "Server error: " + error.message,
    });
  }
};

/**
 * Get peak hours analysis
 * @route   GET /api/owner/dashboard/peak-hours?futsalId=:id
 */
export const getPeakHours = async (req, res) => {
  try {
    const { futsalId } = req.query;

    if (!futsalId) {
      return res.status(400).json({
        status: "error",
        message: "Please provide futsal ID",
      });
    }

    // Verify ownership
    const futsal = await prisma.futsal.findFirst({
      where: {
        id: parseInt(futsalId),
        ownerId: req.user.id,
      },
    });

    if (!futsal) {
      return res.status(404).json({
        status: "error",
        message: "Futsal not found or you do not have permission",
      });
    }

    // Get all confirmed bookings for this futsal
    const bookings = await prisma.booking.findMany({
      where: {
        slot: {
          court: {
            futsalId: parseInt(futsalId),
          },
        },
        status: { in: ["CONFIRMED", "COMPLETED"] },
      },
      include: {
        slot: {
          select: {
            startTime: true,
          },
        },
      },
    });

    // Count bookings by hour
    const peakHours = {};

    bookings.forEach((booking) => {
      const hour = booking.slot.startTime.split(":")[0] + ":00";
      peakHours[hour] = (peakHours[hour] || 0) + 1;
    });

    res.json({
      status: "success",
      peakHours,
    });
  } catch (error) {
    console.error("Get peak hours error:", error);
    res.status(500).json({
      status: "error",
      message: "Server error: " + error.message,
    });
  }
};

/**
 * Get upcoming bookings for owner
 * @route   GET /api/owner/bookings/upcoming?futsalId=:id
 */
export const getOwnerUpcomingBookings = async (req, res) => {
  try {
    const { futsalId } = req.query;

    // Get tomorrow's start date (exclude today completely)
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const startOfTomorrow = new Date(
      tomorrow.getFullYear(),
      tomorrow.getMonth(),
      tomorrow.getDate(),
    );
    startOfTomorrow.setHours(0, 0, 0, 0);

    console.log("🔵 UPCOMING TAB - Start from:", startOfTomorrow);

    const bookings = await prisma.booking.findMany({
      where: {
        slot: {
          court: { futsalId: parseInt(futsalId) },
          date: { gte: startOfTomorrow }, // ✅ Only tomorrow and beyond
        },
        status: { not: "CANCELLED" },
      },
      include: {
        slot: { include: { court: true } },
        user: { select: { fullName: true, phoneNumber: true, email: true } },
        payment: true,
      },
      orderBy: [{ slot: { date: "asc" } }, { slot: { startTime: "asc" } }],
    });

    console.log("🔵 UPCOMING TAB - Found bookings:", bookings.length);
    res.json({ bookings: bookings });
  } catch (error) {
    console.error("Get upcoming bookings error:", error);
    res.status(500).json({ status: "error", message: "Server error" });
  }
};

/**
 * Get month bookings for calendar view
 * @route   GET /api/owner/bookings/month?futsalId=:id&year=:year&month=:month
 */
export const getMonthBookings = async (req, res) => {
  try {
    const { futsalId, year, month } = req.query;

    if (!futsalId || !year || !month) {
      return res.status(400).json({
        status: "error",
        message: "Please provide futsal ID, year, and month",
      });
    }

    // Verify ownership
    const futsal = await prisma.futsal.findFirst({
      where: {
        id: parseInt(futsalId),
        ownerId: req.user.id,
      },
    });

    if (!futsal) {
      return res.status(404).json({
        status: "error",
        message: "Futsal not found or you do not have permission",
      });
    }

    const startDate = new Date(parseInt(year), parseInt(month) - 1, 1);
    const endDate = new Date(parseInt(year), parseInt(month), 0);

    const bookings = await prisma.booking.findMany({
      where: {
        slot: {
          date: { gte: startDate, lte: endDate },
          court: { futsalId: parseInt(futsalId) },
        },
      },
      include: {
        user: {
          select: {
            fullName: true,
          },
        },
        slot: {
          include: {
            court: {
              select: {
                courtNumber: true,
              },
            },
          },
        },
      },
      orderBy: {
        bookingDate: "asc",
      },
    });

    const formattedBookings = bookings.map((booking) => ({
      id: booking.id,
      customerName: booking.user.fullName,
      courtNumber: booking.slot.court.courtNumber,
      date: booking.slot.date,
      startTime: booking.slot.startTime,
      endTime: booking.slot.endTime,
      totalAmount: booking.totalPrice,
      status: booking.status,
    }));

    res.json({
      status: "success",
      bookings: formattedBookings,
    });
  } catch (error) {
    console.error("Get month bookings error:", error);
    res.status(500).json({
      status: "error",
      message: "Server error: " + error.message,
    });
  }
};

// ============================================
// EARNINGS & PAYOUT ENDPOINTS
// ============================================

/**
 * Get owner earnings overview
 * @route   GET /api/owner/earnings/overview
 */
export const getEarningsOverview = async (req, res) => {
  try {
    const ownerId = req.user.id;
    const { period = "month" } = req.query;
    
    let startDate;
    const now = new Date();
    
    switch (period) {
      case "today":
        startDate = new Date(now);
        startDate.setHours(0, 0, 0, 0);
        break;
      case "week":
        startDate = new Date(now);
        startDate.setDate(now.getDate() - 7);
        break;
      case "month":
        startDate = new Date(now.getFullYear(), now.getMonth(), 1);
        break;
      case "year":
        startDate = new Date(now.getFullYear(), 0, 1);
        break;
      default:
        startDate = new Date(now);
        startDate.setDate(now.getDate() - 30);
    }
    
    // Total earnings from ALL completed transactions
    const totalEarnings = await prisma.transaction.aggregate({
      where: {
        ownerId: ownerId,
        createdAt: { gte: startDate, lte: now },
        status: "COMPLETED",
      },
      _sum: { ownerEarning: true },
    });
    
    // COD earnings (owner already has cash, no payout needed)
    const codEarnings = await prisma.transaction.aggregate({
      where: {
        ownerId: ownerId,
        createdAt: { gte: startDate, lte: now },
        status: "COMPLETED",
        paymentMethod: "COD",
      },
      _sum: { ownerEarning: true },
    });
    
    // Khalti earnings (waiting for payout)
    const khaltiEarnings = await prisma.transaction.aggregate({
      where: {
        ownerId: ownerId,
        createdAt: { gte: startDate, lte: now },
        status: "COMPLETED",
        paymentMethod: "KHALTI",
      },
      _sum: { ownerEarning: true },
    });
    
    // Pending payout = ONLY Khalti transactions not yet paid out
    const pendingPayout = await prisma.transaction.aggregate({
      where: {
        ownerId: ownerId,
        status: "COMPLETED",
        paymentMethod: "KHALTI",
        payoutId: null,
      },
      _sum: { ownerEarning: true },
    });
    
    // Total paid out = Khalti transactions that have been paid out
    const totalPaidOut = await prisma.payout.aggregate({
      where: {
        ownerId: ownerId,
        status: "COMPLETED",
      },
      _sum: { amount: true },
    });
    
    // Total bookings count
    const totalBookings = await prisma.booking.count({
      where: {
        status: { in: ["CONFIRMED", "COMPLETED"] },
        slot: {
          court: {
            futsal: { ownerId: ownerId }
          }
        },
        bookingDate: { gte: startDate, lte: now },
      },
    });
    
    // Get minimum payout amount from settings
    const settings = await prisma.systemSettings.findFirst();
    const minPayoutAmount = settings?.minPayoutAmount || 1000;
    
    console.log("🔵 Earnings data:", {
      ownerId,
      totalEarnings: totalEarnings._sum.ownerEarning || 0,
      codEarnings: codEarnings._sum.ownerEarning || 0,
      khaltiEarnings: khaltiEarnings._sum.ownerEarning || 0,
      pendingPayout: pendingPayout._sum.ownerEarning || 0,
      totalBookings,
    });
    
    res.json({
      status: "success",
      data: {
        totalEarnings: totalEarnings._sum.ownerEarning || 0,
        codEarnings: codEarnings._sum.ownerEarning || 0,
        khaltiEarnings: khaltiEarnings._sum.ownerEarning || 0,
        pendingPayout: pendingPayout._sum.ownerEarning || 0,
        totalPaidOut: totalPaidOut._sum.amount || 0,
        totalBookings,
        minPayoutAmount,
        period: { startDate, endDate: now },
      },
    });
  } catch (error) {
    console.error("Get earnings overview error:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
};

/**
 * Get earnings breakdown by futsal
 * @route   GET /api/owner/earnings/breakdown
 */
export const getEarningsBreakdown = async (req, res) => {
  try {
    const ownerId = req.user.id;
    const { futsalId, from, to } = req.query;

    const startDate = from
      ? new Date(from)
      : new Date(new Date().setDate(new Date().getDate() - 30));
    const endDate = to ? new Date(to) : new Date();

    const whereCondition = {
      ownerId: ownerId,
      createdAt: { gte: startDate, lte: endDate },
      status: "COMPLETED",
    };

    if (futsalId) {
      whereCondition.futsalId = parseInt(futsalId);
    }

    // Get transactions grouped by futsal
    const transactions = await prisma.transaction.groupBy({
      by: ["futsalId"],
      where: whereCondition,
      _sum: {
        amount: true,
        commission: true,
        ownerEarning: true,
      },
      _count: {
        id: true,
      },
      orderBy: {
        _sum: { ownerEarning: "desc" },
      },
    });

    // Get futsal names
    const breakdown = await Promise.all(
      transactions.map(async (item) => {
        const futsal = await prisma.futsal.findUnique({
          where: { id: item.futsalId },
          select: { name: true },
        });

        return {
          futsalId: item.futsalId,
          futsalName: futsal?.name || "Unknown",
          totalBookings: item._count.id,
          totalAmount: item._sum.amount || 0,
          totalCommission: item._sum.commission || 0,
          totalEarnings: item._sum.ownerEarning || 0,
        };
      }),
    );

    // Get overall totals
    const totals = await prisma.transaction.aggregate({
      where: whereCondition,
      _sum: {
        amount: true,
        commission: true,
        ownerEarning: true,
      },
      _count: { id: true },
    });

    res.json({
      status: "success",
      data: {
        breakdown,
        totals: {
          totalBookings: totals._count.id || 0,
          totalAmount: totals._sum.amount || 0,
          totalCommission: totals._sum.commission || 0,
          totalEarnings: totals._sum.ownerEarning || 0,
        },
      },
    });
  } catch (error) {
    console.error("Get earnings breakdown error:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
};

/**
 * Get earnings history (transactions list)
 * @route   GET /api/owner/earnings/history
 */
export const getEarningsHistory = async (req, res) => {
  try {
    const ownerId = req.user.id;
    const { page = 1, limit = 20, from, to } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const startDate = from ? new Date(from) : undefined;
    const endDate = to ? new Date(to) : undefined;

    const whereCondition = {
      ownerId: ownerId,
      status: "COMPLETED",
    };

    if (startDate && endDate) {
      whereCondition.createdAt = { gte: startDate, lte: endDate };
    }

    const [transactions, total] = await Promise.all([
      prisma.transaction.findMany({
        where: whereCondition,
        include: {
          booking: {
            include: {
              slot: {
                include: {
                  court: {
                    include: {
                      futsal: { select: { name: true } },
                    },
                  },
                },
              },
            },
          },
          futsal: { select: { name: true } },
        },
        orderBy: { createdAt: "desc" },
        skip,
        take: parseInt(limit),
      }),
      prisma.transaction.count({ where: whereCondition }),
    ]);

    res.json({
      status: "success",
      data: {
        transactions,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          totalPages: Math.ceil(total / parseInt(limit)),
        },
      },
    });
  } catch (error) {
    console.error("Get earnings history error:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
};

/**
 * Request a payout (only for Khalti earnings)
 * @route   POST /api/owner/earnings/request-payout
 */
export const requestPayout = async (req, res) => {
  try {
    const ownerId = req.user.id;
    
    // Get pending Khalti earnings only
    const pendingKhaltiEarnings = await prisma.transaction.aggregate({
      where: {
        ownerId: ownerId,
        status: "COMPLETED",
        paymentMethod: "KHALTI",
        payoutId: null,
      },
      _sum: { ownerEarning: true },
    });
    
    const availableAmount = pendingKhaltiEarnings._sum.ownerEarning || 0;
    
    // Get minimum payout amount from settings
    const settings = await prisma.systemSettings.findFirst();
    const minPayoutAmount = settings?.minPayoutAmount || 1000;
    
    if (availableAmount < minPayoutAmount) {
      return res.status(400).json({
        status: "error",
        message: `Minimum payout amount is रू ${minPayoutAmount}. You have रू ${availableAmount} available from Khalti payments.`,
      });
    }
    
    // Get all pending Khalti transactions
    const pendingTransactions = await prisma.transaction.findMany({
      where: {
        ownerId: ownerId,
        status: "COMPLETED",
        paymentMethod: "KHALTI",
        payoutId: null,
      },
    });
    
    if (pendingTransactions.length === 0) {
      return res.status(400).json({
        status: "error",
        message: "No pending earnings to request payout.",
      });
    }
    
    // Create payout request
    const payout = await prisma.payout.create({
      data: {
        ownerId: ownerId,
        amount: availableAmount,
        status: "PENDING",
        requestDate: new Date(),
      },
    });
    
    // Link transactions to this payout
    await prisma.transaction.updateMany({
      where: {
        id: { in: pendingTransactions.map(t => t.id) },
      },
      data: { payoutId: payout.id },
    });
    
    res.json({
      status: "success",
      message: `Payout request of रू ${availableAmount} submitted successfully`,
      data: payout,
    });
  } catch (error) {
    console.error("Request payout error:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
};

/**
 * Get payout history
 * @route   GET /api/owner/earnings/payouts
 */
export const getPayoutHistory = async (req, res) => {
  try {
    const ownerId = req.user.id;

    const payouts = await prisma.payout.findMany({
      where: { ownerId: ownerId },
      include: {
        transactions: {
          include: {
            booking: {
              include: {
                slot: {
                  include: {
                    court: {
                      include: {
                        futsal: { select: { name: true } },
                      },
                    },
                  },
                },
              },
            },
          },
        },
      },
      orderBy: { requestDate: "desc" },
    });

    res.json({
      status: "success",
      data: payouts,
    });
  } catch (error) {
    console.error("Get payout history error:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
};

/**
 * Get daily earnings chart data
 * @route   GET /api/owner/earnings/chart
 */
export const getEarningsChart = async (req, res) => {
  try {
    const ownerId = req.user.id;
    const { days = 30 } = req.query;
    const numDays = parseInt(days);

    const endDate = new Date();
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - numDays);

    const results = [];
    let currentDate = new Date(startDate);

    while (currentDate <= endDate) {
      const dayStart = new Date(currentDate);
      dayStart.setHours(0, 0, 0, 0);
      const dayEnd = new Date(currentDate);
      dayEnd.setHours(23, 59, 59, 999);

      const earnings = await prisma.transaction.aggregate({
        where: {
          ownerId: ownerId,
          createdAt: { gte: dayStart, lte: dayEnd },
          status: "COMPLETED",
        },
        _sum: { ownerEarning: true },
        _count: { id: true },
      });

      results.push({
        date: currentDate.toISOString().split("T")[0],
        label: currentDate.toLocaleDateString("en-US", {
          month: "short",
          day: "numeric",
        }),
        earnings: earnings._sum.ownerEarning || 0,
        bookings: earnings._count.id || 0,
      });

      currentDate.setDate(currentDate.getDate() + 1);
    }

    res.json({
      status: "success",
      data: results,
    });
  } catch (error) {
    console.error("Get earnings chart error:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
};
