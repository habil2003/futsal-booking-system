import bcrypt from "bcryptjs";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();
const PASSWORD = "habil1234";

// ------------------------------------------------------------------
// Helpers
// ------------------------------------------------------------------
const noonUTC = (daysFromToday = 0, hour = 12) => {
  const d = new Date();
  d.setUTCHours(0, 0, 0, 0);
  d.setUTCDate(d.getUTCDate() + daysFromToday);
  d.setUTCHours(hour, 0, 0, 0);
  return d;
};

const dayDiff = (slotDate, ref = new Date()) => {
  const refStart = new Date(Date.UTC(ref.getUTCFullYear(), ref.getUTCMonth(), ref.getUTCDate()));
  const slotStart = new Date(Date.UTC(slotDate.getUTCFullYear(), slotDate.getUTCMonth(), slotDate.getUTCDate()));
  return Math.round((refStart.getTime() - slotStart.getTime()) / 86400000); // +ve => past
};

const rand = (arr) => arr[Math.floor(Math.random() * arr.length)];
const pad2 = (n) => String(n).padStart(2, "0");
const npr = (n) => `Rs. ${n.toLocaleString("en-IN")}`;

// ------------------------------------------------------------------
// USERS
// ------------------------------------------------------------------
const PLAYERS = [
  ["Aarya Pokharel", "aarya.pokharel@gmail.com", "9841000001"],
  ["Bibek Thapa", "bibek.thapa@gmail.com", "9841000002"],
  ["Sandip Gurung", "sandip.gurung@gmail.com", "9841000003"],
  ["Nisha Ranabhat", "nisha.ranabhat@gmail.com", "9841000004"],
  ["Prabin Gharti", "prabin.gharti@gmail.com", "9841000005"],
  ["Rojina Poudel", "rojina.poudel@gmail.com", "9841000006"],
  ["Suraj K.C.", "suraj.kc@gmail.com", "9841000007"],
  ["Pooja Gurung", "pooja.gurung@gmail.com", "9841000008"],
  ["Anil Subedi", "anil.subedi@gmail.com", "9841000009"],
  ["Kritika Baral", "kritika.baral@gmail.com", "9841000010"],
  ["Dipesh Thapa", "dipesh.thapa@gmail.com", "9841000011"],
  ["Bikash Ghimire", "bikash.ghimire@gmail.com", "9841000012"],
  ["Sajina Rana", "sajina.rana@gmail.com", "9841000013"],
  ["Laxmi Adhikari", "laxmi.adhikari@gmail.com", "9841000014"],
  ["Nabin Magar", "nabin.magar@gmail.com", "9841000015"],
  ["Smarika Gautam", "smarika.gautam@gmail.com", "9841000016"],
  ["Ujjwal Tiwari", "ujjwal.tiwari@gmail.com", "9841000017"],
  ["Jenish K.C.", "jenish.kc@gmail.com", "9841000018"],
  ["Sabina Paudel", "sabina.paudel@gmail.com", "9841000019"],
  ["Roshan Gurung", "roshan.gurung@gmail.com", "9841000020"],
  ["Manish Pant", "manish.pant@gmail.com", "9841000021"],
  ["Dipika Rai", "dipika.rai@gmail.com", "9841000022"],
  ["Kushal Pun", "kushal.pun@gmail.com", "9841000023"],
  ["Anjali Chhetri", "anjali.chhetri@gmail.com", "9841000024"],
];

const OWNERS = [
  ["Ram Bahadur Thapa", "ram.thapa.owner@gmail.com", "9842000001", "Thapa Futsal Ventures", "123456789"],
  ["Sita Baral", "sita.baral.owner@gmail.com", "9842000002", "Baral Sports Group", "987654321"],
  ["Hari Bahadur Gurung", "hari.gurung.owner@gmail.com", "9842000003", "Gurung Futsal Corner", "456789123"],
  ["Anisha Karki", "anisha.karki.owner@gmail.com", "9842000004", "Karki Recreation", "789123456"],
  ["Prakash Pokharel", "prakash.pokharel.owner@gmail.com", "9842000005", "Pokharel Sports Hub", "321654987"],
  ["Sunita Rai", "sunita.rai.owner@gmail.com", "9842000006", "Rai Futsal Park", "654987321"],
  ["Milan Bhandari", "milan.bhandari.owner@gmail.com", "9842000007", "Bhandari Fitness & Futsal", "147258369"],
  ["Gita Sharma", "gita.sharma.owner@gmail.com", "9842000008", "Gita Sports Arena", "159357852"],
];

const ADMINS = [
  ["Super Admin", "super.admin@gmail.com", "9843000001"],
];

