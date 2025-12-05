import { Schema, model, Document, Types } from 'mongoose';

export interface IClinic extends Document {
  owner: Types.ObjectId;
  name: string;
  type: 'clinic' | 'salon';
  address: string;
  city: string;
  description?: string;
  logoUrl?: string;
  coverImageUrl?: string;
  openingTime: string;
  closingTime: string;
  slotDurationMinutes: number;
  createdAt: Date;
  updatedAt: Date;
}

const clinicSchema = new Schema<IClinic>({
  owner: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  name: { type: String, required: true },
  type: { type: String, enum: ['clinic', 'salon'], required: true },
  address: { type: String, required: true },
  city: { type: String, required: true },
  description: { type: String },
  logoUrl: { type: String },
  coverImageUrl: { type: String },
  openingTime: { type: String, required: true },
  closingTime: { type: String, required: true },
  slotDurationMinutes: { type: Number, required: true },
}, { timestamps: true });

export default model<IClinic>('Clinic', clinicSchema);
