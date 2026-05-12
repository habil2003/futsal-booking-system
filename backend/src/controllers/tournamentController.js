import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

// Admin: Create tournament
export const createTournament = async (req, res) => {
  try {
    console.log('📥 Create tournament request body:', req.body);

    const {
      futsalId,
      name,
      description,
      type,
      startDate,
      endDate,
      maxTeams,
      entryFee,
      prizePool,
      rules,
      prizes,
      isPublished = false,
    } = req.body;

    // Validate required fields
    if (!futsalId || !name || !type || !startDate || !maxTeams) {
      console.error('❌ Missing required fields:', { futsalId, name, type, startDate, maxTeams });
      return res.status(400).json({
        status: 'error',
        message: 'Futsal, name, type, start date, and max teams are required',
      });
    }

    // Ensure prizes is an array of strings (defensive)
    let prizesArray = [];
    if (Array.isArray(prizes)) {
      prizesArray = prizes.filter(p => p && typeof p === 'string').map(p => p.trim());
    } else if (typeof prizes === 'string') {
      prizesArray = prizes.split(',').map(p => p.trim()).filter(p => p);
    }

    // Check if futsal exists
    const futsalExists = await prisma.futsal.findUnique({
      where: { id: parseInt(futsalId) },
    });
    if (!futsalExists) {
      return res.status(400).json({ status: 'error', message: 'Futsal not found' });
    }

    // Validate type enum
    const validTypes = ['LEAGUE', 'KNOCKOUT'];
if (!validTypes.includes(type)) {
  return res.status(400).json({ status: 'error', message: 'Invalid tournament type' });
}
    const tournamentData = {
      futsalId: parseInt(futsalId),
      name: name.trim(),
      description: description?.trim() || null,
      type,
      startDate: new Date(startDate),
      endDate: endDate ? new Date(endDate) : null,
      maxTeams: parseInt(maxTeams),
      entryFee: entryFee ? parseFloat(entryFee) : null,
      prizePool: prizePool ? parseFloat(prizePool) : null,
      rules: rules?.trim() || null,
      prizes: prizesArray,
      isPublished: isPublished === 'true' || isPublished === true,
      status: 'DRAFT',
    };

    console.log('📝 Creating tournament with data:', tournamentData);

    const tournament = await prisma.tournament.create({
      data: tournamentData,
    });

    console.log('✅ Tournament created:', tournament.id);
    res.status(201).json({ status: 'success', data: tournament });
  } catch (error) {
    console.error('Create tournament error:', error);
    // Log detailed Prisma error
    if (error.code) {
      console.error(`Prisma error code: ${error.code}`);
      console.error('Prisma error meta:', error.meta);
    }
    res.status(500).json({ status: 'error', message: error.message });
  }
};

// Admin: Get all tournaments
export const getAllTournaments = async (req, res) => {
  try {
    const tournaments = await prisma.tournament.findMany({
      include: { futsal: { select: { name: true } } },
      orderBy: { createdAt: 'desc' },
    });
    res.json({ status: 'success', data: tournaments });
  } catch (error) {
    console.error('Get tournaments error:', error);
    res.status(500).json({ status: 'error', message: 'Failed to fetch tournaments' });
  }
};

// Admin: Update tournament
export const updateTournament = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      futsalId,
      name,
      description,
      type,
      startDate,
      endDate,
      maxTeams,
      entryFee,
      prizePool,
      rules,
      prizes,
      isPublished,
      status,
    } = req.body;

    const imageUrl = req.file?.path;

    const updateData = {};
    if (futsalId) updateData.futsalId = parseInt(futsalId);
    if (name) updateData.name = name;
    if (description !== undefined) updateData.description = description;
    if (type) updateData.type = type;
    if (startDate) updateData.startDate = new Date(startDate);
    if (endDate !== undefined) updateData.endDate = endDate ? new Date(endDate) : null;
    if (maxTeams) updateData.maxTeams = parseInt(maxTeams);
    if (entryFee !== undefined) updateData.entryFee = entryFee ? parseFloat(entryFee) : null;
    if (prizePool !== undefined) updateData.prizePool = prizePool ? parseFloat(prizePool) : null;
    if (rules !== undefined) updateData.rules = rules;
    if (prizes) updateData.prizes = prizes;
    if (isPublished !== undefined) updateData.isPublished = isPublished === 'true' || isPublished === true;
    if (status) updateData.status = status;
    if (imageUrl) updateData.imageUrl = imageUrl; // Assuming you add imageUrl field to schema

    const tournament = await prisma.tournament.update({
      where: { id: parseInt(id) },
      data: updateData,
    });

    res.json({ status: 'success', data: tournament });
  } catch (error) {
    console.error('Update tournament error:', error);
    if (error.code === 'P2025') {
      return res.status(404).json({ status: 'error', message: 'Tournament not found' });
    }
    res.status(500).json({ status: 'error', message: 'Failed to update tournament' });
  }
};

// Admin: Delete tournament
export const deleteTournament = async (req, res) => {
  try {
    const { id } = req.params;
    await prisma.tournament.delete({ where: { id: parseInt(id) } });
    res.json({ status: 'success', message: 'Tournament deleted' });
  } catch (error) {
    console.error('Delete tournament error:', error);
    if (error.code === 'P2025') {
      return res.status(404).json({ status: 'error', message: 'Tournament not found' });
    }
    res.status(500).json({ status: 'error', message: 'Failed to delete tournament' });
  }
};

// Public: Get published tournaments (for home screen)
export const getPublishedTournaments = async (req, res) => {
  try {
    const tournaments = await prisma.tournament.findMany({
      where: { isPublished: true },
      include: { futsal: { select: { name: true } } },
      orderBy: { startDate: 'asc' },
    });
    res.json({ status: 'success', data: tournaments });
  } catch (error) {
    console.error('Get published tournaments error:', error);
    res.status(500).json({ status: 'error', message: 'Failed to fetch tournaments' });
  }
};

// Get futsals for dropdown
export const getFutsalsForDropdown = async (req, res) => {
  try {
    const futsals = await prisma.futsal.findMany({
      where: { status: 'ACTIVE' },
      select: { id: true, name: true },
      orderBy: { name: 'asc' },
    });
    res.json({ status: 'success', data: futsals });
  } catch (error) {
    res.status(500).json({ status: 'error', message: 'Failed to fetch futsals' });
  }
};