const OLD_SEED_EMAILS = [
  "aarya.shrestha@gmail.com", "bibek.maharjan@gmail.com", "sandip.gurung@gmail.com",
  "nisha.tamang@gmail.com", "prabin.lama@gmail.com", "rojina.poudel@gmail.com",
  "suraj.khadka@gmail.com", "pooja.rana@gmail.com", "anil.tamang@gmail.com",
  "kritika.shrestha@gmail.com", "dipesh.thapa@gmail.com", "bikash.shrestha@gmail.com",
  "sajina.bajracharya@gmail.com", "laxmi.ghimire@gmail.com", "nabin.magar@gmail.com",
  "smarika.dangol@gmail.com", "ujjwal.adhikari@gmail.com", "jenish.shakya@gmail.com",
  "sabina.karki@gmail.com", "roshan.shrestha@gmail.com", "manish.prajapati@gmail.com",
  "dipika.rai@gmail.com", "kushal.pun@gmail.com", "anjali.chhetri@gmail.com",
  "sita.sharma.owner@gmail.com", "prakash.shrestha.owner@gmail.com", "gita.shrestha.owner@gmail.com",
];

const hash = await bcrypt.hash(PASSWORD, 10);

// ------------------------------------------------------------------
// WIPE transactional tables (keep existing users)
// ------------------------------------------------------------------
await prisma.$transaction([
  prisma.match.deleteMany(),
  prisma.teamMember.deleteMany(),
  prisma.team.deleteMany(),
  prisma.tournament.deleteMany(),
  prisma.review.deleteMany(),
  prisma.payment.deleteMany(),
  prisma.booking.deleteMany(),
  prisma.favorite.deleteMany(),
  prisma.block.deleteMany(),
  prisma.timeSlot.deleteMany(),
  prisma.court.deleteMany(),
  prisma.futsal.deleteMany(),
  prisma.ad.deleteMany(),
  prisma.notification.deleteMany(),
  prisma.activityLog.deleteMany(),
  prisma.user.deleteMany({ where: { email: { in: OLD_SEED_EMAILS } } }),
]);

// Upsert users
const allUsers = [];
for (const [fullName, email, phoneNumber, ...extra] of [
  ...PLAYERS.map(([n, e, ph]) => [n, e, ph, "PLAYER"]),
  ...OWNERS.map(([n, e, ph, bName, pan]) => [n, e, ph, "OWNER", bName, pan]),
  ...ADMINS.map(([n, e, ph]) => [n, e, ph, "ADMIN"]),
]) {
  const data = {
    password: hash,
    fullName,
    phoneNumber,
    role: extra[0],
    isApproved: true,
    isActive: true,
    isEmailVerified: true,
    otp: null,
    otpExpiry: null,
    ...(extra[0] === "OWNER"
      ? {
          businessName: extra[1],
          panVatNumber: extra[2],
        }
      : {}),
  };
  const user = await prisma.user.upsert({
    where: { email },
    update: data,
    create: { email, ...data },
  });
  allUsers.push(user);
}

const players = allUsers.filter((u) => u.role === "PLAYER");
const owners = allUsers.filter((u) => u.role === "OWNER");
const admins = allUsers.filter((u) => u.role === "ADMIN");
console.log(`Seeded users: ${players.length} players, ${owners.length} owners, ${admins.length} admins`);

// ------------------------------------------------------------------
// FUTSALS
// ------------------------------------------------------------------
const operatingHours = {
  monday: { open: "06:00", close: "22:00" },
  tuesday: { open: "06:00", close: "22:00" },
  wednesday: { open: "06:00", close: "22:00" },
  thursday: { open: "06:00", close: "22:00" },
  friday: { open: "06:00", close: "22:00" },
  saturday: { open: "07:00", close: "23:00" },
  sunday: { open: "07:00", close: "23:00" },
};

