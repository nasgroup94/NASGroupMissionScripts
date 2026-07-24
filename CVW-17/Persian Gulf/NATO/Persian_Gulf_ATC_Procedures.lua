NASG_ATC = NASG_ATC or {}

---------------------------------------------------------------------------
-- Named navigation procedures (SID/STAR-style).
--
-- An ordered list of points (referencing Persian_Gulf_ATC_TrackedPoints.lua
-- entries by name, or inline point tables) a pilot can request as a unit
-- from Clearance Delivery, e.g. "request Dream departure". Edit this list
-- to add/remove procedures for your mission.
--
-- Type is "departure" or "recovery". AirportId scopes the procedure to one
-- airport's Clearance/Center; omit it if the procedure applies map-wide.
---------------------------------------------------------------------------

-- Example: a departure procedure built from two tracked points registered
-- in Persian_Gulf_ATC_TrackedPoints.lua.
-- NASG_ATC:RegisterProcedure({
--     Id = "dream_departure",
--     Name = "Dream",
--     Type = "departure",
--     AirportId = "al_minhad",
--     Points = { "texaco", "bullseye" },
-- })

-- Example: a recovery procedure with an alias.
-- NASG_ATC:RegisterProcedure({
--     Id = "strike_recovery",
--     Name = "Strike",
--     Type = "recovery",
--     AirportId = "al_minhad",
--     Aliases = { "Strike One" },
--     Points = { "range_entry", "bullseye" },
-- })

NASG_ATC:Log("Persian Gulf ATC procedures loaded")
