const asyncHandler = require('express-async-handler');
const { verifyToken }     = require('../utils/jwt');
const { findUserById }    = require('../models/userModel');

exports.protect = asyncHandler(async (req, res, next) => {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    res.status(401);
    throw new Error('Not authorized');
  }
  const token = header.split(' ')[1];
  let decoded;
  try {
    decoded = verifyToken(token);
  } catch {
    res.status(401);
    throw new Error('Token failed');
  }
  const user = await findUserById(decoded.userId);
  if (!user) {
    res.status(404);
    throw new Error('User not found');
  }
  req.user = user;
  next();
});
