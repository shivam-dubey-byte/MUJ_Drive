// src/controllers/bookingController.js

const asyncHandler                 = require('express-async-handler');
const { ObjectId }                 = require('mongodb');
const { getOfferedRideCollection } = require('../models/offeredRideModel');
const { getBookingCollection }     = require('../models/bookingModel');
const { getNotificationCollection}= require('../models/notificationModel');
const { sendMail }                 = require('../mail/mailService');
const { findStudentByEmail }       = require('../models/studentModel');

/**
 * 1) Student books a ride
 *    POST /rides/:rideId/request
 *    → NO seat decrement here
 */
exports.requestRide = asyncHandler(async (req, res) => {
  const studentEmail = req.user.email;
  const { rideId }   = req.params;

  if (!studentEmail) {
    res.status(401); throw new Error('Invalid token');
  }
  if (!ObjectId.isValid(rideId)) {
    res.status(400); throw new Error('Invalid rideId');
  }

  // load & validate ride
  const ridesCol = await getOfferedRideCollection();
  const ride     = await ridesCol.findOne({ _id: new ObjectId(rideId) });
  if (!ride)                 { res.status(404); throw new Error('Ride not found'); }

  // create booking record (status: requested)
  const bookingCol = await getBookingCollection();
  const bookingDoc = {
    rideId,
    studentEmail,
    offererEmail: ride.email,
    rideDetails: {
      pickupLocation: ride.pickupLocation,
      dropLocation:   ride.dropLocation,
      date:           ride.date,
      time:           ride.time
    },
    requestedAt: new Date(),
    status:      'requested'
  };
  const { insertedId } = await bookingCol.insertOne(bookingDoc);

  // in-app notification for the offerer
  const notifCol = await getNotificationCollection();
  await notifCol.insertOne({
    userEmail: ride.email,
    relatedId: insertedId.toString(),
    message:   `${studentEmail} requested your ride on ${ride.date.toDateString()} at ${ride.time}.`,
    createdAt: new Date(),
    read:      false
  });

  // email the offerer with requester’s name & phone
  const student = await findStudentByEmail(studentEmail);
  const studentName  = student?.name  || studentEmail;
  const studentPhone = student?.phone || 'N/A';

  await sendMail(
    ride.email,
    '🔔 New Ride Request',
    `Hi there,

You have a new request for your ride:
• Route : ${ride.pickupLocation} → ${ride.dropLocation}
• When : ${ride.date.toDateString()} at ${ride.time}

Requester details:
• Name : ${studentName}
• Phone: ${studentPhone}

Please log in to accept or reject this request.

– MUJ Drive`
  );

  res.status(201).json({
    message:   'Ride request created',
    bookingId: insertedId.toString()
  });
});


/**
 * 2) Offerer lists incoming requests
 *    GET /rides/requests
 */
exports.listRequests = asyncHandler(async (req, res) => {
  const offererEmail = req.user.email;
  const ridesCol     = await getOfferedRideCollection();
  const bookingCol   = await getBookingCollection();

  const offered = await ridesCol
    .find({ email: offererEmail })
    .project({ _id: 1 })
    .toArray();
  const rideIds = offered.map(r => r._id.toString());

  const pending = await bookingCol
    .find({ rideId: { $in: rideIds }, status: 'requested' })
    .sort({ requestedAt: -1 })
    .toArray();

  res.json({ requests: pending });
});


/**
 * 3) Student views their own bookings + status
 *    GET /rides/bookings
 */
exports.listUserBookings = asyncHandler(async (req, res) => {
  const studentEmail = req.user.email;
  const bookingCol   = await getBookingCollection();

  const bookings = await bookingCol
    .find({ studentEmail })
    .project({ rideId:1, status:1, _id:0 })
    .toArray();

  res.json({ bookings });
});


/**
 * 4) Offerer accepts a booking
 *    PUT /rides/:rideId/requests/:bookingId/accept
 *    → NOW decrement seat here
 */
