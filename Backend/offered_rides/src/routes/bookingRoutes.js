// src/routes/bookingRoutes.js

const express        = require('express');
const authMiddleware = require('../middleware/authMiddleware');
const {
  requestRide,
  listRequests,
  listUserBookings,
  acceptRequest,
  rejectRequest,
  cancelRequest
} = require('../controllers/bookingController');

const router = express.Router();

// 1. Student books a ride
router.post('/:rideId/request',                   authMiddleware, requestRide);

// 2. Offerer lists incoming requests
router.get('/requests',                            authMiddleware, listRequests);

// 3. Student views their own bookings + status
router.get('/bookings',                            authMiddleware, listUserBookings);

// 4. Offerer accepts a booking
router.put('/:rideId/requests/:bookingId/accept',  authMiddleware, acceptRequest);

// 5. Offerer rejects a booking
router.put('/:rideId/requests/:bookingId/reject',  authMiddleware, rejectRequest);

// 6. Student cancels a pending booking
router.put('/:rideId/requests/:bookingId/cancel',  authMiddleware, cancelRequest);

module.exports = router;
