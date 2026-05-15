import { prisma } from '../index.js';

// ============================================
// HELPER FUNCTIONS (YOURS + GAURAV'S)
// ============================================

const getDaysForRange = (range) => {
  switch (range) {
    case 'week': return 7;
    case 'month': return 30;
    case 'year': return 365;
    case 'all': return 365 * 5;
    default: return 7;
  }
};

const formatDate = (date) => date.toISOString().slice(0, 10);

// Your helper - for owner analytics
const generateResultForRange = (range, startDate, data, type) => {
  const result = [];
  const now = new Date();
  const days = Math.ceil((now - startDate) / (1000 * 60 * 60 * 24));

  const dataMap = new Map();
  data.forEach(item => {
    const dateStr = item.bookingDate.toISOString().split('T')[0];
    const value = type === 'revenue' ? item._sum.totalPrice : item._count.id;
    if (dataMap.has(dateStr)) {
      dataMap.set(dateStr, dataMap.get(dateStr) + value);
    } else {
      dataMap.set(dateStr, value);
    }
  });

  for (let i = 0; i < days; i++) {
    const date = new Date(startDate);
    date.setDate(startDate.getDate() + i);
    const dateStr = date.toISOString().split('T')[0];
    const value = dataMap.get(dateStr) || 0;
    result.push({ [type]: value });
  }
  return result;
};

// Gaurav's helper - for admin analytics
const generateEmptyRange = (range, startDate) => {
  const result = [];
  if (range === "day") {
    for (let i = 0; i < 24; i++) result.push({ label: `${i}:00`, value: 0 });
  } else if (range === "week" || range === "month") {
    const days = getDaysForRange(range);
    for (let i = 0; i <= days; i++) {
      const date = new Date(startDate);
      date.setDate(date.getDate() + i);
      result.push({ label: formatDate(date), value: 0 });
    }
  } else {
    const months = range === "year" ? 12 : 60;
    for (let i = 0; i < months; i++) {
      const date = new Date(startDate);
      date.setMonth(date.getMonth() + i);
      result.push({ label: `${date.getFullYear()}-${String(date.getMonth()+1).padStart(2,"0")}`, value: 0 });
    }
  }
  return result;
};

// ============================================
// OWNER ANALYTICS ENDPOINTS (YOUR CODE)
// ============================================

export const getRevenueOverTime = async (req, res) => {
  try {
    const { range = 'week' } = req.query;
    const days = getDaysForRange(range);
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);
    startDate.setHours(0, 0, 0, 0);

    const bookings = await prisma.booking.findMany({
      where: {
        bookingDate: { gte: startDate },
        status: 'COMPLETED',
      },
      select: {
        bookingDate: true,
        totalPrice: true,
      },
    });

    const revenueMap = new Map();
    bookings.forEach(booking => {
      const dateStr = booking.bookingDate.toISOString().split('T')[0];
      const currentSum = revenueMap.get(dateStr) || 0;
      revenueMap.set(dateStr, currentSum + booking.totalPrice);
    });

    const result = [];
    const now = new Date();
    const totalDays = Math.ceil((now - startDate) / (1000 * 60 * 60 * 24));
    
    for (let i = 0; i < totalDays; i++) {
      const date = new Date(startDate);
      date.setDate(startDate.getDate() + i);
      const dateStr = date.toISOString().split('T')[0];
      const revenue = revenueMap.get(dateStr) || 0;
      result.push({ revenue });
    }

    res.json({ status: 'success', data: result });
  } catch (error) {
    console.error('Revenue over time error:', error);
    res.status(500).json({ status: 'error', message: error.message });
  }
};

