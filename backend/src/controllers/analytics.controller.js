import { prisma } from '../index.js';

// Helper: get number of days for each range
const getDaysForRange = (range) => {
  switch (range) {
    case 'week': return 7;
    case 'month': return 30;
    case 'year': return 365;
    case 'all': return 365 * 5;
    default: return 7;
  }
};

// Helper: generate array of values (revenue or count) for the given range
const generateResultForRange = (range, startDate, data, type) => {
  const result = [];
  const now = new Date();

  if (range === 'day') {
    // Hourly breakdown (not used by frontend currently, but keep for completeness)
    for (let hour = 0; hour < 24; hour++) {
      const date = new Date(startDate);
      date.setHours(hour, 0, 0, 0);
      const found = data.find(b => {
        const bDate = new Date(b.bookingDate);
        return bDate.getHours() === hour && bDate.toDateString() === startDate.toDateString();
      });
      const value = found ? (type === 'revenue' ? found._sum.totalPrice : found._count.id) : 0;
      // Frontend expects a single-key object, no label
      result.push({ [type]: value });
    }
  } else if (range === 'week' || range === 'month') {
    // Daily breakdown
    const days = Math.ceil((now - startDate) / (1000 * 60 * 60 * 24));
    for (let i = 0; i < days; i++) {
      const date = new Date(startDate);
      date.setDate(date.getDate() + i);
      const dateStr = date.toISOString().split('T')[0];
      const found = data.find(b => b.bookingDate.toISOString().split('T')[0] === dateStr);
      const value = found ? (type === 'revenue' ? found._sum.totalPrice : found._count.id) : 0;
      result.push({ [type]: value });
    }
  } else {
    // Monthly breakdown for year/all
    const months = range === 'year' ? 12 : 60;
    for (let i = 0; i < months; i++) {
      const date = new Date(startDate);
      date.setMonth(date.getMonth() + i);
      const monthStart = new Date(date.getFullYear(), date.getMonth(), 1);
      const monthEnd = new Date(date.getFullYear(), date.getMonth() + 1, 0);
      const monthData = data.filter(b => {
        const bDate = new Date(b.bookingDate);
        return bDate >= monthStart && bDate <= monthEnd;
      });
      const value = monthData.reduce((sum, b) => sum + (type === 'revenue' ? b._sum.totalPrice : b._count.id), 0);
      result.push({ [type]: value });
    }
  }
  console.log(`Generated result for range ${range}:`, result);
  return result;
};

// ============================================
// REVENUE OVER TIME (with range query)
// ============================================
export const getRevenueOverTime = async (req, res) => {
  try {
    const { range = 'week' } = req.query;
    const days = getDaysForRange(range);
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);
    startDate.setHours(0, 0, 0, 0);

    const bookings = await prisma.booking.groupBy({
      by: ['bookingDate'],
      where: {
        bookingDate: { gte: startDate },
        status: 'COMPLETED',
      },
      _sum: { totalPrice: true },
      orderBy: { bookingDate: 'asc' },
    });

    const result = generateResultForRange(range, startDate, bookings, 'revenue');
    res.json({ status: 'success', data: result });
  } catch (error) {
    console.error('Revenue over time error:', error);
    res.status(500).json({ status: 'error', message: error.message });
  }
};

// ============================================
// BOOKINGS OVER TIME (with range query)
// ============================================
export const getBookingsOverTime = async (req, res) => {
  try {
    const { range = 'week' } = req.query;
    const days = getDaysForRange(range);
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);
    startDate.setHours(0, 0, 0, 0);

    const bookings = await prisma.booking.groupBy({
      by: ['bookingDate'],
      where: { bookingDate: { gte: startDate } },
      _count: { id: true },
      orderBy: { bookingDate: 'asc' },
    });

    const result = generateResultForRange(range, startDate, bookings, 'count');
    res.json({ status: 'success', data: result });
  } catch (error) {
    console.error('Bookings over time error:', error);
    res.status(500).json({ status: 'error', message: error.message });
  }
};

// ============================================
// BOOKING STATUS BREAKDOWN (for pie chart)
// ============================================
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
// DETAILED ANALYTICS (for the Analytics screen)
// ============================================
export const getBookingAnalytics = async (req, res) => {
  try {
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    sevenDaysAgo.setHours(0, 0, 0, 0);

    const bookings = await prisma.booking.groupBy({
      by: ['bookingDate'],
      where: {
        bookingDate: { gte: sevenDaysAgo },
        status: { in: ['PENDING', 'CONFIRMED', 'COMPLETED'] },
      },
      _count: { id: true },
      orderBy: { bookingDate: 'asc' },
    });

    const totalBookings = await prisma.booking.count({
      where: { status: { in: ['PENDING', 'CONFIRMED', 'COMPLETED'] } },
    });

    res.json({
      status: 'success',
      data: {
        bookingsOverTime: bookings.map(b => b._count.id),
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
      select: {
        totalPrice: true,
        bookingDate: true,
      },
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