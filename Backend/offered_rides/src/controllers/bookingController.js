// src/controllers/bookingController.js
const asyncHandler = require('express-async-handler');
const { ObjectId } = require('mongodb');
const { getOfferedRideCollection } = require('../models/offeredRideModel');
const { getBookingCollection }     = require('../models/bookingModel');
const { getNotificationCollection }= require('../models/notificationModel');
const { sendMail }                = require('../mail/mailService');

exports.requestRide = asyncHandler(async (req, res) => {
  // 1) who is booking?
  const { email: studentEmail } = req.user;
  if (!studentEmail) {
    res.status(401);
    throw new Error('Invalid token: email missing');
  }

  // 2) find the ride
  const rideId = req.params.rideId;
  const ridesCol = await getOfferedRideCollection();
  const ride = await ridesCol.findOne({ _id: new ObjectId(rideId) });
  if (!ride) {
    res.status(404);
    throw new Error('Ride not found');
  }
  if (ride.seatsAvailable < 1) {
    res.status(400);
    throw new Error('No seats available');
  }

  // 3) decrement seats
  await ridesCol.updateOne(
    { _id: new ObjectId(rideId) },
    { $inc: { seatsAvailable: -1 } }
  );

  // 4) record the booking
  const bookingCol = await getBookingCollection();
  const bookingDoc = {
    rideId,
    studentEmail,
    requestedAt: new Date(),
    status:      'requested'
  };
  const { insertedId: bookingId } = await bookingCol.insertOne(bookingDoc);

  // 5) record the notification
  const notifCol = await getNotificationCollection();
  const notifDoc = {
    userEmail: ride.email,   // from the offer‐ride doc
    message:   `Your ride on ${ride.date.toDateString()} at ${ride.time} got a new request from ${studentEmail}.`,
    createdAt: new Date(),
    read:      false
  };
  await notifCol.insertOne(notifDoc);

  // 6) fire off an email via your auth mailer
  await sendMail(
    ride.email,
    'New ride request',
    `Hi,\n\nYour ride scheduled for ${ride.date.toDateString()} at ${ride.time} has a new request from ${studentEmail}.\n\n— MUJ Drive`
  );

  // 7) respond
  res.status(201).json({
    message:   'Ride requested successfully',
    bookingId
  });
});