const FUTSALS = [
  {
    name: "Sports Castle Futsal", ownerIdx: 3, status: "ACTIVE", lat: 28.2287, lng: 83.9853,
    address: "Ganesh Tole, Pokhara-4 33700", description:
      "Home of the 2021 'A' Division National Futsal League champions. Premier arena at Ganesh Tole (Siddhartha Chowk) with stadium-grade turf, floodlights and a buzzing atmosphere for competitive league nights.",
    courts: [
      { n: "A", type: "5-a-side", base: 2200, peak: 3000, am: ["Floodlights", "Changing Room", "Parking"] },
      { n: "B", type: "7-a-side", base: 3000, peak: 4200, am: ["Floodlights", "Shower", "Cafe", "Parking"] },
      { n: "VIP", type: "VIP", base: 4000, peak: 5500, am: ["Lounge", "Air Cooled", "Shower", "Courtside Seating", "Refreshments"] },
    ],
  },
  {
    name: "Pokhara Futsal Arena", ownerIdx: 0, status: "ACTIVE", lat: 28.213, lng: 83.963,
    address: "Gairapatan, Tersapatti Rd, Pokhara 33700", description:
      "Popular arena on the Gairapatan-Tersapatti road, open from 5 AM to 8 PM. Early-morning and evening slots, parking and refreshments. Contact 9814189544.",
    courts: [
      { n: "1", type: "5-a-side", base: 1500, peak: 2000, am: ["Floodlights", "Parking"] },
      { n: "2", type: "5-a-side", base: 1500, peak: 2000, am: ["Floodlights", "Water"] },
      { n: "3", type: "7-a-side", base: 2300, peak: 3200, am: ["Floodlights", "Changing Room", "Cafe"] },
    ],
  },
  {
    name: "B-Fit Futsal", ownerIdx: 6, status: "ACTIVE", lat: 28.2285, lng: 83.985,
    address: "Koirala Birta Marg, Ganesh Tole, Pokhara 33700", description:
      "Training-focused futsal centre on Koirala Birta Marg. Regularly hosts school tournaments such as the Gurukul Intra SEE cup and offers coaching for juniors.",
    courts: [
      { n: "1", type: "5-a-side", base: 1600, peak: 2200, am: ["Floodlights", "Changing Room"] },
      { n: "2", type: "Indoor", base: 2000, peak: 2800, am: ["Air Cooled", "Courtside Seating"] },
    ],
  },
  {
    name: "Pokhara Futsal", ownerIdx: 5, status: "ACTIVE", lat: 28.2284, lng: 83.9851,
    address: "Koirala Birta Marg, Ganesh Tole, Pokhara 33700", description:
      "Established neighbourhood futsal beside B-Fit with friendly rates and casual evening kickabouts. Booking line 061-522654.",
    courts: [
      { n: "1", type: "5-a-side", base: 1300, peak: 1800, am: ["Floodlights", "Parking"] },
      { n: "2", type: "5-a-side", base: 1300, peak: 1800, am: ["Floodlights", "Water"] },
    ],
  },
  {
    name: "DG O KM Futsal Centre", ownerIdx: 4, status: "ACTIVE", lat: 28.216, lng: 83.9775,
    address: "Pokhara 33700", description:
      "Community futsal centre in Pokhara known for pickup games and weekend mini-tournaments. Clean spring turf and competitive pricing.",
    courts: [
      { n: "1", type: "5-a-side", base: 1400, peak: 2000, am: ["Floodlights", "Parking"] },
      { n: "2", type: "7-a-side", base: 2200, peak: 3100, am: ["Floodlights", "Changing Room"] },
    ],
  },
  {
    name: "Kickoff Futsal Zone", ownerIdx: 5, status: "ACTIVE", lat: 28.2022, lng: 83.9935,
    address: "Naya Bazar, Pokhara 33700", description:
      "Compact, budget-friendly futsal zone in Naya Bazar. Ideal for casual kickabouts, college leagues and evening games with friends.",
    courts: [
      { n: "1", type: "5-a-side", base: 1400, peak: 2000, am: ["Floodlights", "Parking"] },
      { n: "2", type: "5-a-side", base: 1400, peak: 2000, am: ["Floodlights", "Water"] },
    ],
  },
  {
    name: "Himalayan Futsal Complex", ownerIdx: 6, status: "ACTIVE", lat: 28.2096, lng: 83.9856,
    address: "Srijana Chowk, Pokhara 33700", description:
      "Large futsal complex at Srijana Chowk with four courts, gym integration and a full-service restaurant. Hosts the annual Holiday Cup.",
    courts: [
      { n: "A", type: "5-a-side", base: 1800, peak: 2500, am: ["Floodlights", "Changing Room", "Parking"] },
      { n: "B", type: "7-a-side", base: 2700, peak: 3800, am: ["Floodlights", "Shower", "Cafe", "Parking"] },
      { n: "C", type: "Outdoor", base: 1500, peak: 2100, am: ["Floodlights", "Water"] },
      { n: "D", type: "Indoor", base: 2300, peak: 3200, am: ["Air Cooled", "Gym Access", "Refreshments"] },
    ],
  },
  {
    name: "Midtown Futsal Court", ownerIdx: 2, status: "ACTIVE", lat: 28.2079, lng: 83.9968,
    address: "Ranipauwa, Pokhara 33700", description:
      "Conveniently located futsal court at Ranipauwa. Regular all-women sessions on Sundays and junior academy training on Saturdays.",
    courts: [
      { n: "1", type: "5-a-side", base: 1600, peak: 2200, am: ["Floodlights", "Changing Room"] },
      { n: "2", type: "Indoor", base: 2000, peak: 2800, am: ["Air Cooled", "Courtside Seating"] },
      { n: "3", type: "7-a-side", base: 2400, peak: 3400, am: ["Floodlights", "Parking"] },
    ],
  },
  {
    name: "Sunshine Futsal Arena", ownerIdx: 7, status: "ACTIVE", lat: 28.2135, lng: 83.9828,
    address: "Ratna Chowk, Pokhara 33700", description:
      "Bright and friendly futsal arena near Ratna Chowk with a focus on family and youth football. Afternoon kids academy and corporate evening slots.",
    courts: [
      { n: "1", type: "5-a-side", base: 1700, peak: 2400, am: ["Floodlights", "Changing Room", "Parking"] },
      { n: "2", type: "7-a-side", base: 2500, peak: 3500, am: ["Floodlights", "Cafe", "Parking"] },
    ],
  },
  {
    name: "Phewa 5v5 Futsal", ownerIdx: 0, status: "ACTIVE", lat: 28.207, lng: 83.97,
    address: "Gagangauda, Pokhara 33700", description:
      "Fast-paced 5v5 specialist courts at Gagangauda with compact spring turf suited for quick passing games. Night sessions available till late.",
    courts: [
      { n: "1", type: "5-a-side", base: 1900, peak: 2700, am: ["Floodlights", "Changing Room"] },
      { n: "2", type: "5-a-side", base: 1900, peak: 2700, am: ["Floodlights", "Water"] },
      { n: "3", type: "7-a-side", base: 2800, peak: 3900, am: ["Floodlights", "Shower", "Parking"] },
    ],
  },
  {
    name: "Dhaulagiri Sports Futsal", ownerIdx: 4, status: "ACTIVE", lat: 28.2117, lng: 83.9773,
    address: "Prithivi Chowk, Pokhara 33700", description:
      "Pokhara's favourite futsal ground at Prithivi Chowk offering open-air turf courts and community-run weekend tournaments. Famous for its winter league.",
    courts: [
      { n: "1", type: "5-a-side", base: 1500, peak: 2100, am: ["Floodlights", "Parking"] },
      { n: "2", type: "7-a-side", base: 2300, peak: 3200, am: ["Floodlights", "Changing Room"] },
      { n: "3", type: "Outdoor", base: 1300, peak: 1900, am: ["Floodlights", "Water"] },
    ],
  },
  {
    name: "Gandaki Futsal Arena", ownerIdx: 6, status: "PENDING", lat: 28.2062, lng: 83.9782,
    address: "Kundahar, Pokhara 33700", description:
      "Brand new arena in Kundahar awaiting approval. Two spring courts, floodlighting and a modern cafe planned on site.",
    courts: [
      { n: "1", type: "5-a-side", base: 1800, peak: 2500, am: ["Floodlights"] },
      { n: "2", type: "7-a-side", base: 2600, peak: 3600, am: ["Floodlights", "Cafe"] },
    ],
  },
  {
    name: "New Bazaar Futsal Ground", ownerIdx: 7, status: "PENDING", lat: 28.1998, lng: 83.991,
    address: "New Bazaar, Naya Bazar, Pokhara 33700", description:
      "Newly constructed futsal ground at New Bazaar awaiting admin approval. Features an outdoor 7-a-side court and changing facilities.",
    courts: [
      { n: "1", type: "7-a-side", base: 2500, peak: 3500, am: ["Floodlights", "Changing Room"] },
    ],
  },
];