export const getBookingsOverTime = async (req, res) => {
  try {
    const { range = 'week' } = req.query;
    const days = getDaysForRange(range);
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);
    startDate.setHours(0, 0, 0, 0);

    const bookings = await prisma.booking.findMany({
      where: {
        bookingDate: { gte: startDate },
      },
      select: {
        bookingDate: true,
      },
    });

    const countMap = new Map();
    bookings.forEach(booking => {
      const dateStr = booking.bookingDate.toISOString().split('T')[0];
      const currentCount = countMap.get(dateStr) || 0;
      countMap.set(dateStr, currentCount + 1);
    });

    const result = [];
    const now = new Date();
    const totalDays = Math.ceil((now - startDate) / (1000 * 60 * 60 * 24));
    
    for (let i = 0; i < totalDays; i++) {
      const date = new Date(startDate);
      date.setDate(startDate.getDate() + i);
      const dateStr = date.toISOString().split('T')[0];
      const count = countMap.get(dateStr) || 0;
      result.push({ count });
    }

    res.json({ status: 'success', data: result });
  } catch (error) {
    console.error('Bookings over time error:', error);
    res.status(500).json({ status: 'error', message: error.message });
  }
};

export const getBookingStatusBreakdown = async (req, res) => {
  try {
    const statuses = await prisma.booking.groupBy({
      by: ['status'],
      _count: { status: true },
    });

    const result = {
      CONFIRMED: 0,
      COMPLETED: 0,
      CANCELLED: 0,
      PENDING: 0,
    };

    statuses.forEach(s => {
      result[s.status] = s._count.status;
    });

    res.json({ status: 'success', data: result });
  } catch (error) {
    console.error('Booking status breakdown error:', error);
    res.status(500).json({ status: 'error', message: error.message });
  }
};

// ============================================
// GAURAV'S ADMIN ANALYTICS ENDPOINTS
// ============================================

