const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
prisma.$connect().then(() => {
  return prisma.user.findUnique({ where: { email: 'newuser@example.com' } });
}).then(user => {
  console.log('User found:', user ? 'YES' : 'NO');
  if (user) {
    console.log('isEmailVerified:', user.isEmailVerified);
    console.log('has otp:', !!user.otp);
    console.log('fullName:', user.fullName);
  }
}).catch(e => console.error(e)).finally(() => prisma.$disconnect());