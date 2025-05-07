// src/routes/profileRoutes.js
const express            = require('express');
const { protectProfile } = require('../middleware/profileAuth');
const { getProfile, updateProfile } = require('../controllers/profileController');

const router = express.Router();

router.get('/', protectProfile, getProfile);
router.put('/', protectProfile, updateProfile);

module.exports = router;
