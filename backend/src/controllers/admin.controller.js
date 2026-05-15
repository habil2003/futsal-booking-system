import { prisma } from "../index.js";

export const getDashboardStats = async (req, res) => {
  try {
    const [
      totalUsers,
      totalFutsals,
      totalOwners,
      totalPlayers,
      totalRevenue,
      totalBookings,
      pendingApprovals,
      todayBookings,
    ] = await Promise.all([
      prisma.user.count(),
      prisma.futsal.count({ where: { status: 'ACTIVE' } }),
      prisma.user.count({ where: { role: 'OWNER' } }),
      prisma.user.count({ where: { role: 'PLAYER' } }),
      prisma.booking.aggregate({
        where: { status: 'COMPLETED' },
        _sum: { totalPrice: true },
      }),
      prisma.booking.count(),
      prisma.futsal.count({ where: { status: 'PENDING' } }),
      prisma.booking.count({
        where: {
          bookingDate: {
            gte: new Date(new Date().setHours(0, 0, 0, 0)),
            lte: new Date(new Date().setHours(23, 59, 59, 999)),
          },
          status: { in: ['PENDING', 'CONFIRMED', 'COMPLETED'] },
        },
      }),
    ]);

    // -------------------------------------------------------
    // Fetch recent activities with user details
    // -------------------------------------------------------
    const recentActivities = await prisma.activityLog.findMany({
      orderBy: { createdAt: 'desc' },
      take: 10,
      include: {
        user: { select: { fullName: true, email: true, phoneNumber: true } },
      },
    });

    // Format activities for the frontend
    const formattedActivities = recentActivities.map((a) => ({
      id: a.id,
      type: a.type,
      description: a.description,
      name: a.metadata?.name || a.user?.fullName || 'System',
      email: a.metadata?.email || a.user?.email || '',
      phone: a.metadata?.phone || a.user?.phoneNumber || '',
      category: a.category || a.type,
      status: a.status || 'completed',
      createdAt: a.createdAt.toISOString(),
    }));

    res.json({
      status: 'success',
      data: {
        totalUsers,
        totalFutsals,
        totalOwners,
        totalPlayers,
        totalRevenue: totalRevenue._sum.totalPrice || 0,
        totalBookings,
        pendingApprovals,
        todayBookings,
        recentActivities: formattedActivities,   // <-- added
      },
    });
  } catch (error) {
    console.error('Dashboard stats error:', error);
    res.status(500).json({ status: 'error', message: error.message });
  }
};

// ============================================
// USER MANAGEMENT
// ============================================

/**
 * Get All Users (Admin only)
 */
export const getUsers = async (req, res, next) => {
  try {
    const users = await prisma.user.findMany({
      orderBy: { createdAt: "desc" },
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
      data: { isApproved: true },
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
 * Toggle User Active Status (Block/Unblock)
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

// ============================================
// FUTSAL MANAGEMENT
// ============================================

/**
 * Get Pending Futsals (awaiting approval)
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
 * Approve Futsal (set status to ACTIVE)
 */
export const approveFutsal = async (req, res, next) => {
  try {
    const futsalId = parseInt(req.params.id);

    const futsal = await prisma.futsal.update({
      where: { id: futsalId },
      data: {
        isApproved: true,
        status: 'ACTIVE',
      },
    });

    res.json({
      status: "success",
      message: "Futsal approved successfully",
      data: futsal,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Reject Futsal (delete record)
 */
export const rejectFutsal = async (req, res, next) => {
  try {
    const futsalId = Number(req.params.id);

    if (isNaN(futsalId)) {
      return res.status(400).json({
        status: 'error',
        message: 'Invalid futsal ID',
      });
    }

    const futsal = await prisma.futsal.update({
      where: {
        id: futsalId,
      },

      data: {
        status: 'REJECTED',
        isApproved: false,
      },
    });

    res.json({
      status: 'success',
      message: 'Futsal rejected successfully',
      data: futsal,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get All Futsals (for admin management)
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
        _count: { select: { courts: true } },
      },
      orderBy: { createdAt: "desc" },
    });

    const futsalsWithCount = futsals.map(futsal => ({
      ...futsal,
      courtCount: futsal._count?.courts || 0,
    }));

    res.json({ status: "success", data: futsalsWithCount });
  } catch (error) {
    next(error);
  }
};

// ============================================
// BOOKINGS
// ============================================

/**
 * Get All Bookings (with filtering and pagination)
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

// ============================================
// REPORTS
// ============================================

/**
 * Generate Report (bookings or revenue) by date range
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

// ============================================
// ADMIN ANALYTICS (LEGACY)
// ============================================

/**
 * Get Admin Analytics (weekly revenue, status breakdown, top futsals)
 * Used by the older analytics screen.
 */
export const getAdminAnalytics = async (req, res, next) => {
  try {
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
          slot: { date: { gte: date, lt: nextDate } },
          status: { in: ['CONFIRMED', 'COMPLETED'] },
        },
        _sum: { totalPrice: true },
      });

      weeklyRevenue.push(revenue._sum.totalPrice || 0);
    }

    const bookingsByStatus = await prisma.booking.groupBy({
      by: ['status'],
      _count: { status: true },
    });

    const topFutsalsData = await prisma.booking.groupBy({
      by: ['slotId'],
      _count: { id: true },
      orderBy: { _count: { id: 'desc' } },
      take: 5,
    });

    const topFutsals = await Promise.all(
      topFutsalsData.map(async (item) => {
        const slot = await prisma.timeSlot.findUnique({
          where: { id: item.slotId },
          include: {
            court: {
              include: { futsal: { select: { name: true } } }
            }
          }
        });
        return {
          futsalName: slot?.court?.futsal?.name || 'Unknown',
          bookings: item._count.id,
        };
      })
    );

    const totalBookings = await prisma.booking.count();
    const totalRevenue = await prisma.booking.aggregate({
      _sum: { totalPrice: true },
      where: { status: { in: ['CONFIRMED', 'COMPLETED'] } },
    });
    const activeUsers = await prisma.user.count({ where: { isActive: true } });

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

// ============================================
// ADMIN PROFILE
// ============================================

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
      },
    });

    if (!admin) {
      return res.status(404).json({ status: 'error', message: 'Admin not found' });
    }

    res.json({ status: 'success', data: admin });
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