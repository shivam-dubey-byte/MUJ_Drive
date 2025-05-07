// src/controllers/dashboardController.js

const asyncHandler                 = require('express-async-handler');
const { ObjectId }                 = require('mongodb');
const { getOfferedRideCollection } = require('../models/offeredRideModel');
const { getBookingCollection }     = require('../models/bookingModel');
const { findStudentByEmail }       = require('../models/studentModel');

exports.getDashboard = asyncHandler(async (req, res) => {
  // 0) Auth guard
  if (!req.user || !req.user.email) {
    res.status(401);
    throw new Error('Not authenticated');
  }
  const userEmail = req.user.email;

  // 1) All rides *I* offered
  const rideCol      = await getOfferedRideCollection();
  const offeredRides = await rideCol
    .find({ email: userEmail })
    .toArray();
  // Convert each ObjectId to hex string so it matches booking.rideId
  const offeredIds   = offeredRides.map(r => r._id.toString());

  // 2) Incoming requests on those rides (rideId stored as string in bookings)
  const bookingCol  = await getBookingCollection();
  const incomingRaw = await bookingCol
    .find({ rideId: { $in: offeredIds } })
    .toArray();

  const incomingRequests = await Promise.all(
    incomingRaw.map(async br => {
      // Find the matching ride by comparing hex strings
      const ride      = offeredRides.find(r => r._id.toString() === br.rideId);
      const requester = await findStudentByEmail(br.studentEmail);
      return {
        bookingId:   br._id,
        rideId:      br.rideId,
        status:      br.status,
        rideDetails: {
          pickupLocation: ride.pickupLocation,
          dropLocation:   ride.dropLocation,
          date:           ride.date,
          time:           ride.time
        },
        requester: {
          name:           requester.name,
          registrationNo: requester.registrationNo,
          phone:          requester.phone
        }
      };
    })
  );

  // 3) My own bookings (as a rider)
  const myRaw      = await bookingCol
    .find({ studentEmail: userEmail })
    .toArray();

  const myBookings = await Promise.all(
    myRaw.map(async br => {
      // Convert the stored string back into ObjectId to fetch the ride doc
      const ride    = await rideCol.findOne({ _id: new ObjectId(br.rideId) });
      const offerer = await findStudentByEmail(ride.email);
      return {
        bookingId:   br._id,
        rideId:      br.rideId,
        status:      br.status,
        rideDetails: {
          pickupLocation: ride.pickupLocation,
          dropLocation:   ride.dropLocation,
          date:           ride.date,
          time:           ride.time
        },
        offerer: {
          name:           offerer.name,
          registrationNo: offerer.registrationNo,
          phone:          offerer.phone
        }
      };
    })
  );

  // 4) Split my bookings into active, pending, and past
  const activeBookings  = myBookings.filter(b => b.status === 'accepted');
  const pendingBookings = myBookings.filter(b => b.status === 'requested');
  const pastBookings    = myBookings.filter(
    b => b.status !== 'accepted' && b.status !== 'requested'
  );

  // Respond with all four lists
  res.json({
    incomingRequests,
    activeBookings,
    pendingBookings,
    pastBookings
  });
});
