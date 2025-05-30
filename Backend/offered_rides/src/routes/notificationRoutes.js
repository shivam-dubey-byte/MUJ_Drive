// src/routes/notificationRoutes.js

const express                = require('express');
const authMiddleware         = require('../middleware/authMiddleware');
const {
  listNotifications,
  markRead,
  markAllRead
} = require('../controllers/notificationController');

const router = express.Router();

// GET  /notifications            → list all for the logged-in user
// PUT  /notifications/:id/read  → mark one as read
router.get('/',       authMiddleware, listNotifications);
router.put('/:id/read', authMiddleware, markRead);
router.put('/read-all',    authMiddleware, markAllRead);

module.exports = router;
