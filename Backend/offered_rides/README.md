# Rides Service

Provides an endpoint to offer rides.  
Reads user email from JWT, then stores ride details in the `rides.offeredride` collection.

## Setup

1. Copy `.env.example` → `.env`, set `MONGO_URI` & `JWT_SECRET`
2. `npm install`
3. `npm run dev`

## Endpoints

- **POST** `/rides/offer-ride`  
  **Headers**: `Authorization: Bearer <token>`  
  **Body**:
  ```json
  {
    "pickupLocation": "MUJ",
    "dropLocation":   "JAI",
    "date":           "2025-05-10",
    "time":           "14:30",
    "totalSeats":     4,
    "seatsAvailable": 3,
    "luggage": {
      "small":  1,
      "medium": 0,
      "large":  2
    }
  }
