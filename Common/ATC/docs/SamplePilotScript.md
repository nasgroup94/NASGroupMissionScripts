# Sample Pilot Script — Full Flight, Cold Start to Shutdown

A line-by-line walkthrough of everything a pilot says (and roughly what ATC
says back) to exercise the complete NASG_ATC chain: Clearance → Ground →
Tower → Center → Tower → Ground. Every pilot line below uses a phrase
confirmed to route to a real, implemented handler as of this session (see
`Common/ATC/ATC_Command_Reference.txt` for the full command list).

Scenario: Nellis (NTTR), callsign **Hammer 1-1**, cold-starting on the ramp,
flying the real registered "Dream Four" departure out and the real
registered "Strike" recovery back home. These two procedures are the only
ones in `Nellis_ATC_Procedures.lua` that are actually registered under
`AirportId = "nellis"` with aliases matching the user's requested phrasing
("Dream 4" → alias `Dream4`; "Strike" → `Strike`/`Strike One`) — this is why
the script uses Nellis rather than Persian Gulf/Al Minhad, whose procedures
file (`Persian_Gulf_ATC_Procedures.lua`) currently has no procedures
registered at all, only commented-out examples.

Frequencies (from `ATC_Command_Reference.txt`, Nellis):
- Clearance — 120.900 AM — "Nellis Clearance"
- Ground — 121.800 AM — "Nellis Ground"
- Tower — 327.100 AM — "Nellis Tower"
- Center/Approach — 239.400 AM — "Nellis Approach"
- ATIS — 270.100 AM — "Nellis Information"

**IMPORTANT — retune your SRS radio at every handoff.** Dispatch is driven
by which frequency you're actually transmitting on (`event.facility`), not
by any internal state tracking. Saying the right words on the wrong
frequency will not route to the right controller. Every "contact X" below
means: tune your radio to X's frequency before making your next call.

---

## 1. Cold start

Listen to Nellis Information (270.100) first and note the ATIS letter — the
script below assumes it's currently **Information Bravo**. Startup/taxi
checks require you to state the current letter; substitute whatever letter
is actually live in your session.

**Pilot → Ground (121.800):**
> "Nellis Ground, Hammer One One, request startup, information Bravo."

**Ground:** checks ATIS, approves engine start, expects a taxi request next.

---

## 1a. Optional — forgot to rename your DCS slot?

If your client slot spawned with a mission-editor name instead of your
intended callsign, fix it now (before Clearance, so the readback and every
later facility already use it) — say this on Ground:

**Pilot → Ground (121.800):**
> "Nellis Ground, set callsign as Hammer One One."

**Ground:**
> "Copy, Hammer One One, callsign updated."

Every facility below now addresses you as Hammer 1-1, and flight-plan
lookups use the new callsign too. This is voice-only — the F10 "ATC Status"
menu can only clear an alias, not set one. The rest of this script assumes
you're already correctly named and skips this step.

---

## 2. Clearance

**Pilot → Clearance (120.900):**
> "Nellis Clearance, Hammer One One, request Dream Four departure to Student
> Gap."

**Clearance:** looks up "Dream Four" (matches the registered `dream_four_departure`
procedure via its `Dream4` alias), attaches it as your assigned route with
"Student Gap" carried as free-text destination, assigns a squawk, and reads
back something like:
> "Hammer One One, cleared to Student Gap, Dream Four departure, squawk 4321."

**Pilot readback:**
> "Cleared to Student Gap, Dream Four departure, squawk 4321, Hammer One
> One."

Clearance validates the squawk and the procedure name in your readback and
confirms. You're now transferred back to Ground procedurally, but you're
already on Ground's frequency from step 1.

**If you're flying as part of a package** (callsign fits
`<STEM><FLIGHT><POSITION>`, e.g. Hammer 1-1/1-2/1-3/1-4 as "HAMMER11" through
"HAMMER14"), only one member needs to do the above — once any one of you has
a clearance on file, the rest are told:
> "Hammer One Two, you're already covered under Hammer One One's clearance
> for your package. Contact Ground when ready."
instead of getting a duplicate one. Ground and Tower still handle each jet
individually for taxi/takeoff.

---

## 3. Taxi

Nellis requires you to state your parking location in the same call as your
taxi request (`RequireParkingLocation` in `Nellis_ATC_Airports.lua`) — you
spawned cold on the ramp in step 1, so that's "west ramp":

**Pilot → Ground (121.800):**
> "Nellis Ground, Hammer One One, ready to taxi, west ramp."