const SLOT_GEN_START = -15; // days back (for historical bookings)
const SLOT_GEN_END = 30; // days forward

const futsalRows = [];
for (let i = 0; i < FUTSALS.length; i++) {
  const def = FUTSALS[i];
  const approved = def.status === "ACTIVE";
  const futsal = await prisma.futsal.create({
    data: {
      name: def.name,
      description: def.description,
      address: def.address,
      latitude: def.lat,
      longitude: def.lng,
      images: [
        `https://picsum.photos/seed/futsal${i + 1}-a/800/600`,
        `https://picsum.photos/seed/futsal${i + 1}-b/800/600`,
        `https://picsum.photos/seed/futsal${i + 1}-c/800/600`,
      ],
      ownerId: owners[def.ownerIdx].id,
      isApproved: approved,
      status: def.status,
      operatingHours,
    },
  });
  futsalRows.push(futsal);

  for (const courtDef of def.courts) {
    const court = await prisma.court.create({
      data: {
        futsalId: futsal.id,
        courtNumber: courtDef.n,
        courtType: courtDef.type,
        basePrice: courtDef.base,
        peakPrice: courtDef.peak,
        amenities: courtDef.am,
        isActive: approved,
        isUnderMaintenance: false,
      },
    });

    // Generate slots (like the app: 08:00-22:00, peak 17-20 + weekends)
    const slots = [];
    for (let day = SLOT_GEN_START; day <= SLOT_GEN_END; day++) {
      const date = noonUTC(day);
      for (let hour = 8; hour < 22; hour++) {
        const startTime = `${pad2(hour)}:00`;
        const endTime = `${pad2(hour + 1)}:00`;
        const isPeakHour = hour >= 17 && hour <= 20;
        const isWeekend = date.getUTCDay() === 0 || date.getUTCDay() === 6;
        let price = courtDef.base;
        if (courtDef.peak && (isPeakHour || isWeekend)) price = courtDef.peak;
        slots.push({
          courtId: court.id,
          date,
          startTime,
          endTime,
          price: parseFloat(price),
          status: "AVAILABLE",
        });
      }
    }
    await prisma.timeSlot.createMany({ data: slots });
  }
}

