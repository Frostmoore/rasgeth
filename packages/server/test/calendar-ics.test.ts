import { describe, expect, it } from "vitest";
import { buildIcs, eventsBetween, parseIcs } from "../src/calendar/ics.js";
import { calendarData } from "../src/calendar/service.js";

const day = (s: string) => new Date(`${s}T00:00:00Z`);

const FEED = [
  "BEGIN:VCALENDAR",
  "VERSION:2.0",
  "BEGIN:VEVENT",
  "UID:one@x",
  "DTSTART:20261125T090000Z",
  "DTEND:20261125T100000Z",
  "SUMMARY:Dentist\\, Dr. Rossi",
  "LOCATION:Via Roma 1",
  "DESCRIPTION:Bring the card\\nand the X-rays that were",
  "  taken last year",
  "END:VEVENT",
  "BEGIN:VEVENT",
  "UID:two@x",
  "DTSTART;VALUE=DATE:20261126",
  "DTEND;VALUE=DATE:20261128",
  "SUMMARY:Trip",
  "BEGIN:VALARM",
  "TRIGGER:-PT15M",
  "END:VALARM",
  "END:VEVENT",
  "BEGIN:VEVENT",
  "UID:three@x",
  "DTSTART;TZID=Europe/Rome:20261125T180000",
  "DURATION:PT90M",
  "SUMMARY:Dinner",
  "END:VEVENT",
  "END:VCALENDAR",
].join("\r\n");

describe("iCalendar reading", () => {
  it("reads timed, whole-day and zoned events, unfolding and unescaping", () => {
    const r = parseIcs(FEED);
    expect(r.map((e) => e.uid)).toEqual(["one@x", "two@x", "three@x"]);
    expect(r[0]?.summary).toBe("Dentist, Dr. Rossi");
    expect(r[0]?.description).toBe("Bring the card\nand the X-rays that were taken last year");
    expect(r[1]?.allDay).toBe(true);
    // Rome is one hour ahead of UTC in November: 18:00 local is 17:00Z, for 90 minutes.
    expect(r[2]?.start.toISOString()).toBe("2026-11-25T17:00:00.000Z");
    expect(r[2]?.end?.toISOString()).toBe("2026-11-25T18:30:00.000Z");
  });

  it("lists the events of a range, soonest first, and keeps the alarm out of the event", () => {
    const ev = eventsBetween(parseIcs(FEED), day("2026-11-25"), day("2026-11-27"), "Home");
    expect(ev.map((e) => e.summary)).toEqual(["Dentist, Dr. Rossi", "Dinner", "Trip"]);
    expect(ev[0]).toMatchObject({
      start: "2026-11-25T09:00:00.000Z",
      calendar: "Home",
      location: "Via Roma 1",
    });
    expect(ev[2]).toMatchObject({ start: "2026-11-26", allDay: true });
    expect(eventsBetween(parseIcs(FEED), day("2026-12-01"), day("2026-12-02"))).toEqual([]);
  });

  it("expands weekly rules with a count, an exception and BYDAY", () => {
    const text = [
      "BEGIN:VCALENDAR",
      "BEGIN:VEVENT",
      "UID:w@x",
      "DTSTART:20261102T080000Z",
      "DTEND:20261102T090000Z",
      "RRULE:FREQ=WEEKLY;COUNT=4;BYDAY=MO,WE",
      "EXDATE:20261111T080000Z",
      "SUMMARY:Gym",
      "END:VEVENT",
      "END:VCALENDAR",
    ].join("\n");
    const ev = eventsBetween(parseIcs(text), day("2026-11-01"), day("2026-12-31"));
    // Monday 2 and Wednesday 4, then 9 and 11: the 11th is an exception; the count is 4 in all.
    expect(ev.map((e) => e.start.slice(0, 10))).toEqual(["2026-11-02", "2026-11-04", "2026-11-09"]);
  });

  it("expands a daily rule up to its until date and a monthly one", () => {
    const text = (rule: string) =>
      [
        "BEGIN:VEVENT",
        "UID:r",
        "DTSTART:20261120T100000Z",
        `RRULE:${rule}`,
        "SUMMARY:R",
        "END:VEVENT",
      ].join("\n");
    expect(
      eventsBetween(
        parseIcs(text("FREQ=DAILY;UNTIL=20261123T235959Z")),
        day("2026-11-01"),
        day("2026-12-01"),
      ),
    ).toHaveLength(4);
    expect(
      eventsBetween(
        parseIcs(text("FREQ=MONTHLY;INTERVAL=2")),
        day("2026-11-01"),
        day("2027-06-01"),
      ).map((e) => e.start.slice(0, 10)),
    ).toEqual(["2026-11-20", "2027-01-20", "2027-03-20", "2027-05-20"]);
  });

  it("ignores what is not an event and what has no start", () => {
    expect(parseIcs("BEGIN:VCALENDAR\nBEGIN:VTODO\nSUMMARY:x\nEND:VTODO\nEND:VCALENDAR")).toEqual(
      [],
    );
    expect(parseIcs("BEGIN:VEVENT\nUID:a\nSUMMARY:no start\nEND:VEVENT")).toEqual([]);
    expect(parseIcs("nonsense")).toEqual([]);
  });
});

