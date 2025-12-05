import { Schema, model, Document, Types } from 'mongoose';

export interface IService extends Document {
  clinic: Types.ObjectId;
  name: string;
  description?: string;
  price: number;
  durationMinutes: number;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const serviceSchema = new Schema<IService>({
  clinic: { type: Schema.Types.ObjectId, ref: 'Clinic', required: true },
  name: { type: String, required: true },
  description: { type: String },
  price: { type: Number, required: true },
  durationMinutes: { type: Number, required: true },
  isActive: { type: Boolean, default: true },
}, { timestamps: true });

export default model<IService>('Service', serviceSchema);
