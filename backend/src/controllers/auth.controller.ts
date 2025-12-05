import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import User from '../models/User';
import { ok, errorRes } from '../utils/sendResponse';

export async function register(req: Request, res: Response) {
  try {
    const { name, email, password, phone, role } = req.body;
    if (!name || !email || !password || !role) {
      return errorRes(res, 'All fields are required', 400);
    }
    const existing = await User.findOne({ email });
    if (existing) return errorRes(res, 'Email already used', 409);
    const hash = await bcrypt.hash(password, 10);
    const user = await User.create({ name, email, phone, role, passwordHash: hash });
    return ok(res, { userId: user._id }, 201);
  } catch (err) {
    return errorRes(res, 'Server error', 500);
  }
}

export async function login(req: Request, res: Response) {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return errorRes(res, 'Email and password are required', 400);
    }
    const user = await User.findOne({ email });
    if (!user) return errorRes(res, 'Invalid credentials', 400);
    const okPass = await bcrypt.compare(password, user.passwordHash);
    if (!okPass) return errorRes(res, 'Invalid credentials', 400);
    const token = jwt.sign(
      { userId: user._id, role: user.role },
      process.env.JWT_SECRET as string,
      { expiresIn: '7d' }
    );
    return ok(res, {
      token,
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
        role: user.role
      }
    });
  } catch (err) {
    return errorRes(res, 'Server error', 500);
  }
}
