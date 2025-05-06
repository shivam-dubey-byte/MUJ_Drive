// src/controllers/dashboardController.js

const asyncHandler                 = require('express-async-handler');
const { getOfferedRideCollection } = require('../models/offeredRideModel');
const { getBookingCollection }     = require('../models/bookingModel');
const { findStudentByEmail }       = require('../models/studentModel');

exports.getDashboard = asyncHandler(async (req, res) => {
  const userEmail = req.user.email; // set by your authMiddleware

  // 1) All rides *I* offered
  const rideCol      = await getOfferedRideCollection();
  const offeredRides = await rideCol.find({ email: userEmail }).toArray();
  const offeredIds   = offeredRides.map(r => r._id);

  // 2) Incoming requests on those rides
  const bookingCol   = await getBookingCollection();
  const incomingRaw  = await bookingCol.find({ rideId: { $in: offeredIds } }).toArray();
  const incomingRequests = await Promise.all(
    incomingRaw.map(async br => {
      const ride      = offeredRides.find(r => r._id.equals(br.rideId));
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

  // 3) My own bookings (as rider)
  const myRaw     = await bookingCol.find({ studentEmail: userEmail }).toArray();
  const myBookings = await Promise.all(
    myRaw.map(async br => {
      const ride    = await rideCol.findOne({ _id: br.rideId });
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

  // 4) Partition my bookings
  const active  = myBookings.filter(b => b.status === 'accepted');
  const pending = myBookings.filter(b => b.status === 'requested');
  const past    = myBookings.filter(b => b.status !== 'accepted' && b.status !== 'requested');

  res.json({
    incomingRequests,
    activeBookings:  active,
    pendingBookings: pending,
    pastBookings:    past
  });
});
