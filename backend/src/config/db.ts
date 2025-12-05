import mongoose from 'mongoose';

export async function connectDB() {
  const uri = process.env.MONGO_URI as string;
  if (!uri) throw new Error('MONGO_URI not set in environment');
  await mongoose.connect(uri);
  console.log('MongoDB connected');
}
