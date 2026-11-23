// Calendars (3.12.3): CalDAV accounts (iCloud, Nextcloud, Fastmail...: read and write) and
// read-only iCal addresses (for example Google's secret iCal address). The password, or an iCal
// address that is itself a secret, never leaves the keychain. Writing to Google with OAuth is not
// part of this: a Google calendar is read through its secret iCal address.
import { z } from "zod";

export const CalendarKind = z.enum(["caldav", "ics"]);
export type CalendarKind = z.infer<typeof CalendarKind>;

/** A calendar as the page shows it: no password, and an iCal address only as its host. */
export const CalendarInfo = z.object({
  id: z.string(),
  name: z.string(),
  kind: CalendarKind,
  /** CalDAV: the collection's address. iCal: only the host (the address is a secret). */
  url: z.string(),
  user: z.string().optional(),
  /** CalDAV can be written to (always with the person's yes); an iCal address is read only. */
  writable: z.boolean(),
  /** The agents may read it (and, CalDAV, ask to write); off until the person says so. */
  agents: z.boolean().optional(),
  createdAt: z.string(),
});
export type CalendarInfo = z.infer<typeof CalendarInfo>;

export const CalendarEvent = z.object({
  uid: z.string(),
  summary: z.string(),
  /** ISO 8601; a whole-day event is a plain date (YYYY-MM-DD). */
  start: z.string(),
  end: z.string().optional(),
  allDay: z.boolean(),
  location: z.string().optional(),
  description: z.string().optional(),
  calendar: z.string().optional(),
});
export type CalendarEvent = z.infer<typeof CalendarEvent>;
