/**
 * Get operating hours for a specific day
 * @param {Object} futsal - Futsal object with operatingHours
 * @param {Date} date - Date to get hours for
 * @returns {Object} { openHour, closeHour }
 */
export const getOperatingHoursForDay = (futsal, date) => {
  const days = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
  const dayName = days[date.getDay()];
  
  // Default hours if no operating hours set (8 AM to 10 PM)
  const defaultHours = { openHour: 8, closeHour: 22 };
  
  if (!futsal?.operatingHours) {
    return defaultHours;
  }
  
  const dayHours = futsal.operatingHours[dayName];
  if (!dayHours || !dayHours.open || !dayHours.close) {
    return defaultHours;
  }
  
  const openHour = parseInt(dayHours.open.split(':')[0]);
  const closeHour = parseInt(dayHours.close.split(':')[0]);
  
  // Validate hours
  if (isNaN(openHour) || isNaN(closeHour)) {
    return defaultHours;
  }
  
  return { openHour, closeHour };
};

/**
 * Generate slots for a specific court and date range
 * @param {Object} court - Court object
 * @param {Object} futsal - Futsal object with operatingHours
 * @param {Date} startDate - Start date
 * @param {Date} endDate - End date
 * @returns {Array} Array of slot objects
 */
export const generateSlotsForCourt = async (court, futsal, startDate, endDate) => {
  const slots = [];
  const currentDate = new Date(startDate);
  
  while (currentDate <= endDate) {
    const { openHour, closeHour } = getOperatingHoursForDay(futsal, currentDate);
    
    // Create date at midnight for consistent storage
    const slotDate = new Date(currentDate);
    slotDate.setHours(0, 0, 0, 0);
    
    for (let hour = openHour; hour < closeHour; hour++) {
      const startTime = `${hour.toString().padStart(2, '0')}:00`;
      const endTime = `${(hour + 1).toString().padStart(2, '0')}:00`;
      
      // Calculate price based on time
      const isPeakHour = hour >= 17 && hour <= 20;
      const dayOfWeek = currentDate.getDay();
      const isWeekend = dayOfWeek === 0 || dayOfWeek === 6;
      
      let price = court.basePrice;
      if (court.peakPrice && (isPeakHour || isWeekend)) {
        price = court.peakPrice;
      }
      
      slots.push({
        courtId: court.id,
        date: slotDate,
        startTime,
        endTime,
        price,
        status: 'AVAILABLE'
      });
    }
    
    currentDate.setDate(currentDate.getDate() + 1);
  }
  
  return slots;
};