exports.acceptRequest = asyncHandler(async (req, res) => {
  const { rideId, bookingId } = req.params;
  const bookingCol            = await getBookingCollection();
  const ridesCol              = await getOfferedRideCollection();
  const notifCol              = await getNotificationCollection();

  // atomically decrement seat
  const rideResult = await ridesCol.findOneAndUpdate(
    { _id: new ObjectId(rideId), seatsAvailable: { $gt: 0 } },
    { $inc: { seatsAvailable: -1 } },
    { returnDocument: 'after' }
  );
  if (!rideResult.value) {
    res.status(400); throw new Error('No seats available to accept');
  }

  // mark booking accepted
  const r1 = await bookingCol.updateOne(
    { _id: new ObjectId(bookingId), rideId, status: 'requested' },
    { $set: { status: 'accepted', respondedAt: new Date() } }
  );
  if (r1.matchedCount === 0) {
    res.status(404); throw new Error('Not found or already handled');
  }

  // fetch for messaging
  const booking = await bookingCol.findOne({ _id: new ObjectId(bookingId) });
  const ride    = rideResult.value;

  // in-app notification for student
  const msg = `Your request for ride on ${ride.date.toDateString()} at ${ride.time} has been ACCEPTED.`;
  await notifCol.insertOne({
    userEmail: booking.studentEmail,
    relatedId: bookingId,
    message:   msg,
    createdAt: new Date(),
    read:      false
  });

  // email the student with full ride details & offerer’s contact
  const offerer = await findStudentByEmail(booking.offererEmail);
  const name  = offerer?.name  || booking.offererEmail;
  const phone = offerer?.phone || 'N/A';

  await sendMail(
    booking.studentEmail,
    '✅ Your Ride Request Was Accepted',
    `Hello ${booking.studentEmail},

Great news—your request for the following ride has been accepted!

Ride details:
• Route : ${ride.pickupLocation} → ${ride.dropLocation}
• When : ${ride.date.toDateString()} at ${ride.time}

Offerer details:
• Name : ${name}
• Phone: ${phone}

Please coordinate with the offerer for pickup.

– MUJ Drive`
  );

  res.json({ message: 'Booking accepted' });
});


/**
 * 5) Offerer rejects a booking
 *    PUT /rides/:rideId/requests/:bookingId/reject
 *    → NO seat increment here
 */
exports.rejectRequest = asyncHandler(async (req, res) => {
  const { rideId, bookingId } = req.params;
  const bookingCol            = await getBookingCollection();
  const notifCol              = await getNotificationCollection();
  const ridesCol              = await getOfferedRideCollection();

  // mark booking rejected
  const r1 = await bookingCol.updateOne(
    { _id: new ObjectId(bookingId), rideId, status: 'requested' },
    { $set: { status: 'rejected', respondedAt: new Date() } }
  );
  if (r1.matchedCount === 0) {
    res.status(404); throw new Error('Not found or already handled');
  }

  // fetch for messaging
  const booking = await bookingCol.findOne({ _id: new ObjectId(bookingId) });
  const ride    = await ridesCol.findOne({ _id: new ObjectId(rideId) });

  // in-app notification for student
  const msg = `Your request for ride on ${ride.date.toDateString()} at ${ride.time} was REJECTED.`;
  await notifCol.insertOne({
    userEmail: booking.studentEmail,
    relatedId: bookingId,
    message:   msg,
    createdAt: new Date(),
    read:      false
  });

  // email the student with full ride details & offerer’s contact
  const offerer = await findStudentByEmail(booking.offererEmail);
  const name  = offerer?.name  || booking.offererEmail;
  const phone = offerer?.phone || 'N/A';

  await sendMail(
    booking.studentEmail,
    '❌ Your Ride Request Was Rejected',
    `Hello ${booking.studentEmail},

We’re sorry—your request for the following ride was rejected:

Ride details:
• Route : ${ride.pickupLocation} → ${ride.dropLocation}
• When : ${ride.date.toDateString()} at ${ride.time}

Offerer details:
• Name : ${name}
• Phone: ${phone}

Feel free to search for another ride.

– MUJ Drive`
  );

  res.json({ message: 'Booking rejected' });
});


/**
 * 6) Student withdraws a pending booking
 *    PUT /rides/:rideId/requests/:bookingId/cancel
 *    → NO seat increment here
 */
exports.cancelRequest = asyncHandler(async (req, res) => {
  const { rideId, bookingId } = req.params;
  const bookingCol            = await getBookingCollection();
  const notifCol              = await getNotificationCollection();

  const booking = await bookingCol.findOne({
    _id: new ObjectId(bookingId),
    rideId,
    status: 'requested'
  });
  if (!booking) {
    res.status(400); throw new Error('Cannot cancel');
  }

  // cancel booking
  await bookingCol.updateOne(
    { _id: new ObjectId(bookingId) },
    { $set: { status: 'cancelled', respondedAt: new Date() } }
  );

  // in-app notification for offerer
  const msg = `${booking.studentEmail} withdrew their request for your ride on ${booking.rideDetails.date.toDateString()} at ${booking.rideDetails.time}.`;
  await notifCol.insertOne({
    userEmail: booking.offererEmail,
    relatedId: bookingId,
    message:   msg,
    createdAt: new Date(),
    read:      false
  });

  // email the offerer
  await sendMail(
    booking.offererEmail,
    'Ride Request Withdrawn',
    `Hello,

${msg}

– MUJ Drive`
  );

  res.json({ message: 'Booking cancelled' });
});