export const getGroundsByBookingCount = async (req, res) => {
  try {
    const data = await prisma.$queryRaw`
      SELECT f.id, f.name, COUNT(b.id)::int AS "bookingCount"
      FROM "Futsal" f
      LEFT JOIN "Court" c ON c."futsalId" = f.id
      LEFT JOIN "TimeSlot" ts ON ts."courtId" = c.id
      LEFT JOIN "Booking" b ON b."slotId" = ts.id AND b."status" = 'COMPLETED'
      GROUP BY f.id ORDER BY "bookingCount" DESC
    `;
    res.json({ status: "success", data });
  } catch (error) {
    console.error("Ground booking rank error:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
};

export const getGroundsByRevenue = async (req, res) => {
  try {
    const data = await prisma.$queryRaw`
      SELECT f.id, f.name, COALESCE(SUM(b."totalPrice"),0)::float AS revenue
      FROM "Futsal" f
      LEFT JOIN "Court" c ON c."futsalId" = f.id
      LEFT JOIN "TimeSlot" ts ON ts."courtId" = c.id
      LEFT JOIN "Booking" b ON b."slotId" = ts.id AND b."status" = 'COMPLETED'
      GROUP BY f.id ORDER BY revenue DESC
    `;
    res.json({ status: "success", data });
  } catch (error) {
    console.error("Ground revenue rank error:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
};

export const getTopUsersByBookings = async (req, res) => {
  try {
    const limit = Number(req.query.limit) || 10;
    const users = await prisma.$queryRaw`
      SELECT u.id, u."fullName" AS name, COUNT(b.id)::int AS "bookingCount"
      FROM "User" u
      LEFT JOIN "Booking" b ON b."userId" = u.id AND b."status" = 'COMPLETED'
      WHERE u.role = 'PLAYER'
      GROUP BY u.id ORDER BY "bookingCount" DESC LIMIT ${limit}
    `;
    res.json({ status: "success", data: users });
  } catch (error) {
    console.error("Top players error:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
};

export const getPeakHours = async (req, res) => {
  try {
    const peakHours = await prisma.$queryRaw`
      SELECT 
        CAST(SPLIT_PART(ts."startTime", ':', 1) AS INTEGER) AS hour,
        COUNT(b.id)::int AS count
      FROM "Booking" b
      JOIN "TimeSlot" ts ON b."slotId" = ts.id
      WHERE b."status" = 'COMPLETED'
      GROUP BY hour
      ORDER BY hour ASC
    `;
    res.json({ status: 'success', data: peakHours });
  } catch (error) {
    console.error('Peak Hours Error:', error);
    res.status(500).json({ status: 'error', message: error.message });
  }
};

export const getTournamentRanking = async (req, res) => {
  try {
    const tournaments = await prisma.tournament.findMany({
      include: { teams: true },
    });
    const ranked = tournaments.map(t => ({
      id: t.id,
      name: t.name,
      teamCount: t.teams.length,
      estimatedRevenue: (t.entryFee || 0) * t.teams.length,
    })).sort((a,b) => b.teamCount - a.teamCount);
    res.json({ status: "success", data: ranked });
  } catch (error) {
    console.error("Tournament ranking error:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
};

export const getAdminAnalytics = async (req, res) => {
  try {
    const totalBookings = await prisma.booking.count();
    const totalRevenue = await prisma.booking.aggregate({
      where: { status: { in: ["CONFIRMED","COMPLETED"] } },
      _sum: { totalPrice: true },
    });
    const activeUsers = await prisma.user.count({ where: { isActive: true } });
    res.json({
      status: "success",
      totalBookings,
      totalRevenue: totalRevenue._sum?.totalPrice || 0,
      activeUsers,
    });
  } catch (error) {
    console.error("Admin analytics error:", error);
    res.status(500).json({ status: "error", message: error.message });
  }
};

// ============================================
// LEGACY/COMPATIBILITY FUNCTIONS (for existing routes)
// ============================================

export const getBookingAnalytics = async (req, res) => {
  try {
    const totalBookings = await prisma.booking.count({
      where: { status: { in: ['PENDING', 'CONFIRMED', 'COMPLETED'] } },
    });
    res.json({
      status: 'success',
      data: {
        bookingsOverTime: [],
        peakHours: {},
        mostBookedDays: [],
        totalBookings,
      },
    });
  } catch (error) {
    console.error('Booking analytics error:', error);
    res.status(500).json({ status: 'error', message: error.message });
  }
};

export const getRevenueAnalytics = async (req, res) => {
  try {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    const completedBookings = await prisma.booking.findMany({
      where: {
        status: 'COMPLETED',
        bookingDate: { gte: thirtyDaysAgo },
      },
      select: { totalPrice: true },
    });
    const totalRevenue = completedBookings.reduce((sum, b) => sum + b.totalPrice, 0);
    res.json({
      status: 'success',
      data: {
        trends: [],
        revenuePerGround: [],
        paymentMethods: {},
        totalRevenue,
      },
    });
  } catch (error) {
    console.error('Revenue analytics error:', error);
    res.status(500).json({ status: 'error', message: error.message });
  }
};

export const getUserAnalytics = async (req, res) => {
  try {
    const activeUsers = await prisma.user.count({ where: { isActive: true } });
    const totalUsers = await prisma.user.count();
    res.json({
      status: 'success',
      data: {
        newUsers: 0,
        activeUsers,
        totalUsers,
        topPlayers: [],
      },
    });
  } catch (error) {
    res.status(500).json({ status: 'error', message: error.message });
  }
};

export const getGroundPerformance = async (req, res) => {
  try {
    res.json({
      status: 'success',
      data: {
        popular: [],
        leastUsed: [],
        occupancyRate: 0,
      },
    });
  } catch (error) {
    res.status(500).json({ status: 'error', message: error.message });
  }
};

export const getTimeSlotAnalytics = async (req, res) => {
  try {
    res.json({
      status: 'success',
      data: {
        peakSlots: [],
        leastUsedSlots: [],
      },
    });
  } catch (error) {
    res.status(500).json({ status: 'error', message: error.message });
  }
};

export const getTournamentAnalytics = async (req, res) => {
  try {
    res.json({
      status: 'success',
      data: {
        count: 0,
        participationRate: 0,
        revenue: 0,
      },
    });
  } catch (error) {
    res.status(500).json({ status: 'error', message: error.message });
  }
};