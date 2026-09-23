import { prisma } from "../index.js";

/**
 * Get all approved futsals
 */
export const getAllFutsals = async (req, res) => {
  try {
    const { lat, lng, radius } = req.query;

    let whereClause = { status: 'ACTIVE' };

    // Add location-based filtering if coordinates provided (optional)
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

    // Calculate average rating for each futsal
    const futsalsWithRating = futsals.map((futsal) => {
      const avgRating =
        futsal.reviews.length > 0
          ? futsal.reviews.reduce((sum, review) => sum + review.rating, 0) /
            futsal.reviews.length
          : 0;

      // Remove reviews from response to keep it clean
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

    // Calculate average rating
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

    // Parse date
    const queryDate = new Date(date);
    queryDate.setHours(0, 0, 0, 0);

    const nextDay = new Date(queryDate);
    nextDay.setDate(nextDay.getDate() + 1);

    // FIXED: Use court relation instead of direct futsalId
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

    // Format response to match frontend expectations
    const formattedSlots = slots.map((slot) => ({
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
 * Create a new futsal
 */
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
      courts,
    } = req.body;

    if (!name || !address) {
      return res.status(400).json({
        status: "error",
        message: "Please provide name and address",
      });
    }

    // ── Minimum viable listing (anti-spam + approval basis) ──
    if (!images || !Array.isArray(images) || images.length === 0) {
      return res.status(400).json({
        status: "error",
        message: "Please upload at least one photo of your futsal",
      });
    }
    if (
      latitude === undefined ||
      latitude === null ||
      isNaN(parseFloat(latitude)) ||
      longitude === undefined ||
      longitude === null ||
      isNaN(parseFloat(longitude))
    ) {
      return res.status(400).json({
        status: "error",
        message: "Please set your futsal location using GPS",
      });
    }
    if (!courts || !Array.isArray(courts) || courts.length === 0) {
      return res.status(400).json({
        status: "error",
        message: "Add at least one court to your futsal",
      });
    }
    const validCourts = courts
      .filter(
        (c) =>
          c &&
          c.courtNumber &&
          c.courtType &&
          c.basePrice !== undefined &&
          c.basePrice !== null
      )
      .map((c) => ({
        courtNumber: String(c.courtNumber).trim(),
        courtType: String(c.courtType).trim(),
        basePrice: parseFloat(c.basePrice),
        peakPrice: c.peakPrice != null ? parseFloat(c.peakPrice) : null,
        amenities: Array.isArray(c.amenities) ? c.amenities : [],
      }));
    if (validCourts.length === 0) {
      return res.status(400).json({
        status: "error",
        message: "Each court needs a number, type, and base price",
      });
    }

    if (!req.user || !req.user.id) {
      return res.status(401).json({
        status: "error",
        message: "Authentication required",
      });
    }

    // ── Honor the auto-approve system setting ──
    let shouldAutoApprove = false;
    try {
      const settings = await prisma.systemSettings.findFirst();
      shouldAutoApprove = settings?.autoApproveFutsals === true;
    } catch (_) {}

    const status = shouldAutoApprove ? "ACTIVE" : "PENDING";
    const isApproved = shouldAutoApprove;

    const futsal = await prisma.$transaction(async (tx) => {
      const created = await tx.futsal.create({
        data: {
          name,
          description,
          address,
          images: images || [],
          latitude: parseFloat(latitude),
          longitude: parseFloat(longitude),
          operatingHours: operatingHours || null,
          ownerId: req.user.id,
          status,
          isApproved,
        },
      });

      await tx.court.createMany({
        data: validCourts.map((c) => ({ ...c, futsalId: created.id })),
      });

      return created;
    });

    res.status(201).json({
      status: "success",
      message: shouldAutoApprove
        ? "Futsal created and approved."
        : "Futsal created successfully. Waiting for admin approval.",
      futsal,
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
      isApproved,  // Keep for backward compatibility
      status,      // New status field
      toggleActive, // For toggling
    } = req.body;

    const existingFutsal = await prisma.futsal.findUnique({
      where: { id: parseInt(id) },
    });

    if (!existingFutsal) {
      return res.status(404).json({
        status: "error",
        message: "Futsal not found",
      });
    }

    if (existingFutsal.ownerId !== req.user.id && req.user.role !== "ADMIN") {
      return res.status(404).json({
        status: "error",
        message: "Futsal not found or you do not have permission",
      });
    }

    const isAdmin = req.user.role === "ADMIN";

    // ── Status changes: ADMIN only, or owner operational ACTIVE<->DEACTIVATED ──
    let newStatus;
    if (isAdmin) {
      if (toggleActive) {
        newStatus = existingFutsal.status === 'ACTIVE' ? 'DEACTIVATED' : 'ACTIVE';
      } else if (isApproved !== undefined) {
        newStatus = isApproved ? 'ACTIVE' : 'DEACTIVATED';
      }
      newStatus = newStatus ?? status;
    } else {
      // Owner can never set approval status directly
      if (status !== undefined || isApproved !== undefined) {
        return res.status(403).json({
          status: "error",
          message: "You cannot change approval status",
        });
      }
      // Owner may flip between ACTIVE and DEACTIVATED (self-managed),
      // but can NEVER promote a PENDING futsal (no self-approval)
      if (toggleActive) {
        if (
          existingFutsal.status !== 'ACTIVE' &&
          existingFutsal.status !== 'DEACTIVATED'
        ) {
          return res.status(403).json({
            status: "error",
            message: "This futsal is awaiting admin approval",
          });
        }
        newStatus = existingFutsal.status === 'ACTIVE' ? 'DEACTIVATED' : 'ACTIVE';
      }
    }

    // ── Identity detail edits re-flag PENDING for admin review ──
    const editingDetails =
      name !== undefined ||
      description !== undefined ||
      address !== undefined ||
      images !== undefined ||
      latitude !== undefined ||
      longitude !== undefined ||
      operatingHours !== undefined;

    if (!isAdmin && editingDetails && newStatus === undefined) {
      if (
        existingFutsal.status === 'ACTIVE' ||
        existingFutsal.status === 'DEACTIVATED'
      ) {
        newStatus = 'PENDING';
      }
    }

    const data = {};
    if (name !== undefined) data.name = name;
    if (description !== undefined) data.description = description;
    if (address !== undefined) data.address = address;
    if (images !== undefined) data.images = images;
    if (latitude !== undefined) data.latitude = latitude ? parseFloat(latitude) : undefined;
    if (longitude !== undefined) data.longitude = longitude ? parseFloat(longitude) : undefined;
    if (operatingHours !== undefined) data.operatingHours = operatingHours;
    if (newStatus !== undefined) data.status = newStatus;
    if (isAdmin && isApproved !== undefined) data.isApproved = isApproved;

    const futsal = await prisma.futsal.update({
      where: { id: parseInt(id) },
      data,
    });

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

    // First check if futsal exists and user has permission
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

    // Check if futsal has any bookings
    const bookingCount = await prisma.booking.count({
      where: {
        slot: {
          court: {
            futsalId: futsalId,
          },
        },
      },
    });

    // Check if futsal has any favorites
    const favoriteCount = await prisma.favorite.count({
      where: {
        futsalId: futsalId,
      },
    });

    // If there are bookings or favorites, prevent deletion
    if (bookingCount > 0 || favoriteCount > 0) {
      return res.status(400).json({
        status: "error",
        message:
          "Cannot delete futsal. It has existing bookings or favorites. Consider archiving it instead.",
        details: {
          bookings: bookingCount,
          favorites: favoriteCount,
        },
      });
    }

    // If no related data, proceed with deletion
    await prisma.futsal.delete({
      where: { id: futsalId },
    });

    res.json({
      status: "success",
      message: "Futsal deleted successfully",
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

    // Add court count to response
    const futsalsWithCount = futsals.map((futsal) => ({
      ...futsal,
      courtCount: futsal._count?.courts || 0,
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
