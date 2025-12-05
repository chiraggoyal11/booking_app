
import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import { connectDB } from './config/db';

import authRoutes from './routes/auth.routes';
import clinicRoutes from './routes/clinic.routes';
import serviceRoutes from './routes/service.routes';
import { errorHandler } from './middleware/errorHandler';
import bookingRoutes from './routes/booking.routes';
import adminRoutes from './routes/admin.routes';

const app = express();

app.use(cors({ origin: process.env.CLIENT_URL, credentials: true }));
app.use(express.json());


app.use('/api/auth', authRoutes);
app.use('/api/clinic', clinicRoutes);
app.use('/api/services', serviceRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/admin', adminRoutes);

app.use(errorHandler);

const PORT = process.env.PORT || 5000;

connectDB()
  .then(() => {
    app.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
    });
  })
  .catch((err) => {
    console.error('DB connection failed', err);
    process.exit(1);
  });
