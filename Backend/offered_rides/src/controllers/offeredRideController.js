const asyncHandler = require('express-async-handler');
const OfferedRide  = require('../models/offeredRideModel');

// POST /rides/offer-ride
exports.offerRide = asyncHandler(async (req, res) => {
  const {
    pickupLocation,
    dropLocation,
    date,
    time,
    totalSeats,
    seatsAvailable,
    luggage
  } = req.body;

  // extract email from token payload
  const { email } = req.user;
  if (!email) {
    res.status(401);
    throw new Error('Invalid token: email missing');
  }

  if (
    !pickupLocation ||
    !dropLocation ||
    !date ||
    !time ||
    totalSeats == null ||
    seatsAvailable == null
  ) {
    res.status(400);
    throw new Error('Missing required fields');
  }

  const ride = await OfferedRide.create({
    email,
    pickupLocation,
    dropLocation,
    date:          new Date(date),
    time,
    totalSeats,
    seatsAvailable,
    luggage:       luggage || {}
  });

  res.status(201).json({ message: 'Ride offered successfully', ride });
});
