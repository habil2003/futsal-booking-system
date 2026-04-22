import { prisma } from "../index.js";

/**
 * Get Admin Dashboard Stats
 */
export const getDashboardStats = async (req, res, next) => {
  try {
    const totalUsers = await prisma.user.count();

    const totalFutsals = await prisma.futsal.count({
      where: { status: 'ACTIVE' },
    });

    const pendingFutsals = await prisma.futsal.count({
      where: { status: 'PENDING' },
    });

    // ✅ Show ALL bookings
    const totalBookings = await prisma.booking.count();
    
    // ✅ Show completed bookings separately
    const completedBookings = await prisma.booking.count({
      where: { status: "COMPLETED" },
    });
    
    // ✅ Show pending + confirmed (active bookings)
    const activeBookings = await prisma.booking.count({
      where: { status: { in: ["PENDING", "CONFIRMED"] } },
    });
    
    // ✅ Show cancelled bookings
    const cancelledBookings = await prisma.booking.count({
      where: { status: "CANCELLED" },
    });

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const todayBookings = await prisma.booking.count({
      where: {
        bookingDate: {
          gte: today,
          lt: tomorrow,
        },
      },
    });

    // ✅ Revenue from completed bookings only
    const bookingRevenue = await prisma.booking.aggregate({
      _sum: { totalPrice: true },
      where: {
        status: { in: ["CONFIRMED", "COMPLETED"] },
      },
    });

    // ✅ NEW: Get registration fee revenue from PlatformRevenue
    const registrationRevenue = await prisma.platformRevenue.aggregate({
      _sum: { amount: true },
      where: {
        type: "REGISTRATION",
      },
    });

    // ✅ Total revenue = booking revenue + registration fees
    const totalRevenue = (bookingRevenue._sum.totalPrice || 0) + (registrationRevenue._sum.amount || 0);
    
    const recentBookings = await prisma.booking.findMany({
      orderBy: { bookingDate: "desc" },
      take: 5,
      include: {
        user: { select: { fullName: true } },
        slot: { include: { court: true } },
      },
    });

    res.json({
      status: "success",
      data: {
        totalUsers,
        totalFutsals,
        pendingFutsals,
        totalBookings,
        completedBookings,
        activeBookings,
        cancelledBookings,
        todayBookings,
        totalRevenue,
        bookingRevenue: bookingRevenue._sum.totalPrice || 0,
        registrationRevenue: registrationRevenue._sum.amount || 0,
        recentActivities: recentBookings,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get All Users
 */
export const getUsers = async (req, res, next) => {
  try {
    const users = await prisma.user.findMany({
      orderBy: {
        createdAt: "desc",
      },
    });

    res.json({
      status: "success",
      data: users,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Approve Owner Account
 */
export const approveOwner = async (req, res, next) => {
  try {
    const userId = parseInt(req.params.id);

    const user = await prisma.user.update({
      where: { id: userId },
      data: {
        isApproved: true,
      },
    });

    res.json({
      status: "success",
      message: "Owner approved successfully",
      data: user,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get Pending Futsals
 */
export const getPendingFutsals = async (req, res, next) => {
  try {
    const futsals = await prisma.futsal.findMany({
      where: { status: 'PENDING' },
      include: {
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
            amenities: true,
          },
        },
      },
      orderBy: { createdAt: "desc" },
    });

    res.json({ status: "success", data: futsals });
  } catch (error) {
    next(error);
  }
};

/**
 * Approve Futsal
 */
export const approveFutsal = async (req, res, next) => {
  try {
    const futsalId = parseInt(req.params.id);

    console.log(`🟢 Approving futsal ${futsalId}`);

    // First, check if futsal exists and has paid registration fee
    const futsal = await prisma.futsal.findUnique({
      where: { id: futsalId },
    });

    if (!futsal) {
      return res.status(404).json({
        status: "error",
        message: "Futsal not found",
      });
    }

    // Check if registration fee is paid
    if (!futsal.registrationFeePaid) {
      return res.status(400).json({
        status: "error",
        message: "Cannot approve: Registration fee not paid yet",
      });
    }

    const updatedFutsal = await prisma.futsal.update({
      where: { id: futsalId },
      data: {
        isApproved: true,
        status: 'ACTIVE',
      },
    });

    console.log(`✅ Futsal ${futsalId} (${futsal.name}) approved successfully`);

    res.json({
      status: "success",
      message: "Futsal approved successfully",
      data: updatedFutsal,
    });
  } catch (error) {
    console.error("❌ Approve futsal error:", error);
    res.status(500).json({
      status: "error",
      message: "Server error: " + error.message,
    });
  }
};

/**
 * Reject Futsal
 */
export const rejectFutsal = async (req, res, next) => {
  try {
    const futsalId = parseInt(req.params.id);
    const { reason } = req.body;

    console.log(`🔴 Rejecting futsal ${futsalId}, reason: ${reason || 'No reason provided'}`);

    // First, check if futsal exists
    const futsal = await prisma.futsal.findUnique({
      where: { id: futsalId },
      include: {
        courts: true,
        transactions: true,
      },
    });

    if (!futsal) {
      return res.status(404).json({
        status: "error",
        message: "Futsal not found",
      });
    }

    console.log(`📋 Futsal details: ${futsal.name}, Status: ${futsal.status}, Has transactions: ${futsal.transactions?.length || 0}`);

    // Delete all related records in correct order
    await prisma.$transaction(async (tx) => {
      // 1. Delete all time slots for courts
      for (const court of futsal.courts) {
        await tx.timeSlot.deleteMany({
          where: { courtId: court.id },
        });
      }

      // 2. Delete all courts
      await tx.court.deleteMany({
        where: { futsalId: futsalId },
      });

      // 3. Delete all favorites
      await tx.favorite.deleteMany({
        where: { futsalId: futsalId },
      });

      // 4. Delete all transactions related to this futsal
      await tx.transaction.deleteMany({
        where: { futsalId: futsalId },
      });

      // 5. Delete all blocks related to this futsal
      await tx.block.deleteMany({
        where: { futsalId: futsalId },
      });

      // 6. Finally, delete the futsal
      await tx.futsal.delete({
        where: { id: futsalId },
      });
    });

    console.log(`✅ Futsal ${futsalId} (${futsal.name}) rejected and deleted successfully`);

    res.json({
      status: "success",
      message: "Futsal rejected and removed successfully",
    });
  } catch (error) {
    console.error("❌ Reject futsal error:", error);
    res.status(500).json({
      status: "error",
      message: "Server error: " + error.message,
    });
  }
};

/**
 * Get All Futsals (for admin)
 */
export const getAllFutsals = async (req, res, next) => {
  try {
    const futsals = await prisma.futsal.findMany({
      include: {
        owner: { select: { id: true, fullName: true, email: true } },
        courts: {
          select: {
            id: true,
            courtNumber: true,
            courtType: true,
            basePrice: true,
            isActive: true,
          },
        },
        _count: {
          select: { courts: true },
        },
      },
      orderBy: { createdAt: "desc" },
    });

    // Add court count to each futsal
    const futsalsWithCount = futsals.map(futsal => ({
      ...futsal,
      courtCount: futsal._count?.courts || 0,
    }));

    res.json({ status: "success", data: futsalsWithCount });
  } catch (error) {
    next(error);
  }
};

export const adminDeactivateFutsal = async (req, res, next) => {
  try {
    const futsalId = parseInt(req.params.id);

    const futsal = await prisma.futsal.update({
      where: { id: futsalId },
      data: {
        status: 'DEACTIVATED',
        deactivatedBy: 'ADMIN',
        deactivatedAt: new Date(),
      },
    });

    res.json({
      status: "success",
      message: "Futsal deactivated by admin. Owner cannot reactivate.",
      data: futsal,
    });
  } catch (error) {
    console.error("Admin deactivate error:", error);
    res.status(500).json({
      status: "error",
      message: "Server error: " + error.message,
    });
  }
};

export const adminActivateFutsal = async (req, res, next) => {
  try {
    const futsalId = parseInt(req.params.id);

    const futsal = await prisma.futsal.update({
      where: { id: futsalId },
      data: {
        status: 'ACTIVE',
        deactivatedBy: null,
        deactivatedAt: null,
      },
    });

    res.json({
      status: "success",
      message: "Futsal activated by admin.",
      data: futsal,
    });
  } catch (error) {
    console.error("Admin activate error:", error);
    res.status(500).json({
      status: "error",
      message: "Server error: " + error.message,
    });
  }
};



/**
 * Delete Futsal (Admin force delete)
 */
export const deleteFutsal = async (req, res, next) => {
  try {
    const futsalId = parseInt(req.params.id);

    const futsal = await prisma.futsal.findUnique({
      where: { id: futsalId },
      include: {
        courts: {
          include: {
            slots: true,
          },
        },
        transactions: true,
      },
    });

    if (!futsal) {
      return res.status(404).json({
        status: "error",
        message: "Futsal not found",
      });
    }

    // Check if there are any bookings through slots
    let hasBookings = false;
    for (const court of futsal.courts) {
      const bookingCount = await prisma.booking.count({
        where: {
          slot: {
            courtId: court.id,
          },
        },
      });
      if (bookingCount > 0) {
        hasBookings = true;
        break;
      }
    }

    if (hasBookings) {
      return res.status(400).json({
        status: "error",
        message: "Cannot delete futsal with existing bookings. Archive instead.",
      });
    }

    // Delete all related records
    await prisma.$transaction(async (tx) => {
      // Delete slots
      for (const court of futsal.courts) {
        await tx.timeSlot.deleteMany({ where: { courtId: court.id } });
      }
      // Delete courts
      await tx.court.deleteMany({ where: { futsalId: futsalId } });
      // Delete favorites
      await tx.favorite.deleteMany({ where: { futsalId: futsalId } });
      // Delete transactions
      await tx.transaction.deleteMany({ where: { futsalId: futsalId } });
      // Delete blocks
      await tx.block.deleteMany({ where: { futsalId: futsalId } });
      // Delete futsal
      await tx.futsal.delete({ where: { id: futsalId } });
    });

    res.json({
      status: "success",
      message: "Futsal deleted successfully",
    });
  } catch (error) {
    console.error("Admin delete futsal error:", error);
    res.status(500).json({
      status: "error",
      message: "Server error: " + error.message,
    });
  }
};

/**
 * Toggle User Active Status
 */
export const toggleUserStatus = async (req, res, next) => {
  try {
    const userId = parseInt(req.params.id);
    const { isActive } = req.body;

    const user = await prisma.user.update({
      where: { id: userId },
      data: { isActive },
    });

    res.json({ status: "success", data: user });
  } catch (error) {
    next(error);
  }
};

/**
 * Generate Report
 */
export const generateReport = async (req, res, next) => {
  try {
    const { type, from, to } = req.query;
    const fromDate = new Date(from);
    const toDate = new Date(to);

    let data;
    if (type === "bookings") {
      data = await prisma.booking.findMany({
        where: { bookingDate: { gte: fromDate, lte: toDate } },
        include: {
          user: { select: { fullName: true, email: true } },
          slot: {
            include: {
              court: {
                include: { futsal: { select: { name: true } } }
              }
            }
          }
        },
      });
    } else if (type === "revenue") {
      data = await prisma.payment.findMany({
        where: {
          createdAt: { gte: fromDate, lte: toDate },
          status: "COMPLETED",
        },
        include: {
          booking: {
            include: {
              slot: {
                include: {
                  court: {
                    include: { futsal: { select: { name: true } } }
                  }
                }
              }
            }
          }
        },
      });
    }

    res.json({ status: "success", data });
  } catch (error) {
    next(error);
  }
};

/**
 * Get All Bookings
 */
export const getAllBookings = async (req, res, next) => {
  try {
    const { status, from, to, page = 1, limit = 20 } = req.query;

    const where = {};

    if (status && status !== 'ALL') {
      where.status = status;
    }

    if (from && to) {
      where.slot = {
        date: {
          gte: new Date(from),
          lte: new Date(to),
        },
      };
    }

    const total = await prisma.booking.count({ where });

    const bookings = await prisma.booking.findMany({
      where,
      include: {
        user: { select: { id: true, fullName: true, email: true } },
        slot: {
          include: {
            court: {
              include: {
                futsal: { select: { id: true, name: true } },
              },
            },
          },
        },
        payment: true,
      },
      orderBy: { bookingDate: 'desc' },
      skip: (parseInt(page) - 1) * parseInt(limit),
      take: parseInt(limit),
    });

    const formatted = bookings.map(b => ({
      id: b.id,
      playerName: b.user.fullName,
      playerEmail: b.user.email,
      futsalName: b.slot.court.futsal.name,
      courtNumber: b.slot.court.courtNumber,
      date: b.slot.date,
      startTime: b.slot.startTime,
      endTime: b.slot.endTime,
      duration: b.duration,  // ✅ Added
      totalPrice: b.totalPrice,
      paymentMethod: b.paymentMethod,
      paymentStatus: b.payment?.status ?? 'PENDING',
      bookingStatus: b.status,
      bookingDate: b.bookingDate,
    }));

    res.json({
      status: 'success',
      total,
      page: parseInt(page),
      totalPages: Math.ceil(total / parseInt(limit)),
      bookings: formatted,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get Admin Analytics
 */
export const getAdminAnalytics = async (req, res, next) => {
  try {
    const { futsalId } = req.query; // ✅ Add this line
    
    // Build where clause for futsal filtering
    const futsalFilter = futsalId ? { id: parseInt(futsalId) } : {};
    
    // Last 7 days revenue (with futsal filter)
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    const weeklyRevenue = [];
    for (let i = 6; i >= 0; i--) {
      const date = new Date(today);
      date.setDate(date.getDate() - i);
      const nextDate = new Date(date);
      nextDate.setDate(nextDate.getDate() + 1);
      
      // Add futsal filter to revenue query
      const revenue = await prisma.booking.aggregate({
        where: {
          slot: { 
            date: { gte: date, lt: nextDate },
            court: futsalId ? { futsalId: parseInt(futsalId) } : {}
          },
          status: { in: ['CONFIRMED', 'COMPLETED'] },
        },
        _sum: { totalPrice: true },
      });
      weeklyRevenue.push(revenue._sum.totalPrice || 0);
    }
    
    // Bookings by status (with futsal filter)
    const bookingsByStatus = await prisma.booking.groupBy({
      by: ['status'],
      where: {
        slot: futsalId ? {
          court: { futsalId: parseInt(futsalId) }
        } : {}
      },
      _count: { status: true },
    });
    
    // Top futsals (only if no specific futsal selected)
    let topFutsals = [];
    if (!futsalId) {
      const topFutsalsData = await prisma.booking.groupBy({
        by: ['slotId'],
        _count: { id: true },
        orderBy: { _count: { id: 'desc' } },
        take: 5,
      });
      
      topFutsals = await Promise.all(
        topFutsalsData.map(async (item) => {
          const slot = await prisma.timeSlot.findUnique({
            where: { id: item.slotId },
            include: {
              court: {
                include: { futsal: { select: { id: true, name: true } } }
              }
            }
          });
          return {
            futsalId: slot?.court?.futsal?.id,
            futsalName: slot?.court?.futsal?.name || 'Unknown',
            bookings: item._count.id,
          };
        })
      );
    }
    
    // Total stats (with futsal filter)
    const totalBookings = await prisma.booking.count({
      where: {
        slot: futsalId ? {
          court: { futsalId: parseInt(futsalId) }
        } : {}
      },
    });
    
    const totalRevenue = await prisma.booking.aggregate({
      _sum: { totalPrice: true },
      where: {
        status: { in: ['CONFIRMED', 'COMPLETED'] },
        slot: futsalId ? {
          court: { futsalId: parseInt(futsalId) }
        } : {}
      },
    });
    
    const activeUsers = await prisma.user.count({
      where: { isActive: true },
    });
    
    res.json({
      status: 'success',
      weeklyRevenue,
      bookingsByStatus,
      topFutsals,
      totalBookings,
      totalRevenue: totalRevenue._sum.totalPrice || 0,
      activeUsers,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get Admin Profile
 */
export const getAdminProfile = async (req, res, next) => {
  try {
    const adminId = req.user.id;

    const admin = await prisma.user.findUnique({
      where: { id: adminId },
      select: {
        id: true,
        fullName: true,
        email: true,
        phoneNumber: true,
        role: true,
        createdAt: true,
        // Remove profileImage
      },
    });

    if (!admin) {
      return res.status(404).json({
        status: 'error',
        message: 'Admin not found',
      });
    }

    res.json({
      status: 'success',
      data: admin,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Update Admin Profile
 */
export const updateAdminProfile = async (req, res, next) => {
  try {
    const adminId = req.user.id;
    const { fullName, phoneNumber } = req.body;

    // Update only provided fields
    const updateData = {};
    if (fullName !== undefined) updateData.fullName = fullName;
    if (phoneNumber !== undefined) updateData.phoneNumber = phoneNumber;

    const updatedAdmin = await prisma.user.update({
      where: { id: adminId },
      data: updateData,
      select: {
        id: true,
        fullName: true,
        email: true,
        phoneNumber: true,
        role: true,
        createdAt: true,
      },
    });

    res.json({
      status: 'success',
      message: 'Profile updated successfully',
      data: updatedAdmin,
    });
  } catch (error) {
    console.error('❌ Update Profile Error:', error);
    next(error);
  }
};

// ============================================
// REVENUE ANALYTICS ENDPOINTS
// ============================================

/**
 * Get revenue overview (platform earnings)
 * @route   GET /api/admin/revenue/overview
 */
export const getRevenueOverview = async (req, res) => {
  try {
    const { period = "month", from, to } = req.query;
    
    let startDate, endDate;
    const now = new Date();
    
    // Set date range based on period
    if (from && to) {
      startDate = new Date(from);
      endDate = new Date(to);
    } else {
      switch (period) {
        case "today":
          startDate = new Date(now);
          startDate.setHours(0, 0, 0, 0);
          endDate = new Date(now);
          endDate.setHours(23, 59, 59, 999);
          break;
        case "week":
          startDate = new Date(now);
          startDate.setDate(now.getDate() - 7);
          endDate = now;
          break;
        case "month":
          startDate = new Date(now.getFullYear(), now.getMonth(), 1);
          endDate = now;
          break;
        case "year":
          startDate = new Date(now.getFullYear(), 0, 1);
          endDate = now;
          break;
        default:
          startDate = new Date(now);
          startDate.setDate(now.getDate() - 30);
          endDate = now;
      }
    }

    // ✅ Get booking revenue (total amount from completed bookings)
    const bookingRevenue = await prisma.booking.aggregate({
      where: {
        bookingDate: { gte: startDate, lte: endDate },
        status: { in: ["CONFIRMED", "COMPLETED"] },
      },
      _sum: { totalPrice: true },
    });

    // ✅ Get registration fee revenue
    const registrationRevenue = await prisma.platformRevenue.aggregate({
      where: {
        createdAt: { gte: startDate, lte: endDate },
        type: "REGISTRATION",
      },
      _sum: { amount: true },
    });

    // ✅ Get platform commission revenue (admin's cut)
    const commissionRevenue = await prisma.transaction.aggregate({
      where: {
        createdAt: { gte: startDate, lte: endDate },
        status: "COMPLETED",
      },
      _sum: { commission: true },
    });

    // Get total bookings count
    const totalBookings = await prisma.booking.count({
      where: {
        bookingDate: { gte: startDate, lte: endDate },
        status: { in: ["CONFIRMED", "COMPLETED"] },
      },
    });

    // Get pending commission
    const pendingCommission = await prisma.transaction.aggregate({
      where: {
        createdAt: { gte: startDate, lte: endDate },
        status: "PENDING",
      },
      _sum: { commission: true },
    });

    // Get average booking value
    const avgBookingValue = totalBookings > 0 
      ? (bookingRevenue._sum.totalPrice || 0) / totalBookings 
      : 0;

    // ✅ Total revenue = booking revenue + registration fees
    const totalRevenue = (bookingRevenue._sum.totalPrice || 0) + (registrationRevenue._sum.amount || 0);

    console.log(`📊 Revenue Overview - Period: ${period}`);
    console.log(`   Booking Revenue: ${bookingRevenue._sum.totalPrice || 0}`);
    console.log(`   Registration Revenue: ${registrationRevenue._sum.amount || 0}`);
    console.log(`   Total Revenue: ${totalRevenue}`);
    console.log(`   Commission Revenue: ${commissionRevenue._sum.commission || 0}`);

    res.json({
      status: "success",
      data: {
        totalRevenue,
        bookingRevenue: bookingRevenue._sum.totalPrice || 0,
        registrationRevenue: registrationRevenue._sum.amount || 0,
        commissionRevenue: commissionRevenue._sum.commission || 0,
        totalBookings,
        pendingCommission: pendingCommission._sum.commission || 0,
        avgBookingValue,
        period: { startDate, endDate },
      },
    });
  } catch (error) {
    console.error("Get revenue overview error:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
};

/**
 * Get commission breakdown by futsal
 * @route   GET /api/admin/revenue/commission-breakdown
 */
export const getCommissionBreakdown = async (req, res) => {
  try {
    const { futsalId, from, to } = req.query;
    
    const startDate = from ? new Date(from) : new Date(new Date().setDate(new Date().getDate() - 30));
    const endDate = to ? new Date(to) : new Date();
    
    const whereCondition = {
      createdAt: { gte: startDate, lte: endDate },
      status: "COMPLETED",
    };
    
    if (futsalId) {
      whereCondition.futsalId = parseInt(futsalId);
    }
    
    // Get transactions grouped by futsal
    const transactions = await prisma.transaction.groupBy({
      by: ['futsalId'],
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
        _sum: { commission: 'desc' },
      },
    });
    
    // Get futsal names
    const breakdown = await Promise.all(
      transactions.map(async (item) => {
        const futsal = await prisma.futsal.findUnique({
          where: { id: item.futsalId },
          select: { name: true, owner: { select: { fullName: true } } },
        });
        
        return {
          futsalId: item.futsalId,
          futsalName: futsal?.name || 'Unknown',
          ownerName: futsal?.owner?.fullName || 'Unknown',
          totalBookings: item._count.id,
          totalAmount: item._sum.amount || 0,
          totalCommission: item._sum.commission || 0,
          totalOwnerEarning: item._sum.ownerEarning || 0,
        };
      })
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
          totalOwnerEarning: totals._sum.ownerEarning || 0,
        },
      },
    });
  } catch (error) {
    console.error("Get commission breakdown error:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
};

/**
 * Get revenue trends (daily/weekly/monthly)
 * @route   GET /api/admin/revenue/trends
 */
export const getRevenueTrends = async (req, res) => {
  try {
    const { interval = "daily", days = 30 } = req.query;
    const numDays = parseInt(days);
    
    const endDate = new Date();
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - numDays);
    
    const results = [];
    let currentDate = new Date(startDate);
    
    if (interval === "daily") {
      while (currentDate <= endDate) {
        const dayStart = new Date(currentDate);
        dayStart.setHours(0, 0, 0, 0);
        const dayEnd = new Date(currentDate);
        dayEnd.setHours(23, 59, 59, 999);
        
        const revenue = await prisma.transaction.aggregate({
          where: {
            createdAt: { gte: dayStart, lte: dayEnd },
            status: "COMPLETED",
          },
          _sum: { commission: true },
          _count: { id: true },
        });
        
        results.push({
          date: currentDate.toISOString().split('T')[0],
          label: currentDate.toLocaleDateString('en-US', { month: 'short', day: 'numeric' }),
          revenue: revenue._sum.commission || 0,
          bookings: revenue._count.id || 0,
        });
        
        currentDate.setDate(currentDate.getDate() + 1);
      }
    } else if (interval === "weekly") {
      while (currentDate <= endDate) {
        const weekStart = new Date(currentDate);
        const weekEnd = new Date(currentDate);
        weekEnd.setDate(weekEnd.getDate() + 6);
        
        const revenue = await prisma.transaction.aggregate({
          where: {
            createdAt: { gte: weekStart, lte: weekEnd },
            status: "COMPLETED",
          },
          _sum: { commission: true },
          _count: { id: true },
        });
        
        results.push({
          week: `Week ${Math.ceil(currentDate.getDate() / 7)}`,
          label: `${weekStart.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })} - ${weekEnd.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}`,
          revenue: revenue._sum.commission || 0,
          bookings: revenue._count.id || 0,
        });
        
        currentDate.setDate(currentDate.getDate() + 7);
      }
    }
    
    res.json({
      status: "success",
      data: results,
    });
  } catch (error) {
    console.error("Get revenue trends error:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
};

/**
 * Get pending payout requests
 * @route   GET /api/admin/revenue/payouts
 */
export const getPayoutRequests = async (req, res) => {
  try {
    const { status = "PENDING" } = req.query;
    
    const payouts = await prisma.payout.findMany({
      where: { status },
      include: {
        owner: {
          select: {
            id: true,
            fullName: true,
            email: true,
            phoneNumber: true,
          },
        },
        transactions: true,
      },
      orderBy: { requestDate: "desc" },
    });
    
    res.json({
      status: "success",
      data: payouts,
    });
  } catch (error) {
    console.error("Get payout requests error:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
};

/**
 * Process payout (mark as completed)
 * @route   POST /api/admin/revenue/payouts/:id/process
 */
export const processPayout = async (req, res) => {
  try {
    const { id } = req.params;
    const { notes } = req.body;
    
    const payout = await prisma.payout.findUnique({
      where: { id: parseInt(id) },
      include: { transactions: true },
    });
    
    if (!payout) {
      return res.status(404).json({ status: "error", message: "Payout not found" });
    }
    
    // Update payout status
    const updatedPayout = await prisma.payout.update({
      where: { id: parseInt(id) },
      data: {
        status: "COMPLETED",
        processedAt: new Date(),
        notes: notes || null,
      },
    });
    
    // Update all associated transactions to mark owner as paid
    await prisma.transaction.updateMany({
      where: { payoutId: payout.id },
      data: { status: "COMPLETED" },
    });
    
    // Update bookings to mark owner as paid
    for (const transaction of payout.transactions) {
      await prisma.booking.updateMany({
        where: { id: transaction.bookingId },
        data: { ownerPaid: true },
      });
    }
    
    res.json({
      status: "success",
      message: "Payout processed successfully",
      data: updatedPayout,
    });
  } catch (error) {
    console.error("Process payout error:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
};

/**
 * Update commission rate
 * @route   PUT /api/admin/revenue/commission-rate
 */
export const updateCommissionRate = async (req, res) => {
  try {
    const { rate } = req.body;
    
    if (!rate || rate < 0 || rate > 100) {
      return res.status(400).json({
        status: "error",
        message: "Commission rate must be between 0 and 100",
      });
    }
    
    // Update system settings
    const settings = await prisma.systemSettings.findFirst();
    
    if (settings) {
      await prisma.systemSettings.update({
        where: { id: settings.id },
        data: { commissionRate: rate },
      });
    } else {
      await prisma.systemSettings.create({
        data: { commissionRate: rate },
      });
    }
    
    res.json({
      status: "success",
      message: `Commission rate updated to ${rate}%`,
      data: { rate },
    });
  } catch (error) {
    console.error("Update commission rate error:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
};

/**
 * Get commission rate
 * @route   GET /api/admin/revenue/commission-rate
 */
export const getCommissionRate = async (req, res) => {
  try {
    const settings = await prisma.systemSettings.findFirst();
    const rate = settings?.commissionRate || 5.0;
    
    res.json({
      status: "success",
      data: { rate },
    });
  } catch (error) {
    console.error("Get commission rate error:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
};


/**
 * Fix missing transactions for completed bookings
 * @route   POST /api/admin/fix-transactions
 */
export const fixMissingTransactions = async (req, res) => {
  try {
    // Get all completed bookings without transactions
    const completedBookings = await prisma.booking.findMany({
      where: {
        status: "COMPLETED",
        transaction: null  // No transaction linked
      },
      include: {
        slot: {
          include: {
            court: {
              include: {
                futsal: true
              }
            }
          }
        }
      }
    });
    
    console.log(`Found ${completedBookings.length} completed bookings without transactions`);
    
    let created = 0;
    const commissionRate = 5; // 5%
    
    for (const booking of completedBookings) {
      const futsal = booking.slot.court.futsal;
      const commission = (booking.totalPrice * commissionRate) / 100;
      const ownerEarning = booking.totalPrice - commission;
      
      await prisma.transaction.create({
        data: {
          bookingId: booking.id,
          futsalId: futsal.id,
          ownerId: futsal.ownerId,
          amount: booking.totalPrice,
          commission: commission,
          ownerEarning: ownerEarning,
          status: "COMPLETED",
          type: "BOOKING",
          createdAt: booking.bookingDate
        }
      });
      created++;
    }
    
    res.json({
      status: "success",
      message: `Created ${created} transactions for completed bookings`,
      created
    });
  } catch (error) {
    console.error("Fix transactions error:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
};
