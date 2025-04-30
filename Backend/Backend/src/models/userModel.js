const { ObjectId } = require('mongodb');
const bcrypt = require('bcryptjs');
const connectDB = require('../config/connectDB');

const createUser = async (name, email, password, role, profile) => {
  const db = await connectDB();
  const users = db.collection('users');
  const hashed = await bcrypt.hash(password, 10);
  const { insertedId } = await users.insertOne({ name, email, password: hashed, role, profile });
  return insertedId;
};

const findUserByEmail = async (email) => {
  const db = await connectDB();
  return db.collection('users').findOne({ email });
};

const comparePassword = async (plain, hash) => {
  return bcrypt.compare(plain, hash);
};

const findUserById = async (id) => {
  const db = await connectDB();
  return db.collection('users').findOne({ _id: new ObjectId(id) });
};

const updatePassword = async (id, newPass) => {
  const db = await connectDB();
  const hashed = await bcrypt.hash(newPass, 10);
  return db.collection('users').updateOne(
    { _id: new ObjectId(id) },
    { $set: { password: hashed } }
  );
};

module.exports = {
  createUser,
  findUserByEmail,
  comparePassword,
  findUserById,
  updatePassword
};
