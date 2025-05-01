// controllers/offeredRideController.js

const asyncHandler = require('express-async-handler');
const { getOfferedRideCollection } = require('../models/offeredRideModel');

exports.offerRide = asyncHandler(async (req, res) => {
  const {
    pickupLocation,
    dropLocation,
    date,
    time,
    totalSeats,
    seatsAvailable,
    luggage = {}
  } = req.body;

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

  // build document
  const doc = {
    email,
    pickupLocation,
    dropLocation,
    date:          new Date(date),
    time,
    totalSeats,
    seatsAvailable,
    luggage,
    createdAt:     new Date()
  };

  // insert into rides.offeredride
  const col    = await getOfferedRideCollection();
  const result = await col.insertOne(doc);

  res.status(201).json({
    message: 'Ride offered successfully',
    ride: { _id: result.insertedId, ...doc }
  });
});
