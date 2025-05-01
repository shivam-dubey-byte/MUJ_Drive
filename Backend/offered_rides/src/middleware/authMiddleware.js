const asyncHandler = require('express-async-handler');
const { verifyToken } = require('../utils/jwt');

const authMiddleware = asyncHandler(async (req, res, next) => {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    res.status(401);
    throw new Error('No token provided');
  }
  const token = header.split(' ')[1];
  try {
    const decoded = verifyToken(token);
    // decoded must include { email, ... }
    req.user = decoded;
    next();
  } catch {
    res.status(401);
    throw new Error('Invalid token');
  }
});

module.exports = authMiddleware;
