// models/driverDataModel.js

const { getClient } = require('../config/connectDB');

// Add a new driver to driverdata collection in Users DB (Enhanced Version)
async function addNewDriverData(name, phone) {
  try {
    const client = await getClient();
    const usersDb = client.db('Users');
    const driverCollection = usersDb.collection('driverdata');
    
    // Check if the driver already exists by phone number
    const existingDriver = await driverCollection.findOne({ phone });
    if (existingDriver) {
      throw new Error("A driver with this phone number already exists.");
    }

    // Insert the new driver
    const newDriver = { name, phone };
    await driverCollection.insertOne(newDriver);
    return newDriver;
  } catch (error) {
    console.error("Error in addNewDriverData:", error.message);
    throw new Error("Failed to add driver. " + error.message);
  }
}

// Fetch all drivers from driverdata collection
async function getAllDriverData() {
  try {
    const client = await getClient();
    const usersDb = client.db('Users');
    const driverCollection = usersDb.collection('driverdata');
    return await driverCollection.find().toArray();
  } catch (error) {
    console.error("Error in getAllDriverData:", error.message);
    throw new Error("Failed to fetch drivers. " + error.message);
  }
}

module.exports = { addNewDriverData, getAllDriverData };
