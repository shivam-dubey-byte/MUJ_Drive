const express           = require('express');
const { offerRide }     = require('../controllers/offeredRideController');
const authMiddleware    = require('../middleware/authMiddleware');

const router = express.Router();

// protected route – token in Authorization: Bearer <token>
router.post('/offer-ride', authMiddleware, offerRide);

module.exports = router;