const pendingFutsals = futsalRows.filter((f) => f.status !== "ACTIVE");
console.log(`Seeded ${futsalRows.length} futsals (${futsalRows.length - pendingFutsals.length} active, ${pendingFutsals.length} pending)`);

// ------------------------------------------------------------------
// SLOTS INDEX (active futsals only) for booking distribution
// ------------------------------------------------------------------
const activeFutsals = futsalRows.filter((f) => f.status === "ACTIVE");
const slotsIndex = {};
{
  const all = await prisma.timeSlot.findMany({
    where: { court: { futsal: { status: "ACTIVE" } } },
    include: { court: { select: { futsalId: true, courtNumber: true } } },
  });
  for (const s of all) {
    (slotsIndex[s.court.futsalId] = slotsIndex[s.court.futsalId] || []).push(s);
  }
}

// ------------------------------------------------------------------
// BOOKINGS + PAYMENTS
// ------------------------------------------------------------------
const bookingStatuses = ["CONFIRMED", "COMPLETED", "PENDING", "CANCELLED"];
const paymentMethods = ["COD", "COD", "Khalti", "Khalti"];
const reviewComments = [
  "Great turf and floodlighting. Highly recommended!",
  "Courts were clean and the staff were very helpful.",
  "Solid experience. Booking was smooth and easy.",
  "Nice place for casual games with friends.",
  "Good facilities but peak hours can get crowded.",
  "Loved the changing rooms and the cafe nearby.",
  "Referees were professional for our tournament game.",
  "Decent turf, fair pricing for the area.",
  "Our regular spot for weekend matches.",
  "Excellent maintenance and friendly owner.",
];
const reviewRatings = [5, 5, 4, 4, 4, 5, 4, 3, 5, 4];

let bookingsCreated = 0;
const completedBookings = [];

for (const futsal of activeFutsals) {
  const courtSlots = slotsIndex[futsal.id];
  if (!courtSlots || courtSlots.length === 0) continue;

  const candidates = courtSlots.filter((s) => s.status === "AVAILABLE");
  const used = new Set();
  const pick = (predicate = () => true) => {
    const pool = candidates.filter((s) => !used.has(s.id) && predicate(s));
    if (pool.length === 0) return null;
    const chosen = pool[Math.floor(Math.random() * pool.length)];
    used.add(chosen.id);
    return chosen;
  };

  // 3 completed (past evenings)
  for (let k = 0; k < 3; k++) {
    const slot = pick((s) => {
      const d = dayDiff(s.date);
      return d >= 1 && d <= 14 && parseInt(s.startTime) >= 15;
    });
    if (!slot) continue;
    const player = rand(players);
    const duration = Math.random() > 0.8 ? 2 : 1;
    const totalPrice = slot.price * duration;
    const bookingDate = new Date(slot.date.getTime() - (1 + Math.floor(Math.random() * 2)) * 86400000);
    bookingDate.setUTCHours(10 + Math.floor(Math.random() * 6), Math.random() > 0.5 ? 30 : 0, 0, 0);
    const booking = await prisma.booking.create({
      data: {
        userId: player.id,
        slotId: slot.id,
        totalPrice,
        status: "COMPLETED",
        bookingDate,
        checkInTime: new Date(slot.date.getTime() - 15 * 60000),
        checkOutTime: new Date(slot.date.getTime() + duration * 3600000),
        duration,
        paymentMethod: rand(paymentMethods),
      },
    });
    await prisma.timeSlot.update({ where: { id: slot.id }, data: { status: "BOOKED" } });
    await prisma.payment.create({
      data: { bookingId: booking.id, amount: totalPrice, method: booking.paymentMethod, status: "PAID", transactionId: `KH-${100000 + Math.floor(Math.random() * 899999)}` },
    });
    completedBookings.push(booking);
    bookingsCreated++;
  }

  // 2 confirmed (future evenings)
  for (let k = 0; k < 2; k++) {
    const slot = pick((s) => {
      const d = dayDiff(s.date);
      return d <= -1 && d >= -5 && parseInt(s.startTime) >= 18;
    });
    if (!slot) continue;
    const player = rand(players);
    const totalPrice = slot.price;
    const booking = await prisma.booking.create({
      data: {
        userId: player.id,
        slotId: slot.id,
        totalPrice,
        status: "CONFIRMED",
        bookingDate: new Date(),
        duration: 1,
        paymentMethod: rand(paymentMethods),
      },
    });
    await prisma.timeSlot.update({ where: { id: slot.id }, data: { status: "BOOKED" } });
    await prisma.payment.create({
      data: { bookingId: booking.id, amount: totalPrice, method: booking.paymentMethod, status: "PAID", transactionId: `KH-${100000 + Math.floor(Math.random() * 899999)}` },
    });
    bookingsCreated++;
  }

  // 1 pending (future daytime)
  const pending = pick((s) => {
    const d = dayDiff(s.date);
    return d <= -1 && d >= -3 && parseInt(s.startTime) < 18;
  });
  if (pending) {
    const player = rand(players);
    const booking = await prisma.booking.create({
      data: {
        userId: player.id,
        slotId: pending.id,
        totalPrice: pending.price,
        status: "PENDING",
        bookingDate: new Date(),
        duration: 1,
        paymentMethod: "COD",
      },
    });
    await prisma.timeSlot.update({ where: { id: pending.id }, data: { status: "BOOKED" } });
    await prisma.payment.create({
      data: { bookingId: booking.id, amount: pending.price, method: "COD", status: "PENDING" },
    });
    bookingsCreated++;
  }

  // 1 cancelled (slot stays AVAILABLE)
  const cancelled = pick((s) => {
    const d = dayDiff(s.date);
    return d <= 10 && d >= -2;
  });
  if (cancelled) {
    const player = rand(players);
    await prisma.booking.create({
      data: {
        userId: player.id,
        slotId: cancelled.id,
        totalPrice: cancelled.price,
        status: "CANCELLED",
        bookingDate: new Date(),
        duration: 1,
        paymentMethod: rand(paymentMethods),
      },
    });
    bookingsCreated++;
  }
}
console.log(`Seeded ${bookingsCreated} bookings`);

