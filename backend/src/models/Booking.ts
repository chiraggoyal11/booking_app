import { Schema, model, Document, Types } from 'mongoose';

export interface IBooking extends Document {
  clinic: Types.ObjectId;
  customer: Types.ObjectId;
  service: Types.ObjectId;
  date: string;
  startTime: string;
  endTime: string;
  status: 'pending' | 'confirmed' | 'completed' | 'cancelled';
  notes?: string;
  createdAt: Date;
  updatedAt: Date;
}

const bookingSchema = new Schema<IBooking>({
  clinic: { type: Schema.Types.ObjectId, ref: 'Clinic', required: true },
  customer: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  service: { type: Schema.Types.ObjectId, ref: 'Service', required: true },
  date: { type: String, required: true },
  startTime: { type: String, required: true },
  endTime: { type: String, required: true },
  status: { type: String, enum: ['pending', 'confirmed', 'completed', 'cancelled'], default: 'pending' },
  notes: { type: String },
}, { timestamps: true });

export default model<IBooking>('Booking', bookingSchema);
