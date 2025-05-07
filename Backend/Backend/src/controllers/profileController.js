// src/controllers/profileController.js
const { ObjectId } = require('mongodb');
const connectDB   = require('../config/connectDB');

exports.getProfile = (req, res) => {
  const { password, ...safe } = req.profile;
  res.json({ profile: safe });
};

exports.updateProfile = async (req, res, next) => {
  try {
    const db      = await connectDB();
    const col     = req.role === 'student' ? 'student' : 'driver';
    const updates = {
      name : req.body.name,
      phone: req.body.phone,
    };

    if (req.role === 'student' && req.body.registrationNo !== undefined) {
      updates.registrationNo = req.body.registrationNo;
    }
    if (req.role === 'driver') {
      if (req.body.vehicleDetails !== undefined) updates.vehicleDetails = req.body.vehicleDetails;
      if (req.body.drivingLicense !== undefined) updates.drivingLicense = req.body.drivingLicense;
    }

    await db
      .collection(col)
      .updateOne({ _id: new ObjectId(req.profile._id) }, { $set: updates });

    const updated = await db
      .collection(col)
      .findOne({ _id: new ObjectId(req.profile._id) });

    const { password, ...safe } = updated;
    res.json({ profile: safe });
  } catch (err) {
    next(err);
  }
};