// ------------------------------------------------------------------
// REVIEWS (only for completed bookings)
// ------------------------------------------------------------------
let reviewsCreated = 0;
for (const booking of completedBookings) {
  const slot = await prisma.timeSlot.findUnique({
    where: { id: booking.slotId },
    include: { court: { select: { futsalId: true } } },
  });
  if (!slot) continue;
  const review = await prisma.review.create({
    data: {
      userId: booking.userId,
      futsalId: slot.court.futsalId,
      bookingId: booking.id,
      rating: rand(reviewRatings),
      comment: rand(reviewComments),
      createdAt: new Date(booking.bookingDate.getTime() + 2 * 86400000),
    },
  });
  reviewsCreated++;
}
console.log(`Seeded ${reviewsCreated} reviews`);

// ------------------------------------------------------------------
// FAVORITES (each player 2-4 favorites)
// ------------------------------------------------------------------
let favsCreated = 0;
for (const player of players) {
  const count = 2 + Math.floor(Math.random() * 3);
  const shuffled = [...activeFutsals].sort(() => 0.5 - Math.random());
  for (let idx = 0; idx < count && idx < shuffled.length; idx++) {
    try {
      await prisma.favorite.upsert({
        where: { userId_futsalId: { userId: player.id, futsalId: shuffled[idx].id } },
        update: {},
        create: { userId: player.id, futsalId: shuffled[idx].id },
      });
      favsCreated++;
    } catch (e) { /* skip dup */ }
  }
}
console.log(`Seeded ${favsCreated} favorites`);

// ------------------------------------------------------------------
// ADS
// ------------------------------------------------------------------
const ADS = [
  { title: "Summer Futsal League 2026", subtitle: "Register your team before the deadline & win Rs. 1 Lakh!", buttonText: "Join Now", buttonLink: "tournaments", imageUrl: "https://picsum.photos/seed/ad-summer/1200/500" },
  { title: "Weekend Training Camps", subtitle: "Professional coaching for kids & beginners every weekend", buttonText: "Book Session", buttonLink: "home", imageUrl: "https://picsum.photos/seed/ad-training/1200/500" },
  { title: "Corporate Tournament Nights", subtitle: "Book all courts with your team for an exclusive office night", buttonText: "Reserve Now", buttonLink: "home", imageUrl: "https://picsum.photos/seed/ad-corporate/1200/500" },
  { title: "Flat 10% off first booking", subtitle: "Use your first booking to get instant discounts on top arenas", buttonText: "Book Now", buttonLink: "futsals", imageUrl: "https://picsum.photos/seed/ad-discount/1200/500" },
];
for (const ad of ADS) {
  await prisma.ad.create({ data: ad });
}
console.log(`Seeded ${ADS.length} ads`);

