// src/middleware/profileAuth.js
const asyncHandler   = require('express-async-handler');
const { verifyToken } = require('../utils/jwt');
const { findStudentById } = require('../models/studentModel');
const { findDriverById }  = require('../models/driverModel');

exports.protectProfile = asyncHandler(async (req, res, next) => {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    res.status(401);
    throw new Error('Not authorized');
  }
  const token = header.split(' ')[1];
  let payload;
  try {
    payload = verifyToken(token);
  } catch {
    res.status(401);
    throw new Error('Token invalid or expired');
  }

  if (payload.role === 'student') {
    req.profile = await findStudentById(payload.userId);
    req.role    = 'student';
  } else {
    req.profile = await findDriverById(payload.userId);
    req.role    = 'driver';
  }

  if (!req.profile) {
    res.status(404);
    throw new Error('Profile not found');
  }

  next();
});
