// controllers/findRideController.js

const asyncHandler = require('express-async-handler');
const { getOfferedRideCollection } = require('../models/offeredRideModel');
const { findStudentByEmail }      = require('../models/studentModel');
const { findDriverByEmail }       = require('../models/driverModel');  // ← import driver helper

exports.findRides = asyncHandler(async (req, res) => {
  const { pickupLocation, dropLocation, date, time } = req.body;
  if (!pickupLocation || !dropLocation || !date || !time) {
    res.status(400);
    throw new Error('Missing required search parameters');
  }

  const col = await getOfferedRideCollection();

  // 1) exact date & time
  let rides = await col
    .find({
      pickupLocation,
      dropLocation,
      date: new Date(date),
      time
    })
    .toArray();

  // 2) if none, search ±1 day
  if (rides.length === 0) {
    const dt   = new Date(date);
    const prev = new Date(dt); prev.setDate(dt.getDate() - 1);
    const next = new Date(dt); next.setDate(dt.getDate() + 1);

    rides = await col
      .find({
        pickupLocation,
        dropLocation,
        date: { $gte: prev, $lte: next }
      })
      .toArray();
  }

  // 3) enrich each ride with student.name/phone or driver.name/phone
  const enriched = await Promise.all(
    rides.map(async ride => {
      let person = await findStudentByEmail(ride.email);
      if (!person) {
        person = await findDriverByEmail(ride.email);
      }

      return {
        rideId: ride._id,
        pickupLocation: ride.pickupLocation,
        dropLocation:   ride.dropLocation,
        date:           ride.date,
        time:           ride.time,
        totalSeats:     ride.totalSeats,
        seatsAvailable: ride.seatsAvailable,
        luggage:        ride.luggage,
        name:           person?.name  || 'Unknown',
        phone:          person?.phone || ''
      };
    })
  );

  res.json({ rides: enriched });
});
