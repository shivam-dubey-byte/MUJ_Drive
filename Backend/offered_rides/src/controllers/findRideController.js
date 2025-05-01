// controllers/findRideController.js

const asyncHandler = require('express-async-handler');
const { getOfferedRideCollection } = require('../models/offeredRideModel');

// Helper: normalize a ride.time string ("HH:mm" or "h:mm AM/PM") to "HH:MM:SS"
function normalizeTime(t) {
  const tl = t.trim().toLowerCase();
  if (tl.endsWith('am') || tl.endsWith('pm')) {
    // e.g. "3:19 AM"
    let [timePart, mod] = t.split(' ');
    let [h, m] = timePart.split(':').map(Number);
    const modifier = mod.toLowerCase();
    if (modifier === 'pm' && h !== 12) h += 12;
    if (modifier === 'am' && h === 12) h = 0;
    return `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}:00`;
  }
  // assume "HH:mm"
  const [h, m] = t.split(':').map(s => s.padStart(2, '0'));
  return `${h}:${m}:00`;
}

exports.findRides = asyncHandler(async (req, res) => {
  const { pickupLocation, dropLocation, date, time } = req.body;
  if (!pickupLocation || !dropLocation || !date || !time) {
    res.status(400);
    throw new Error('Missing required fields');
  }

  const col = await getOfferedRideCollection();

  // Build the desired DateTime
  const desiredDateStr = date; // "YYYY-MM-DD"
  const desiredTimeNorm = normalizeTime(time);
  const desiredDateTime = new Date(`${desiredDateStr}T${desiredTimeNorm}`);

  // Fetch all matching pickup/drop rides
  const rides = await col
    .find({ pickupLocation, dropLocation })
    .toArray();

  // Annotate each ride with its time difference in ms
  const annotated = rides.map(r => {
    const rideDateStr = r.date.toISOString().split('T')[0];
    const rideTimeNorm = normalizeTime(r.time);
    const rideDateTime = new Date(`${rideDateStr}T${rideTimeNorm}`);
    const diff = Math.abs(rideDateTime.getTime() - desiredDateTime.getTime());
    return { ride: r, diff };
  });

  // Sort by ascending difference (exact match → diff=0 first)
  annotated.sort((a, b) => a.diff - b.diff);

  // Strip the diff annotation
  const sortedRides = annotated.map(a => a.ride);

  res.json({ rides: sortedRides });
});
