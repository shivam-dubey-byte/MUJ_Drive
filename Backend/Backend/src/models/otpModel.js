const { ObjectId } = require('mongodb');
const connectDB = require('../config/connectDB');

async function saveOTP(email, otp, expiresAt) {
  console.log(email);
  const db = await connectDB();
  const otps = db.collection('otps');
  await otps.deleteMany({ email });
  await otps.insertOne({ email, otp, expiresAt, verified: false });
}

async function getOTPRecord(email) {
  const db = await connectDB();
  return db.collection('otps').findOne({ email });
}

async function verifyOTPRecord(email) {
  const db = await connectDB();
  await db.collection('otps').updateOne({ email }, { $set: { verified: true } });
}

async function deleteOTPRecord(email) {
  const db = await connectDB();
  await db.collection('otps').deleteMany({ email });
}

module.exports = {
  saveOTP,
  getOTPRecord,
  verifyOTPRecord,
  deleteOTPRecord
};
