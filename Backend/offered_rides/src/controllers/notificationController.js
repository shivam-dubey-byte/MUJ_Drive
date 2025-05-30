// src/controllers/notificationController.js

const asyncHandler               = require('express-async-handler');
const { ObjectId }               = require('mongodb');
const { getNotificationCollection } = require('../models/notificationModel');

exports.listNotifications = asyncHandler(async (req, res) => {
  const { email: userEmail } = req.user;
  if (!userEmail) {
    res.status(401);
    throw new Error('Invalid token: email missing');
  }

  const col = await getNotificationCollection();
  const notifications = await col
    .find({ userEmail, read: false  })
    .sort({ createdAt: -1 })
    .toArray();

  res.json({ notifications });
});

exports.markRead = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const col = await getNotificationCollection();
  const result = await col.updateOne(
    { _id: new ObjectId(id), userEmail: req.user.email },
    { $set: { read: true } }
  );
  if (result.matchedCount === 0) {
    res.status(404);
    throw new Error('Notification not found');
  }
  res.json({ message: 'Marked as read' });
});

exports.markAllRead = asyncHandler(async (req, res) => {
  const userEmail = req.user.email;
  const col       = await getNotificationCollection();

  // set every unread → read
  await col.updateMany(
    { userEmail, read: false },
    { $set: { read: true } }
  );

  res.json({ message: 'All notifications marked read' });
});