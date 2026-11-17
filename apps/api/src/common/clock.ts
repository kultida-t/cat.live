import { Provider } from '@nestjs/common';

/** เวลาปัจจุบันของระบบ — inject ได้เพื่อให้เทสเลื่อนเวลาข้ามการหมดอายุ/การล็อกได้ */
export const CLOCK = Symbol('CLOCK');
export type Clock = () => Date;

export const clockProvider: Provider = {
  provide: CLOCK,
  useValue: (): Date => new Date(),
};