// ------------------------------------------------------------------
// TOURNAMENTS, TEAMS, MATCHES
// ------------------------------------------------------------------
const TOURNAMENTS = [
  {
    name: "Srijana Chowk Holiday Cup 2026", futsalIdx: 6, type: "ROUND_ROBIN", isPublished: true,
    status: "DRAFT", maxTeams: 8, entryFee: 8000, prizePool: 150000,
    prizes: ["Trophy & Medals", "Rs. 100,000 Cash", "Rs. 30,000 Runner-up", "Man of the Match awards"],
    description: "The annual Holiday Cup returns to Srijana Chowk! Round-robin group stage followed by finals. Open to all community teams.",
    rules: "Teams must have min 5 and max 12 registered players. Matches are 2x20 minutes.",
    startInDays: 10, endInDays: 24, teams: 4,
  },
  {
    name: "Ganesh Tol Knockout Championship", futsalIdx: 3, type: "KNOCKOUT", isPublished: true,
    status: "DRAFT", maxTeams: 8, entryFee: 5000, prizePool: 80000,
    prizes: ["Trophy", "Rs. 50,000 Winner", "Rs. 20,000 Runner-up"],
    description: "Single-elimination knockout with a big atmosphere at Pokhara Futsal, Ganesh Tol. Seeds 4 teams, min 5 players each.",
    rules: "Winners advance; draws decided by penalties. Strict 2x25 minute matches.",
    startInDays: 13, endInDays: 16, teams: 4,
  },
  {
    name: "Naya Bazar Community Mini League", futsalIdx: 5, type: "ROUND_ROBIN", isPublished: true,
    status: "DRAFT", maxTeams: 6, entryFee: 4000, prizePool: 50000,
    prizes: ["Trophy", "Rs. 30,000 Winner", "Rs. 15,000 Runner-up"],
    description: "A friendly mini league for the Naya Bazar community. Play every weekend for three weeks.",
    rules: "Round-robin; top 2 after the group stage play the final.",
    startInDays: 8, endInDays: 21, teams: 4,
  },
];

const tournamentRows = [];
for (const def of TOURNAMENTS) {
  const futsal = futsalRows[def.futsalIdx];
  const tournament = await prisma.tournament.create({
    data: {
      futsalId: futsal.id,
      name: def.name,
      description: def.description,
      type: def.type,
      startDate: noonUTC(def.startInDays),
      endDate: noonUTC(def.endInDays),
      maxTeams: def.maxTeams,
      entryFee: def.entryFee,
      prizePool: def.prizePool,
      prizes: def.prizes,
      rules: def.rules,
      status: def.status,
      isPublished: def.isPublished,
    },
  });
  tournamentRows.push(tournament);
}

const TEAM_NAMES = [
  ["Lakeside Blasters", "Bagar United", "Chipledhunga Brave", "Mahendrapool Tigers"],
  ["Ranipauwa Giants", "Naya Bazar Boys", "Lamachaur FC", "Phewa Strikers"],
  ["Srijana Chowk Kings", "Ratna Chowk", "Kundahar Comets", "Hemja Rovers"],
];

let teamRows = [];
for (let t = 0; t < TOURNAMENTS.length; t++) {
  const tournament = tournamentRows[t];
  const names = TEAM_NAMES[t];
  const createdTeams = [];
  for (let k = 0; k < names.length; k++) {
    const team = await prisma.team.create({
      data: { name: names[k], tournamentId: tournament.id, status: "APPROVED" },
    });
    createdTeams.push(team);

    const captain = players[Math.floor(Math.random() * players.length)];
    await prisma.teamMember.create({
      data: {
        teamId: team.id,
        userId: captain.id,
        role: "CAPTAIN",
        playerName: captain.fullName,
        playerPhone: captain.phoneNumber,
        jerseyColor: rand(["Red", "Blue", "Green", "Yellow", "Black", "White"]),
      },
    });
    const memberNames = rand([
      ["Suman", "Ramesh", "Deepak", "Prakash", "Kiran"],
      ["Bina", "Gopal", "Raj", "Suresh", "Chandra"],
      ["Nabin", "Diwash", "Buddhi", "Karan", "Sabin"],
    ]);
    for (const m of memberNames) {
      await prisma.teamMember.create({
        data: { teamId: team.id, userId: null, role: "PLAYER", playerName: m },
      });
    }
  }
  teamRows.push(createdTeams);

  // Matches
  const start = noonUTC(TOURNAMENTS[t].startInDays);
  const matches = [];
  if (tournament.type === "KNOCKOUT") {
    const pairs = [[createdTeams[0], createdTeams[1]], [createdTeams[2], createdTeams[3]]];
    pairs.forEach(([home, away], idx) => {
      const d = new Date(start); d.setUTCDate(d.getUTCDate() + idx);
      matches.push({ tournamentId: tournament.id, homeTeamId: home.id, awayTeamId: away.id, matchDate: d, round: "SEMI_FINAL", status: "SCHEDULED" });
    });
  } else {
    // round robin: all pairs
    let dayIdx = 0;
    for (let i = 0; i < createdTeams.length; i++) {
      for (let j = i + 1; j < createdTeams.length; j++) {
        const d = new Date(start); d.setUTCDate(d.getUTCDate() + dayIdx);
        const completed = t === 2 && dayIdx < 3; // some completed for leaderboard
        matches.push({
          tournamentId: tournament.id,
          homeTeamId: createdTeams[i].id,
          awayTeamId: createdTeams[j].id,
          matchDate: d,
          round: "GROUP_STAGE",
          status: completed ? "COMPLETED" : "SCHEDULED",
          homeScore: completed ? Math.floor(Math.random() * 5) : null,
          awayScore: completed ? Math.floor(Math.random() * 5) : null,
        });
        dayIdx++;
      }
    }
  }
  await prisma.match.createMany({ data: matches });
}
console.log(`Seeded ${tournamentRows.length} tournaments, ${teamRows.flat().length} teams`);

