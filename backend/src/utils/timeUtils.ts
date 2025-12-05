export function timeStringToMinutes(time: string): number {
  const [h, m] = time.split(':').map(Number);
  return h * 60 + m;
}

export function minutesToTimeString(total: number): string {
  const h = Math.floor(total / 60);
  const m = total % 60;
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
}

export function generateSlots(
  openingTime: string,
  closingTime: string,
  slotDurationMinutes: number
): string[] {
  const start = timeStringToMinutes(openingTime);
  const end = timeStringToMinutes(closingTime);

  const result: string[] = [];
  for (let t = start; t + slotDurationMinutes <= end; t += slotDurationMinutes) {
    result.push(minutesToTimeString(t));
  }
  return result;
}
