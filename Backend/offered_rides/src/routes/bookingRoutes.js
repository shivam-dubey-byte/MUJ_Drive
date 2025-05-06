// src/routes/bookingRoutes.js
const express            = require('express');
const authMiddleware     = require('../middleware/authMiddleware');
const { requestRide }    = require('../controllers/bookingController');

const router = express.Router();

// POST /rides/:rideId/request
router.post('/:rideId/request', authMiddleware, requestRide);

module.exports = router;
