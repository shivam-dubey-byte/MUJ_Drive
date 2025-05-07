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
  // Convert ObjectIds to strings to match booking.rideId
  const offeredIds   = offeredRides.map(r => r._id.toString());

  // 2) Incoming requests on those rides (only pending)
  const bookingCol  = await getBookingCollection();
  const incomingRaw = await bookingCol
    .find({
      rideId: { $in: offeredIds },
      status: 'requested'    // <-- only show pending
    })
    .toArray();

  const incomingRequests = await Promise.all(
    incomingRaw.map(async br => {
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

  // 3) My own bookings (as rider)
  const myRaw      = await bookingCol
    .find({ studentEmail: userEmail })
    .toArray();

  const myBookings = await Promise.all(
    myRaw.map(async br => {
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

  // 4) Partition myBookings into Active / Pending / Past
  const now = new Date();
  const activeBookings  = [];
  const pendingBookings = [];
  const pastBookings    = [];

  myBookings.forEach(b => {
    // build a Date for ride date+time
    const dt = new Date(b.rideDetails.date);
    const [timePart, ampm] = b.rideDetails.time.split(' ');
    let [h, m] = timePart.split(':').map(n => parseInt(n, 10));
    if (ampm) {
      const isPM = ampm.toLowerCase() === 'pm';
      if (isPM && h < 12) h += 12;
      if (!isPM && h === 12) h = 0;
    }
    dt.setHours(h, m, 0, 0);

    if (b.status === 'requested') {
      pendingBookings.push(b);
    } else if (b.status === 'accepted' && dt > now) {
      activeBookings.push(b);
    } else {
      pastBookings.push(b);
    }
  });

  // 5) Send back all four lists
  res.json({
    incomingRequests,
    activeBookings,
    pendingBookings,
    pastBookings
  });
});
