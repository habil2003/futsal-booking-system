import dotenv from 'dotenv';
import { PrismaClient } from '@prisma/client';

dotenv.config();
const prisma = new PrismaClient();

const startDate = new Date();
startDate.setDate(startDate.getDate() - 7);
startDate.setHours(0,0,0,0);

console.log('\n=== API DATE RANGE ===');
console.log('Start date:', startDate.toISOString().split('T')[0]);
console.log('Today:', new Date().toISOString().split('T')[0]);

const bookings = await prisma.booking.groupBy({
  by: ['bookingDate'],
  where: {
    bookingDate: { gte: startDate },
    status: 'COMPLETED',
  },
  _sum: { totalPrice: true },
  orderBy: { bookingDate: 'asc' },
});

console.log('\n=== COMPLETED BOOKINGS IN LAST 7 DAYS ===');
if (bookings.length === 0) {
  console.log('No completed bookings found in last 7 days');
} else {
  bookings.forEach(b => {
    console.log(b.bookingDate.toISOString().split('T')[0], '-> Revenue:', b._sum.totalPrice);
  });
}

await prisma.$disconnect();