// ------------------------------------------------------------------
// NOTIFICATIONS
// ------------------------------------------------------------------
let notifCreated = 0;
for (const player of players.slice(0, 12)) {
  await prisma.notification.create({
    data: { userId: player.id, title: "Welcome to Futsal Booking", message: "Book courts at your favourite arenas and join tournaments across Pokhara.", type: "welcome", isRead: Math.random() > 0.5 },
  });
  notifCreated++;
}
for (const owner of owners) {
  await prisma.notification.create({
    data: { userId: owner.id, title: "New Booking Received", message: `A player just booked a slot at ${rand(activeFutsals).name}. Check your dashboard.`, type: "new_booking", isRead: false },
  });
  await prisma.notification.create({
    data: { userId: owner.id, title: "Off-peak hours tip", message: "Offer discounts on weekday mornings to attract more bookings.", type: "tip", isRead: true },
  });
  notifCreated += 2;
}

// booking confirmed notifications for a handful of players
{
  const recent = await prisma.booking.findMany({
    where: { status: { in: ["CONFIRMED", "COMPLETED"] } },
    include: { slot: { include: { court: { include: { futsal: { select: { name: true } } } } } } },
    take: 10,
    orderBy: { id: "desc" },
  });
  for (const booking of recent) {
    await prisma.notification.create({
      data: {
        userId: booking.userId,
        title: "Booking Confirmed",
        message: `Your booking at ${booking.slot.court.futsal.name} on ${booking.slot.date.toISOString().slice(0, 10)} ${booking.slot.startTime} is confirmed.`,
        type: "booking_confirmed",
        isRead: false,
      },
    });
    notifCreated++;
  }
}
console.log(`Seeded ${notifCreated} notifications`);

// ------------------------------------------------------------------
// ACTIVITY LOG (fills admin "Recent Activity")
// ------------------------------------------------------------------
const activities = [];
for (const u of players.slice(0, 6)) {
  activities.push({ type: "USER_REGISTER", description: `New player registered: ${u.email}`, userId: u.id, category: "User Added", status: "registered" });
}
for (const f of activeFutsals.slice(0, 6)) {
  activities.push({ type: "FUTSAL_CREATED", description: `New futsal created: ${f.name}`, userId: f.ownerId, category: "Futsal", status: "created" });
  activities.push({ type: "FUTSAL_APPROVED", description: `Futsal ${f.name} approved and activated`, userId: f.ownerId, category: "Futsal", status: "approved" });
}
for (const b of completedBookings.slice(0, 5)) {
  activities.push({ type: "BOOKING_MADE", description: `New booking completed (${npr(b.totalPrice)})`, userId: b.userId, category: "Booking", status: "completed" });
}
for (const u of admins) {
  activities.push({ type: "ADMIN_LOGIN", description: `Admin ${u.email} logged in`, userId: u.id, category: "User Login", status: "completed" });
}
for (const a of activities) {
  await prisma.activityLog.create({ data: a });
}
console.log(`Seeded ${activities.length} activity logs`);

// ------------------------------------------------------------------
// SYSTEM SETTINGS
// ------------------------------------------------------------------
await prisma.systemSettings.upsert({
  where: { id: 1 },
  update: {},
  create: {
    id: 1,
    autoApproveOwners: false,
    autoApproveFutsals: false,
    maintenanceMode: false,
    bookingCancellationHours: 2,
    slotLockMinutes: 5,
    slotGenerationDays: 30,
  },
});

// ------------------------------------------------------------------
// SUMMARY + USER LIST
// ------------------------------------------------------------------
const [uCount, fCount, cCount, sCount, bCount, rCount, favCount, adCount, tCount] = await Promise.all([
  prisma.user.count(),
  prisma.futsal.count(),
  prisma.court.count(),
  prisma.timeSlot.count(),
  prisma.booking.count(),
  prisma.review.count(),
  prisma.favorite.count(),
  prisma.ad.count(),
  prisma.tournament.count(),
]);

console.log("\n===== SEED COMPLETE =====");
console.log(`Users: ${uCount} | Futsals: ${fCount} | Courts: ${cCount} | Slots: ${sCount} | Bookings: ${bCount} | Reviews: ${rCount} | Favorites: ${favCount} | Ads: ${adCount} | Tournaments: ${tCount}`);
console.log("\n----- LOGIN CREDENTIALS (password for ALL: habil1234) -----");
for (const u of allUsers) {
  console.log(`${u.role} | ${u.email} | ${u.fullName}`);
}

await prisma.$disconnect();