describe("iCalendar writing", () => {
  const now = new Date("2026-11-23T10:00:00Z");

  it("builds a timed event the reader reads back, with escapes", () => {
    const text = buildIcs(
      {
        uid: "u1@redgiant",
        summary: "Lunch; with Anna, Bob",
        start: "2026-11-27T12:00:00Z",
        end: "2026-11-27T13:30:00Z",
        allDay: false,
        location: "Bar",
      },
      now,
    );
    expect(text).toContain("BEGIN:VCALENDAR\r\n");
    expect(text).toContain("DTSTAMP:20261123T100000Z");
    const [e] = parseIcs(text);
    expect(e).toMatchObject({
      uid: "u1@redgiant",
      summary: "Lunch; with Anna, Bob",
      location: "Bar",
      allDay: false,
    });
    expect(e?.start.toISOString()).toBe("2026-11-27T12:00:00.000Z");
    expect(e?.end?.toISOString()).toBe("2026-11-27T13:30:00.000Z");
  });

  it("an event with no end lasts an hour; a whole-day one ends the day after its last day", () => {
    const [a] = parseIcs(
      buildIcs({ uid: "a", summary: "A", start: "2026-11-27T12:00:00Z", allDay: false }, now),
    );
    expect(a?.end?.toISOString()).toBe("2026-11-27T13:00:00.000Z");
    const text = buildIcs(
      { uid: "b", summary: "B", start: "2026-12-24", end: "2026-12-26", allDay: true },
      now,
    );
    expect(text).toContain("DTSTART;VALUE=DATE:20261224");
    expect(text).toContain("DTEND;VALUE=DATE:20261227");
  });

  it("folds long lines at 75 characters", () => {
    const text = buildIcs(
      { uid: "c", summary: "x".repeat(300), start: "2026-11-27T12:00:00Z", allDay: false },
      now,
    );
    for (const l of text.split("\r\n")) expect(l.length).toBeLessThanOrEqual(75);
    expect(parseIcs(text)[0]?.summary).toBe("x".repeat(300));
  });
});

describe("CalDAV answers", () => {
  it("takes the calendar objects out of a multistatus, any prefix, entities and CDATA", () => {
    const xml = `<?xml version="1.0"?><d:multistatus xmlns:d="DAV:" xmlns:C="urn:ietf:params:xml:ns:caldav">
<d:response><d:propstat><d:prop><C:calendar-data>BEGIN:VCALENDAR&#13;
SUMMARY:A &amp; B
END:VCALENDAR</C:calendar-data></d:prop></d:propstat></d:response>
<d:response><d:propstat><d:prop><cal:calendar-data><![CDATA[BEGIN:VCALENDAR
SUMMARY:C
END:VCALENDAR]]></cal:calendar-data></d:prop></d:propstat></d:response></d:multistatus>`;
    const out = calendarData(xml);
    expect(out).toHaveLength(2);
    expect(out[0]).toContain("SUMMARY:A & B");
    expect(out[1]).toContain("SUMMARY:C");
  });
});
