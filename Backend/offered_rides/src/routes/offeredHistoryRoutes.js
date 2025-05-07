const express                      = require('express');
const authMiddleware               = require('../middleware/authMiddleware');
const { getOfferedRidesWithUsers } = require('../controllers/offeredHistoryController');

const router = express.Router();

// GET /rides/offered-history
router.get('/offered-history', authMiddleware, getOfferedRidesWithUsers);

module.exports = router;
