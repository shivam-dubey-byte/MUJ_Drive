const asyncHandler                 = require('express-async-handler');
const { ObjectId }                 = require('mongodb');
const { getOfferedRideCollection } = require('../models/offeredRideModel');
const { getBookingCollection }     = require('../models/bookingModel');
const { findStudentByEmail }       = require('../models/studentModel');

exports.getOfferedRidesWithUsers = asyncHandler(async (req, res) => {
  const userEmail = req.user?.email;
  if (!userEmail) {
    res.status(401);
    throw new Error('Not authenticated');
  }

  const rideCol = await getOfferedRideCollection();
  const bookCol = await getBookingCollection();

  // 1) fetch all rides this user offered
  const offeredRides = await rideCol.find({ email: userEmail }).toArray();

  // 2) for each ride, fetch all bookings + student info
  const result = await Promise.all(offeredRides.map(async ride => {
    const rideIdStr = ride._id.toString();

    // find all bookings for this ride
    const bookings = await bookCol.find({ rideId: rideIdStr }).toArray();

    // enrich each booking with student details
    const joiners = await Promise.all(bookings.map(async br => {
      const student = await findStudentByEmail(br.studentEmail);
      return {
        bookingId:   br._id,
        status:      br.status,
        requestedAt: br.requestedAt,
        respondedAt: br.respondedAt,
        student: {
          name:           student.name,
          registrationNo: student.registrationNo,
          phone:          student.phone,
        }
      };
    }));

    return {
      rideId:         rideIdStr,
      pickupLocation: ride.pickupLocation,
      dropLocation:   ride.dropLocation,
      date:           ride.date,
      time:           ride.time,
      totalSeats:     ride.totalSeats,
      seatsAvailable: ride.seatsAvailable,
      luggage:        ride.luggage,
      createdAt:      ride.createdAt,
      joiners
    };
  }));

  res.json({ offeredRides: result });
});