If you omit it, Ground holds the clearance and asks for it instead:
> "Hammer One One, say your parking location."
Say it ("west ramp", or one of the EOR names — "south eor", "northeast eor",
etc. — if you'd spawned hot at one of those instead) and Ground proceeds.

**Ground:** verifies ATIS, resolves your stated parking location, and issues
a taxi route to the active runway, e.g.:
> "Hammer One One, taxi to runway 21 via Alpha, Bravo, hold short runway 21,
> contact Tower 327.1 when ready."

**Pilot readback:**
> "Taxi to runway 21 via Alpha, Bravo, hold short runway 21, contact Tower
> 327.1, Hammer One One."

Follow the taxi route. If you cross a runway along the way, Ground's
periodic crossing recheck will re-clear you automatically as you approach
it — no separate call needed unless it tells you to hold.

When you reach the hold-short line:

**Pilot → Ground (121.800):**
> "Hammer One One, holding short runway 21, ready for departure."

**Ground:** hands you to Tower.
> "Hammer One One, contact Tower 327.1."

---

## 4. Tower — departure

**Pilot → Tower (327.100):**
> "Nellis Tower, Hammer One One, holding short runway 21, ready for
> departure."

Tower assesses runway traffic and issues one of:

- **Continue to hold** (traffic on the runway) — wait and it will reassess.
- **Line up and wait:**
  > "Hammer One One, runway 21, line up and wait."

  **Pilot readback (optional, doesn't block the flow):**
  > "Line up and wait runway 21, Hammer One One."

- **Cleared for takeoff** (this is also the message you'll eventually get
  after LUAW clears):
  > "Hammer One One, climb and maintain 1 7 thousand, runway 21, cleared for
  > takeoff, contact Nellis Approach 239.4 when airborne."

**Pilot readback (required):**
> "Climb and maintain 1 7 thousand, runway 21, cleared for takeoff, Hammer
> One One."

Takeoff. Once airborne, retune to Center per the instruction embedded in the
takeoff clearance itself — no separate handoff call needed.

---

## 5. Center — outbound

**Pilot → Center (239.400, "Nellis Approach"):**
> "Nellis Approach, Hammer One One, checking in, 10 west of Nellis, climbing
> through 5 thousand for 1 7 thousand."

**Center:** radar contact, reports your live altitude, and reassigns/confirms
the climb altitude (your stated goal, or the flight plan's active-leg
altitude if you have one on file):
> "Hammer One One, radar contact, climb and maintain 1 7 thousand."

**Pilot readback:**
> "Climb and maintain 1 7 thousand, Hammer One One."

Because you have the Dream Four route attached from Clearance, Center will
also structurally sanity-check the remaining route legs and tell you if one
doesn't resolve (not expected here).

**Established on the departure radial:** off runway 21, Dream Four's first
leg is a turn to intercept LAS VORTAC R-350 outbound (runway 3 would instead
be BLD R-346 — see `Nellis_ATC_Procedures.lua`). Report it once you're on
it, rather than waiting to be asked:
> "Nellis Approach, Hammer One One, established on the 350 radial."

Center checks this against the leg's actual target radial (not the number
you spoke — STT mis-hears are tolerated) and replies:
> "Roger, radar contact on LAS R-350."
(or "negative, N degrees left/right of LAS R-350" if you're actually off
it, or "unable" if no radial leg is currently active). You then continue
via MINTT toward Dream.

**Optional along the route — request a tanker:**
> "Nellis Approach, Hammer One One, request tanker."

Center replies with a vector, TACAN, and frequency to the nearest active
tanker.

**Optional — request a specific tanker by name:** Nellis registers its
tanker AUFTRAGs (Jade, Coral, Pearl, Topaz, Onyx, Amber — see
`Nellis_AFB.lua`'s `NASG_ATC:AddAssets(NellisAW)`) as live named assets, not
static points, so you can ask for one specifically instead of taking
whichever is nearest:
> "Nellis Approach, Hammer One One, request vector to Jade."

Center replies with a current bearing/range to whichever aircraft is
actually flying the Jade tanker mission right now, plus its real TACAN
channel and radio frequency — this keeps working across respawns since it's
tied to the mission, not one spawned unit's name.

**Optional — request a specific point:**
> "Nellis Approach, Hammer One One, request vector to Bullseye."

---

## 6. Center — recovery

**Pilot → Center (239.400):**
> "Nellis Approach, Hammer One One, request Strike recovery to home plate."

"Strike" matches the registered `strike_recovery` procedure; "home plate" is
the alias added this session to `request_recovery` specifically to support
this phrasing. Center attaches the Strike recovery route, assigns a **new**
squawk (independent of your outbound squawk — same shared pool Clearance
uses), and vectors you to the first leg of the return route:

> "Hammer One One, cleared Strike recovery, squawk 5432, vector 240 for 15
> miles to Dreamland Entry, descend and maintain 1 0 thousand."

**Pilot readback:**
> "Squawk 5432, descend and maintain 1 0 thousand, Hammer One One."

You remain on Center's frequency — **do not retune yet**. A background
check now runs every ~15 seconds watching your distance to Nellis. There is
no further pilot call needed for the handoff; when you cross 10 NM from the
field, Center automatically flips you to Tower and transmits:

> "Hammer One One, contact Tower 327.1."

Retune to Tower at that point.

---

## 7. Tower — recovery

Pick one of the two supported inbound intents and include the current ATIS
letter (assume it's rolled to **Information Charlie** by now):

**Overhead:**
> "Nellis Tower, Hammer One One, inbound overhead, information Charlie."

**— or straight-in:**
> "Nellis Tower, Hammer One One, straight in, information Charlie."

Tower checks your stated ATIS letter against the live one; if it's stale
you'll get "verify you have current airport information, Information X is
current" instead of a clearance — say the current letter back and try
again.

**Tower (overhead example):**
> "Hammer One One, information Charlie current, enter initial runway 21,
> pattern altitude 1500, report initial."

**— or (straight-in example):**
> "Hammer One One, information Charlie current, cleared straight in runway
> 21, pattern altitude 1500, report initial."

Fly the entry. Report as you go:

> "Hammer One One, initial."
→ "Break approved, report downwind."

> "Hammer One One, downwind."
→ landing clearance with wind.

> "Hammer One One, final."
→ "Cleared to land."

Land. **On touchdown you're switched to Ground automatically** (this
session's new auto-handoff) — no "clear of runway" call is required,
though saying it is harmless (treated as a no-op if you're already
transferred).

---

## 8. Ground — post-land

Retune to 121.800. State your exit ramp as flavor/position callout and your
intention — Ground routes you by your actual detected position, not by
parsing the ramp name, so this is descriptive rather than a required
parse target:

**Taxi to the line (parking):**
> "Nellis Ground, Hammer One One, clear of the runway at Bravo, taxi to
> line."

**— or hot refuel:**
> "Nellis Ground, Hammer One One, clear of the runway at Bravo, hot
> refuel."

**— or rearm:**
> "Nellis Ground, Hammer One One, clear of the runway at Bravo, rearm."

Ground routes you to parking or the maintenance/rearm ramp accordingly.

---

## 9. Shutdown

**Pilot → Ground (121.800):**
> "Nellis Ground, Hammer One One, request shutdown."

**Ground:**
> "Hammer One One, shutdown approved. Good day."

End of flight.

---

## Notes / deliberate simplifications

- **Nellis parses your stated parking location; other fields may not.**
  Nellis sets `RequireParkingLocation = true` and resolves what you say
  ("west ramp", "south eor", ...) to a real taxi origin via
  `ParkingLocations` in `Nellis_ATC_Airports.lua` — say the wrong one and
  you'll be routed from the wrong place. Fields that don't set this flag
  fall back to purely spatial detection (nearest node to your actual
  coordinate), where exit-ramp call-outs are cosmetic flavor text only.
- **Callsign alias is session-scoped.** "Set callsign as X" only lasts
  until you respawn into a different DCS slot — it's meant to fix a
  forgot-to-rename mistake for the current sortie, not to persist across
  sessions.
- **Package-flight clearance sharing is Clearance-only, v1.** Only the "has
  this package already talked to Clearance" gate is shared across package
  members; Ground/Tower still issue taxi and takeoff clearances to each jet
  individually.
- **Named recovery/departure routes must be pre-registered.** "Dream Four"
  and "Strike" work because they're defined in `Nellis_ATC_Procedures.lua`.
  A destination like "Student Gap" or "home plate" does not need to be a
  registered point — it's carried as free text for the readback exchange
  only.
- **Frequency retuning is mandatory at every handoff** — see the callout at
  the top. This is a hard architectural constraint (`HandleSpeechEvent`
  dispatches on the frequency you transmitted on), not a suggestion.
- This script is code-complete and every referenced file passed
  `luac5.1 -p` syntax validation this session, but the full flow has **not
  been flown live in DCS** — no live session was available to verify actual
  voice-intent dispatch, timing of the 10 NM auto-handoff, or TTS phrasing
  end to end.
