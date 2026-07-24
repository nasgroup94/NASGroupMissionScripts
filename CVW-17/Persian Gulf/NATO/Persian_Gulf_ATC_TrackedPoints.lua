NASG_ATC = NASG_ATC or {}

---------------------------------------------------------------------------
-- Center-tracked points.
--
-- Named locations pilots can request a vector to that aren't flight-plan
-- waypoints: tankers, AWACS stations, bullseye, objectives, range entry
-- points, etc. Edit this list to add/remove points for your mission.
--
-- Exactly one location method per point (checked in this priority order
-- if more than one is given): UnitName > GroupName > StaticName > a flat
-- coordinate (x/z, the DCS map grid, or lat/lon).
--
-- Pilots reach these by saying "vector to <Name>" or "direct <Name>"
-- (matches Name, Id, or any Alias, case-insensitive).
---------------------------------------------------------------------------

-- Example: vector to a live tanker unit (tracks its current position).
-- NASG_ATC:RegisterTrackedPoint({
--     Id = "texaco",
--     Name = "Texaco",
--     UnitName = "Texaco-1-1",
-- })

-- Example: vector to a live group (uses the group leader's position).
-- NASG_ATC:RegisterTrackedPoint({
--     Id = "objective_alpha",
--     Name = "Objective Alpha",
--     GroupName = "Alpha Ground Group",
-- })

-- Example: vector to a fixed DCS map coordinate (x/z).
-- NASG_ATC:RegisterTrackedPoint({
--     Id = "bullseye",
--     Name = "Bullseye",
--     x = 123456.7,
--     z = 654321.0,
-- })

-- Example: vector to a fixed lat/lon coordinate, with an alias.
-- NASG_ATC:RegisterTrackedPoint({
--     Id = "range_entry",
--     Name = "Range Entry",
--     Aliases = { "Range" },
--     lat = 25.16,
--     lon = 55.76,
-- })

---------------------------------------------------------------------------
-- Enroute (ENR) named fixes, imported from the community Persian Gulf ENR
-- waypoint template (TMPL_All_ENR). 526 named fixes across the map, each
-- reachable via "request direct <name>" / "vector to <name>" from Center
-- or Clearance (see ATC_Command_Reference.txt). Coordinates are copied
-- straight from the source mission file's nav_points table (x = north,
-- z = east, matching nav_points.y) -- no conversion needed. Three fixes
-- in the source data were listed twice under different ids with
-- identical coordinates (GABKO, ORSAR, PATAT) -- deduplicated here.
---------------------------------------------------------------------------

NASG_ATC:RegisterTrackedPoint({
    Id = "abumusaisland",
    Name = "ABUMUSAISLAND",
    x = -31261.5,
    z = -122331.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "algux",
    Name = "ALGUX",
    x = -195803.7,
    z = -208014.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "alkad",
    Name = "ALKAD",
    x = -183787.5,
    z = -208363.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "alkes",
    Name = "ALKES",
    x = 443814.7,
    z = 124642.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "alkul",
    Name = "ALKUL",
    x = 409045.0,
    z = 100892.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "almek",
    Name = "ALMEK",
    x = 400654.2,
    z = 61151.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "almob",
    Name = "ALMOB",
    x = 487964.6,
    z = 25336.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "alnet",
    Name = "ALNET",
    x = -82048.7,
    z = -104515.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "alnev",
    Name = "ALNEV",
    x = -151735.4,
    z = -259060.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "alnin",
    Name = "ALNIN",
    x = 282460.4,
    z = -592546.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "alnol",
    Name = "ALNOL",
    x = 60701.6,
    z = -259401.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "alnum",
    Name = "ALNUM",
    x = -146395.0,
    z = 1664.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "alpob",
    Name = "ALPOB",
    x = -45878.7,
    z = -324218.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "alrar",
    Name = "ALRAR",
    x = -52899.7,
    z = -121908.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "alser",
    Name = "ALSER",
    x = 126517.3,
    z = -536560.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "alsil",
    Name = "ALSIL",
    x = -75559.2,
    z = -47110.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "alsov",
    Name = "ALSOV",
    x = -204403.6,
    z = -122804.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ambov",
    Name = "AMBOV",
    x = -63831.9,
    z = -166667.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "anvix",
    Name = "ANVIX",
    x = -153712.6,
    z = -31624.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "askum",
    Name = "ASKUM",
    x = -63103.8,
    z = -39982.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "asmet",
    Name = "ASMET",
    x = 291114.5,
    z = -5053.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "asmuk",
    Name = "ASMUK",
    x = 220827.3,
    z = -14428.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "asnax",
    Name = "ASNAX",
    x = -128609.5,
    z = -360450.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "asnek",
    Name = "ASNEK",
    x = -25153.5,
    z = -42601.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "asnul",
    Name = "ASNUL",
    x = -86152.8,
    z = -68706.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "asped",
    Name = "ASPED",
    x = -238820.5,
    z = -73589.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "asrat",
    Name = "ASRAT",
    x = -198227.2,
    z = -229080.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "astes",
    Name = "ASTES",
    x = -106806.4,
    z = -79691.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "astog",
    Name = "ASTOG",
    x = -71094.2,
    z = -342613.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "asvad",
    Name = "ASVAD",
    x = -229187.4,
    z = -67981.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "atudo",
    Name = "ATUDO",
    x = -206948.5,
    z = -170338.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "bam",
    Name = "BAM",
    x = 322514.0,
    z = 217699.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "bandarabbas",
    Name = "BANDARABBAS",
    x = 113486.7,
    z = 13037.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "bandarlengeh",
    Name = "BANDARLENGEH",
    x = 41921.3,
    z = -138339.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "bandarmahshahr",
    Name = "BANDARMAHSHAHR",
    x = 511867.8,
    z = -678298.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "bomiv",
    Name = "BOMIV",
    x = -80711.3,
    z = -91592.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "bomos",
    Name = "BOMOS",
    x = -203930.2,
    z = -145726.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "bonik",
    Name = "BONIK",
    x = 63440.0,
    z = 20816.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "bopis",
    Name = "BOPIS",
    x = 505553.5,
    z = -720935.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "bopit",
    Name = "BOPIT",
    x = -237999.8,
    z = -222579.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "bopor",
    Name = "BOPOR",
    x = -231544.1,
    z = -67344.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "borim",
    Name = "BORIM",
    x = -170339.4,
    z = -207949.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "borul",
    Name = "BORUL",
    x = -130829.7,
    z = 39706.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "boseg",
    Name = "BOSEG",
    x = -84100.6,
    z = -24866.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "bosev",
    Name = "BOSEV",
    x = -144870.5,
    z = -219348.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "bosig",
    Name = "BOSIG",
    x = -227505.7,
    z = -131382.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "bosos",
    Name = "BOSOS",
    x = 61530.1,
    z = -51582.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "botas",
    Name = "BOTAS",
    x = 425905.8,
    z = -511839.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "botut",
    Name = "BOTUT",
    x = -43486.5,
    z = -45159.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "botux",
    Name = "BOTUX",
    x = 311318.5,
    z = -83245.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "boxot",
    Name = "BOXOT",
    x = -105215.4,
    z = -296761.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "bundu",
    Name = "BUNDU",
    x = -121660.2,
    z = -379626.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "bushehr",
    Name = "BUSHEHR",
    x = 323404.1,
    z = -526498.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "danig",
    Name = "DANIG",
    x = -126554.1,
    z = 29460.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "danok",
    Name = "DANOK",
    x = -268967.4,
    z = -279176.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "dapad",
    Name = "DAPAD",
    x = -104376.2,
    z = -55193.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "daper",
    Name = "DAPER",
    x = -44672.4,
    z = -128988.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "dapox",
    Name = "DAPOX",
    x = 484959.5,
    z = -40199.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "dariv",
    Name = "DARIV",
    x = -38761.9,
    z = -27252.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "darto",
    Name = "DARTO",
    x = -74078.8,
    z = -27510.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "dasdo",
    Name = "DASDO",
    x = 311908.7,
    z = -402517.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "dasnu",
    Name = "DASNU",
    x = -193139.7,
    z = -137761.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "dasut",
    Name = "DASUT",
    x = 20584.3,
    z = -305152.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "datob",
    Name = "DATOB",
    x = -71130.4,
    z = -147108.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "datut",
    Name = "DATUT",
    x = 47160.4,
    z = -263611.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "davep",
    Name = "DAVEP",
    x = 169882.7,
    z = 108864.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "davmo",
    Name = "DAVMO",
    x = -34334.8,
    z = -59519.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "davut",
    Name = "DAVUT",
    x = 429077.5,
    z = -80093.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "daxib",
    Name = "DAXIB",
    x = -136610.8,
    z = -212085.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "debki",
    Name = "DEBKI",
    x = -166545.9,
    z = -194335.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "debna",
    Name = "DEBNA",
    x = -229699.8,
    z = -67196.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "dedax",
    Name = "DEDAX",
    x = -149215.6,
    z = -112979.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "degvo",
    Name = "DEGVO",
    x = -173265.3,
    z = -195707.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "delbu",
    Name = "DELBU",
    x = 77017.8,
    z = -213941.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "dempo",
    Name = "DEMPO",
    x = 484934.5,
    z = -721428.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "densa",
    Name = "DENSA",
    x = 42205.2,
    z = -174454.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "depsu",
    Name = "DEPSU",
    x = 276188.7,
    z = -428644.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "despa",
    Name = "DESPA",
    x = -105996.8,
    z = 26620.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "desvu",
    Name = "DESVU",
    x = -198830.3,
    z = -54598.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "detgu",
    Name = "DETGU",
    x = -80528.7,
    z = -64890.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "dursi",
    Name = "DURSI",
    x = 124026.3,
    z = -416917.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "eglop",
    Name = "EGLOP",
    x = -86464.0,
    z = -33818.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "egmap",
    Name = "EGMAP",
    x = -41125.6,
    z = -36206.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "egmit",
    Name = "EGMIT",
    x = 48691.0,
    z = -308838.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "egnot",
    Name = "EGNOT",
    x = -91839.5,
    z = -116225.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "egpep",
    Name = "EGPEP",
    x = -22943.1,
    z = -27067.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "egpog",
    Name = "EGPOG",
    x = -148158.6,
    z = -295316.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "egrop",
    Name = "EGROP",
    x = -142286.2,
    z = -166026.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "egrul",
    Name = "EGRUL",
    x = -222168.7,
    z = -66592.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "egsir",
    Name = "EGSIR",
    x = 411352.1,
    z = -460240.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "egsup",
    Name = "EGSUP",
    x = -197719.2,
    z = -191967.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "egtag",
    Name = "EGTAG",
    x = -111923.9,
    z = -131111.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "elavu",
    Name = "ELAVU",
    x = -175183.5,
    z = -201345.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "elepo",
    Name = "ELEPO",
    x = -179436.4,
    z = -153581.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "elidu",
    Name = "ELIDU",
    x = 32435.9,
    z = -337430.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "eliga",
    Name = "ELIGA",
    x = -195547.3,
    z = -327133.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "elira",
    Name = "ELIRA",
    x = 23751.1,
    z = -248573.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "elovu",
    Name = "ELOVU",
    x = -132231.2,
    z = -193004.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "eluda",
    Name = "ELUDA",
    x = -256272.8,
    z = -78552.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "emati",
    Name = "EMATI",
    x = -195726.9,
    z = -135385.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "emeru",
    Name = "EMERU",
    x = -149832.2,
    z = -121263.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "emiko",
    Name = "EMIKO",
    x = -85766.5,
    z = -83809.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "emixi",
    Name = "EMIXI",
    x = -192673.3,
    z = -431300.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "emopi",
    Name = "EMOPI",
    x = -81113.9,
    z = -9712.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "emopo",
    Name = "EMOPO",
    x = -96729.9,
    z = -130812.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "emosu",
    Name = "EMOSU",
    x = -202447.8,
    z = -147798.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "emota",
    Name = "EMOTA",
    x = -29780.0,
    z = -184371.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "enega",
    Name = "ENEGA",
    x = -118733.1,
    z = -14964.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "gabko",
    Name = "GABKO",
    x = -11189.4,
    z = -44412.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "genuk",
    Name = "GENUK",
    x = -77585.6,
    z = -50207.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "gepel",
    Name = "GEPEL",
    x = -206210.8,
    z = -163103.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "gerip",
    Name = "GERIP",
    x = -199821.0,
    z = -63580.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "gerul",
    Name = "GERUL",
    x = -127512.3,
    z = -182055.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "geset",
    Name = "GESET",
    x = -90743.1,
    z = -61695.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "getid",
    Name = "GETID",
    x = -88183.0,
    z = -30850.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "getis",
    Name = "GETIS",
    x = 445809.8,
    z = 15648.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "gevam",
    Name = "GEVAM",
    x = -81737.4,
    z = -15911.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "geviv",
    Name = "GEVIV",
    x = -162763.0,
    z = -143464.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "gexik",
    Name = "GEXIK",
    x = -153831.5,
    z = -88142.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "gexod",
    Name = "GEXOD",
    x = -195778.2,
    z = -119039.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "gheshmisland",
    Name = "GHESHMISLAND",
    x = 65728.3,
    z = -32850.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "gibib",
    Name = "GIBIB",
    x = -25448.0,
    z = -196038.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "gibur",
    Name = "GIBUR",
    x = -96897.6,
    z = -141121.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "gidis",
    Name = "GIDIS",
    x = -173857.0,
    z = -32231.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "gidob",
    Name = "GIDOB",
    x = -154787.1,
    z = -227891.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "gidol",
    Name = "GIDOL",
    x = -100117.3,
    z = -50088.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "gigab",
    Name = "GIGAB",
    x = -61342.4,
    z = 130166.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ginla",
    Name = "GINLA",
    x = -112784.5,
    z = -133197.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "girgo",
    Name = "GIRGO",
    x = -107454.5,
    z = -63965.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "girgu",
    Name = "GIRGU",
    x = -50558.7,
    z = -165170.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "gismo",
    Name = "GISMO",
    x = -152509.7,
    z = 12751.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "gisvu",
    Name = "GISVU",
    x = -211503.7,
    z = -118534.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "givko",
    Name = "GIVKO",
    x = -122401.5,
    z = -34770.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "givli",
    Name = "GIVLI",
    x = -78771.3,
    z = -55221.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "godki",
    Name = "GODKI",
    x = -49576.6,
    z = -252493.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "golpa",
    Name = "GOLPA",
    x = -194010.0,
    z = -230399.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "gomta",
    Name = "GOMTA",
    x = -109157.2,
    z = 33410.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "gonvi",
    Name = "GONVI",
    x = -49637.6,
    z = -130752.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ibkug",
    Name = "IBKUG",
    x = 381538.9,
    z = -603598.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ibnux",
    Name = "IBNUX",
    x = 13827.2,
    z = -203660.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ibsal",
    Name = "IBSAL",
    x = 464874.4,
    z = -721895.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "imdat",
    Name = "IMDAT",
    x = 180761.2,
    z = -498380.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "imgil",
    Name = "IMGIL",
    x = -132336.0,
    z = -85003.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "imgod",
    Name = "IMGOD",
    x = 463053.8,
    z = -452496.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "imgux",
    Name = "IMGUX",
    x = -69584.9,
    z = -302183.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "imkir",
    Name = "IMKIR",
    x = -122466.7,
    z = 19730.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "imkud",
    Name = "IMKUD",
    x = -209347.2,
    z = -228982.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "imlip",
    Name = "IMLIP",
    x = -170673.4,
    z = -167535.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "imlot",
    Name = "IMLOT",
    x = -98205.0,
    z = 89179.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "imluv",
    Name = "IMLUV",
    x = 41550.6,
    z = -321373.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "imped",
    Name = "IMPED",
    x = -132599.8,
    z = -18275.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "impiv",
    Name = "IMPIV",
    x = -98065.6,
    z = -29940.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "imsig",
    Name = "IMSIG",
    x = -165081.2,
    z = -194286.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "imten",
    Name = "IMTEN",
    x = -31207.8,
    z = -33085.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "imtup",
    Name = "IMTUP",
    x = -203591.1,
    z = -120830.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "itbon",
    Name = "ITBON",
    x = -102880.3,
    z = -36794.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "itbul",
    Name = "ITBUL",
    x = -36271.3,
    z = -204206.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "itiko",
    Name = "ITIKO",
    x = -72989.9,
    z = -37373.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "itkev",
    Name = "ITKEV",
    x = -124097.0,
    z = -251537.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "itkov",
    Name = "ITKOV",
    x = -207096.5,
    z = -142007.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "itlap",
    Name = "ITLAP",
    x = -38266.6,
    z = -40901.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "itliv",
    Name = "ITLIV",
    x = -155751.7,
    z = -144429.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "itomi",
    Name = "ITOMI",
    x = -123612.4,
    z = -207045.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "itotu",
    Name = "ITOTU",
    x = -101440.5,
    z = -31103.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "itrax",
    Name = "ITRAX",
    x = -216561.0,
    z = -46411.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "itren",
    Name = "ITREN",
    x = -216363.4,
    z = -130469.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "itugo",
    Name = "ITUGO",
    x = -181648.1,
    z = -155721.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ivadi",
    Name = "IVADI",
    x = -99320.5,
    z = -62963.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ivatu",
    Name = "IVATU",
    x = -100961.4,
    z = -136027.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ivegu",
    Name = "IVEGU",
    x = -196652.5,
    z = -151819.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ivepo",
    Name = "IVEPO",
    x = -174407.7,
    z = -167694.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ivera",
    Name = "IVERA",
    x = 369341.9,
    z = -481618.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ivili",
    Name = "IVILI",
    x = -97058.7,
    z = -151174.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ivisa",
    Name = "IVISA",
    x = -176059.3,
    z = -200658.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "iviva",
    Name = "IVIVA",
    x = -130188.5,
    z = 159796.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ivoxi",
    Name = "IVOXI",
    x = -105686.5,
    z = -83390.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ivuro",
    Name = "IVURO",
    x = -93421.2,
    z = -9370.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ivuti",
    Name = "IVUTI",
    x = -63175.4,
    z = -118865.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "jask",
    Name = "JASK",
    x = -57597.3,
    z = 154395.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kanip",
    Name = "KANIP",
    x = -220029.1,
    z = -92359.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kanud",
    Name = "KANUD",
    x = -33717.3,
    z = -32855.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kapip",
    Name = "KAPIP",
    x = 69682.2,
    z = -398568.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kapum",
    Name = "KAPUM",
    x = -128861.9,
    z = -269513.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "karer",
    Name = "KARER",
    x = -141604.3,
    z = 32271.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kasol",
    Name = "KASOL",
    x = 266665.7,
    z = -290380.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "katag",
    Name = "KATAG",
    x = 255105.4,
    z = -383826.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "katig",
    Name = "KATIG",
    x = -196580.4,
    z = -155108.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "katur",
    Name = "KATUR",
    x = 319620.0,
    z = -466398.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "katus",
    Name = "KATUS",
    x = -100226.9,
    z = 154632.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kavam",
    Name = "KAVAM",
    x = 97055.5,
    z = -423686.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kaveg",
    Name = "KAVEG",
    x = 11505.1,
    z = -83071.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kavil",
    Name = "KAVIL",
    x = 416040.4,
    z = -477034.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kaxob",
    Name = "KAXOB",
    x = -135571.5,
    z = -286544.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kebog",
    Name = "KEBOG",
    x = -67733.6,
    z = -78634.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kedad",
    Name = "KEDAD",
    x = -191216.7,
    z = -61974.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "keder",
    Name = "KEDER",
    x = -202008.2,
    z = -158575.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kerman",
    Name = "KERMAN",
    x = 455437.8,
    z = 70346.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kharkisland",
    Name = "KHARKISLAND",
    x = 360876.2,
    z = -574295.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kinil",
    Name = "KINIL",
    x = -174382.9,
    z = -182754.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kinot",
    Name = "KINOT",
    x = 489022.9,
    z = -280063.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kipok",
    Name = "KIPOK",
    x = -173653.5,
    z = -13133.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kiruk",
    Name = "KIRUK",
    x = -132277.0,
    z = -122605.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kised",
    Name = "KISED",
    x = 470207.6,
    z = -446301.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kishisland",
    Name = "KISHISLAND",
    x = 42497.7,
    z = -226959.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kitox",
    Name = "KITOX",
    x = -199475.3,
    z = -108421.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kitur",
    Name = "KITUR",
    x = -77613.8,
    z = -96345.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kivus",
    Name = "KIVUS",
    x = -42852.5,
    z = -224288.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kixog",
    Name = "KIXOG",
    x = -83446.2,
    z = -153718.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kugto",
    Name = "KUGTO",
    x = -178168.9,
    z = -190335.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kugvu",
    Name = "KUGVU",
    x = 340707.6,
    z = -475420.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kulba",
    Name = "KULBA",
    x = -104842.4,
    z = -21811.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kumsi",
    Name = "KUMSI",
    x = -139732.5,
    z = -368544.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kumun",
    Name = "KUMUN",
    x = -55005.2,
    z = -99553.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kunpi",
    Name = "KUNPI",
    x = -65023.0,
    z = -86889.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kupma",
    Name = "KUPMA",
    x = -145004.5,
    z = 19857.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kupor",
    Name = "KUPOR",
    x = -75496.5,
    z = -83678.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kupto",
    Name = "KUPTO",
    x = 253951.1,
    z = -325166.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kurtu",
    Name = "KURTU",
    x = -88479.5,
    z = -47631.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kusba",
    Name = "KUSBA",
    x = -94756.4,
    z = -278818.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kusen",
    Name = "KUSEN",
    x = -95767.0,
    z = 14802.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kusok",
    Name = "KUSOK",
    x = -198899.0,
    z = -152219.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kutli",
    Name = "KUTLI",
    x = -143440.2,
    z = -132543.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kuvda",
    Name = "KUVDA",
    x = -159045.9,
    z = -161708.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kuver",
    Name = "KUVER",
    x = 238990.5,
    z = -602598.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kuvin",
    Name = "KUVIN",
    x = -165095.9,
    z = -183004.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "labri",
    Name = "LABRI",
    x = -233153.2,
    z = -62004.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ladmo",
    Name = "LADMO",
    x = -126536.2,
    z = -131796.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "lagli",
    Name = "LAGLI",
    x = -86552.2,
    z = -608.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "lagsa",
    Name = "LAGSA",
    x = 272226.5,
    z = -379476.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "lagta",
    Name = "LAGTA",
    x = -118070.3,
    z = -70033.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "lagvu",
    Name = "LAGVU",
    x = -183910.9,
    z = -219221.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "laldo",
    Name = "LALDO",
    x = -96521.3,
    z = 35491.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "lamerd",
    Name = "LAMERD",
    x = 138583.9,
    z = -301757.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "lar",
    Name = "LAR",
    x = 168962.1,
    z = -179196.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "lavanisland",
    Name = "LAVANISLAND",
    x = 75887.6,
    z = -286542.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "levna",
    Name = "LEVNA",
    x = 13847.8,
    z = -258963.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "lonup",
    Name = "LONUP",
    x = -172171.4,
    z = -150245.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "lonut",
    Name = "LONUT",
    x = -206668.4,
    z = -327422.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "lopap",
    Name = "LOPAP",
    x = -106211.2,
    z = -149465.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "lopuv",
    Name = "LOPUV",
    x = -146992.5,
    z = -40533.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "lorid",
    Name = "LORID",
    x = -135547.5,
    z = -161441.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "lorix",
    Name = "LORIX",
    x = 216053.0,
    z = -147715.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "lorup",
    Name = "LORUP",
    x = -193001.1,
    z = -126963.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "losid",
    Name = "LOSID",
    x = -164133.8,
    z = -177582.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "losov",
    Name = "LOSOV",
    x = -196555.1,
    z = -151941.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "lovem",
    Name = "LOVEM",
    x = -79442.8,
    z = -100758.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "lovim",
    Name = "LOVIM",
    x = -183643.2,
    z = -171004.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "lovok",
    Name = "LOVOK",
    x = -68047.9,
    z = -121776.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "lovol",
    Name = "LOVOL",
    x = -113254.3,
    z = -68665.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "lovub",
    Name = "LOVUB",
    x = -182532.3,
    z = -169407.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "loxix",
    Name = "LOXIX",
    x = -199908.3,
    z = -132975.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "lubap",
    Name = "LUBAP",
    x = -135704.0,
    z = -45298.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "lubat",
    Name = "LUBAT",
    x = -125402.6,
    z = 4832.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "lubik",
    Name = "LUBIK",
    x = -207084.0,
    z = -142021.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "lubus",
    Name = "LUBUS",
    x = -156712.6,
    z = -182999.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ludam",
    Name = "LUDAM",
    x = -24751.5,
    z = -226466.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ludev",
    Name = "LUDEV",
    x = -83884.5,
    z = -48461.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "mekma",
    Name = "MEKMA",
    x = -132326.6,
    z = -387269.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "mekri",
    Name = "MEKRI",
    x = -179309.6,
    z = -236672.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "melmi",
    Name = "MELMI",
    x = 66485.5,
    z = 113864.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "mempi",
    Name = "MEMPI",
    x = 390593.2,
    z = -593261.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "mendi",
    Name = "MENDI",
    x = -36468.4,
    z = -115741.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "mendu",
    Name = "MENDU",
    x = -180193.6,
    z = -172323.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "mensa",
    Name = "MENSA",
    x = -133907.4,
    z = 30024.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "mepdo",
    Name = "MEPDO",
    x = -180037.3,
    z = -182645.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "mepku",
    Name = "MEPKU",
    x = -79005.6,
    z = -129517.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "mepti",
    Name = "MEPTI",
    x = -112173.9,
    z = -1117.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "merpu",
    Name = "MERPU",
    x = -233301.7,
    z = -124161.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "mibru",
    Name = "MIBRU",
    x = -117092.7,
    z = -352047.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "midsi",
    Name = "MIDSI",
    x = 67844.6,
    z = -430838.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "mipip",
    Name = "MIPIP",
    x = -212527.1,
    z = -155307.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "mirit",
    Name = "MIRIT",
    x = 19765.8,
    z = -133527.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "mirot",
    Name = "MIROT",
    x = -116332.4,
    z = -174992.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "miseg",
    Name = "MISEG",
    x = -89701.6,
    z = -38138.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "misol",
    Name = "MISOL",
    x = -139216.7,
    z = -181638.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "mitix",
    Name = "MITIX",
    x = -95864.0,
    z = -113023.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "mivek",
    Name = "MIVEK",
    x = -143312.4,
    z = 446.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "mivun",
    Name = "MIVUN",
    x = 42306.9,
    z = -190158.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "mivur",
    Name = "MIVUR",
    x = -74444.3,
    z = -55011.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "mixem",
    Name = "MIXEM",
    x = 128694.6,
    z = -393218.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "mobet",
    Name = "MOBET",
    x = 62432.3,
    z = -8554.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "mobon",
    Name = "MOBON",
    x = 174160.0,
    z = -79952.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "mobul",
    Name = "MOBUL",
    x = -97774.7,
    z = -195026.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "modus",
    Name = "MODUS",
    x = -108642.9,
    z = -76744.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "mogim",
    Name = "MOGIM",
    x = -162906.7,
    z = -180029.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "munpa",
    Name = "MUNPA",
    x = -170641.8,
    z = -134118.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "murgu",
    Name = "MURGU",
    x = -180935.8,
    z = -19907.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "mursu",
    Name = "MURSU",
    x = -149496.1,
    z = -159785.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "musap",
    Name = "MUSAP",
    x = -207218.3,
    z = -37985.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "musen",
    Name = "MUSEN",
    x = -211784.2,
    z = -173696.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "musul",
    Name = "MUSUL",
    x = -162635.4,
    z = -202445.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "mutop",
    Name = "MUTOP",
    x = -152843.9,
    z = -167330.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "muvum",
    Name = "MUVUM",
    x = -168431.2,
    z = -164232.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "nabex",
    Name = "NABEX",
    x = 116604.1,
    z = -199032.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "nabix",
    Name = "NABIX",
    x = -104288.7,
    z = -173131.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "nabox",
    Name = "NABOX",
    x = 233566.6,
    z = 216361.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "nabun",
    Name = "NABUN",
    x = -233426.3,
    z = -143965.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "nadni",
    Name = "NADNI",
    x = -94038.4,
    z = -29956.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "nagex",
    Name = "NAGEX",
    x = -110280.4,
    z = -4074.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "nalbi",
    Name = "NALBI",
    x = 403568.4,
    z = -224042.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "nalnu",
    Name = "NALNU",
    x = -152575.1,
    z = -9460.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "nalpo",
    Name = "NALPO",
    x = -21872.2,
    z = -275264.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "namla",
    Name = "NAMLA",
    x = -112385.8,
    z = -372742.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "nanpa",
    Name = "NANPA",
    x = 24074.4,
    z = -71219.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "nanpi",
    Name = "NANPI",
    x = 345331.6,
    z = -652092.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "nanto",
    Name = "NANTO",
    x = 279253.0,
    z = 40779.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "napma",
    Name = "NAPMA",
    x = -215647.8,
    z = -121938.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "nitri",
    Name = "NITRI",
    x = -124561.4,
    z = -134934.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "nobto",
    Name = "NOBTO",
    x = -248136.1,
    z = -96140.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "nogso",
    Name = "NOGSO",
    x = -109074.7,
    z = -47931.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "nolsu",
    Name = "NOLSU",
    x = -106077.4,
    z = -12170.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "nomdi",
    Name = "NOMDI",
    x = -50255.9,
    z = -33794.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "nopnu",
    Name = "NOPNU",
    x = -202712.5,
    z = -159165.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "novsu",
    Name = "NOVSU",
    x = 43886.2,
    z = 140186.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "obmuk",
    Name = "OBMUK",
    x = -157092.5,
    z = -177942.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "obnet",
    Name = "OBNET",
    x = -14225.4,
    z = -249190.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "obrev",
    Name = "OBREV",
    x = -125077.5,
    z = -106552.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "obrog",
    Name = "OBROG",
    x = -55074.4,
    z = -79667.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "obsik",
    Name = "OBSIK",
    x = -206682.9,
    z = -162490.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "obtar",
    Name = "OBTAR",
    x = 104651.5,
    z = -514991.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "obtol",
    Name = "OBTOL",
    x = -171126.6,
    z = -186812.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "obvik",
    Name = "OBVIK",
    x = -190393.7,
    z = -174499.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "obvom",
    Name = "OBVOM",
    x = -203561.8,
    z = -439250.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "odkun",
    Name = "ODKUN",
    x = -190497.7,
    z = -160328.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "odlal",
    Name = "ODLAL",
    x = -82759.3,
    z = -131210.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "orbol",
    Name = "ORBOL",
    x = -143035.0,
    z = -187302.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ordad",
    Name = "ORDAD",
    x = 435532.6,
    z = 163916.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ordak",
    Name = "ORDAK",
    x = -163529.1,
    z = -193035.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "orgad",
    Name = "ORGAD",
    x = -172370.2,
    z = -194394.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "orgur",
    Name = "ORGUR",
    x = -116684.7,
    z = -147509.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "orkob",
    Name = "ORKOB",
    x = -142495.7,
    z = 15742.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "orlad",
    Name = "ORLAD",
    x = -89768.5,
    z = -134735.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ormed",
    Name = "ORMED",
    x = -192005.2,
    z = -175450.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ormid",
    Name = "ORMID",
    x = -61081.4,
    z = -335333.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ornel",
    Name = "ORNEL",
    x = -233800.1,
    z = -94214.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "orpat",
    Name = "ORPAT",
    x = -141929.3,
    z = -124656.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "orpax",
    Name = "ORPAX",
    x = -188019.8,
    z = -252855.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "orpen",
    Name = "ORPEN",
    x = 39630.9,
    z = -90088.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "orpep",
    Name = "ORPEP",
    x = -178719.6,
    z = -208637.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "orsar",
    Name = "ORSAR",
    x = -7390.8,
    z = -228541.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "orsob",
    Name = "ORSOB",
    x = -184898.2,
    z = -169660.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "otiki",
    Name = "OTIKI",
    x = -67164.0,
    z = -201115.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "otutu",
    Name = "OTUTU",
    x = -186294.6,
    z = -194322.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ovadi",
    Name = "OVADI",
    x = -88633.0,
    z = -64914.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ovaxa",
    Name = "OVAXA",
    x = -72674.0,
    z = -89319.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ovola",
    Name = "OVOLA",
    x = -160309.4,
    z = -185255.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ovona",
    Name = "OVONA",
    x = -77696.1,
    z = -347469.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "oxari",
    Name = "OXARI",
    x = -78365.5,
    z = -268004.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "papar",
    Name = "PAPAR",
    x = 57119.2,
    z = -178034.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "pared",
    Name = "PARED",
    x = -230964.2,
    z = -122529.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "pasev",
    Name = "PASEV",
    x = -74167.9,
    z = -117045.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "pasov",
    Name = "PASOV",
    x = -169314.6,
    z = 59929.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "patam",
    Name = "PATAM",
    x = -184150.6,
    z = -134459.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "patat",
    Name = "PATAT",
    x = 11056.2,
    z = -22458.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "patid",
    Name = "PATID",
    x = -89446.9,
    z = -92641.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "patir",
    Name = "PATIR",
    x = 329182.2,
    z = -657324.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "pavag",
    Name = "PAVAG",
    x = -100232.5,
    z = -57335.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "pavon",
    Name = "PAVON",
    x = 95632.6,
    z = -3896.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "paxik",
    Name = "PAXIK",
    x = -166099.2,
    z = -204606.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "pebus",
    Name = "PEBUS",
    x = -111060.9,
    z = -143351.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "pedog",
    Name = "PEDOG",
    x = -198881.3,
    z = -36546.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "pedov",
    Name = "PEDOV",
    x = -89347.5,
    z = -107551.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "peduk",
    Name = "PEDUK",
    x = 312165.1,
    z = 164699.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "pedul",
    Name = "PEDUL",
    x = -164212.8,
    z = -21897.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "pegeb",
    Name = "PEGEB",
    x = -203462.6,
    z = -131742.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "peget",
    Name = "PEGET",
    x = 108821.9,
    z = -395102.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "pegum",
    Name = "PEGUM",
    x = -214799.7,
    z = -129216.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "pekax",
    Name = "PEKAX",
    x = -173319.3,
    z = -210403.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "persiangulf",
    Name = "PERSIANGULF",
    x = 138541.5,
    z = -343349.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "purli",
    Name = "PURLI",
    x = -57304.2,
    z = -284842.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "purna",
    Name = "PURNA",
    x = 78001.0,
    z = -237022.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "pusot",
    Name = "PUSOT",
    x = -54731.6,
    z = -191645.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "putib",
    Name = "PUTIB",
    x = -88796.1,
    z = -330551.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "puval",
    Name = "PUVAL",
    x = -62982.7,
    z = -53172.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "puvod",
    Name = "PUVOD",
    x = -172826.7,
    z = -181498.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "puvut",
    Name = "PUVUT",
    x = -225899.6,
    z = -130299.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "puxil",
    Name = "PUXIL",
    x = -164443.9,
    z = 28124.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "puxut",
    Name = "PUXUT",
    x = -167620.2,
    z = -191161.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "rabdu",
    Name = "RABDU",
    x = -194177.8,
    z = -162958.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "radeb",
    Name = "RADEB",
    x = 2849.6,
    z = -45282.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "radid",
    Name = "RADID",
    x = 482698.4,
    z = -458968.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "radso",
    Name = "RADSO",
    x = -198136.2,
    z = -152948.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "rafsanjan",
    Name = "RAFSANJAN",
    x = 457778.0,
    z = -15049.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ragas",
    Name = "RAGAS",
    x = 55373.6,
    z = -399825.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ragdo",
    Name = "RAGDO",
    x = -85282.3,
    z = -241085.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ralda",
    Name = "RALDA",
    x = -177269.8,
    z = -178947.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ralmi",
    Name = "RALMI",
    x = -42141.6,
    z = -274466.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "rapmo",
    Name = "RAPMO",
    x = -135812.0,
    z = -55633.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "rapno",
    Name = "RAPNO",
    x = -210552.7,
    z = -201817.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "rarpi",
    Name = "RARPI",
    x = -116715.1,
    z = -78535.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "rerag",
    Name = "RERAG",
    x = -166361.7,
    z = -42267.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "rerek",
    Name = "REREK",
    x = -84385.2,
    z = -114724.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "resig",
    Name = "RESIG",
    x = -180313.3,
    z = -172170.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "retas",
    Name = "RETAS",
    x = -243846.9,
    z = -69429.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "retux",
    Name = "RETUX",
    x = -182395.9,
    z = -172776.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "revav",
    Name = "REVAV",
    x = -110102.6,
    z = -209539.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "revul",
    Name = "REVUL",
    x = -151685.8,
    z = -91571.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "rexeb",
    Name = "REXEB",
    x = 419191.9,
    z = -392294.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "rexev",
    Name = "REXEV",
    x = -101876.8,
    z = -22246.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "rexig",
    Name = "REXIG",
    x = -239074.8,
    z = -113260.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ribuv",
    Name = "RIBUV",
    x = -158901.7,
    z = -172219.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ridap",
    Name = "RIDAP",
    x = -80054.1,
    z = -163908.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ridev",
    Name = "RIDEV",
    x = -115315.8,
    z = -51408.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ridib",
    Name = "RIDIB",
    x = -179116.5,
    z = -139248.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ridis",
    Name = "RIDIS",
    x = 71000.5,
    z = -161810.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "rigip",
    Name = "RIGIP",
    x = -153136.5,
    z = -194191.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "rigut",
    Name = "RIGUT",
    x = 260670.2,
    z = 112337.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "rikas",
    Name = "RIKAS",
    x = 414606.4,
    z = -161794.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "roron",
    Name = "RORON",
    x = -85877.0,
    z = -311382.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "rotal",
    Name = "ROTAL",
    x = 155697.7,
    z = -231499.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "rotox",
    Name = "ROTOX",
    x = 285145.9,
    z = -629264.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "rovib",
    Name = "ROVIB",
    x = -94667.6,
    z = -143685.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "rovos",
    Name = "ROVOS",
    x = -205744.4,
    z = -90469.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "rubak",
    Name = "RUBAK",
    x = 373279.6,
    z = -438167.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "rudat",
    Name = "RUDAT",
    x = -155476.8,
    z = 3697.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "rudis",
    Name = "RUDIS",
    x = -67621.4,
    z = -97070.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "rudon",
    Name = "RUDON",
    x = -194333.9,
    z = -154707.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ruduk",
    Name = "RUDUK",
    x = -82660.0,
    z = -197827.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "rugis",
    Name = "RUGIS",
    x = -125557.6,
    z = -321958.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "rukor",
    Name = "RUKOR",
    x = -113946.1,
    z = -48480.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "rukos",
    Name = "RUKOS",
    x = -195229.6,
    z = -177272.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "rukot",
    Name = "RUKOT",
    x = 79760.0,
    z = 181112.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "rural",
    Name = "RURAL",
    x = -181728.5,
    z = -174291.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "sedpo",
    Name = "SEDPO",
    x = -113531.4,
    z = -68940.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "senpa",
    Name = "SENPA",
    x = -90804.8,
    z = -172234.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "serdu",
    Name = "SERDU",
    x = 69584.6,
    z = -126467.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "sersa",
    Name = "SERSA",
    x = -92714.9,
    z = -73032.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "sesma",
    Name = "SESMA",
    x = 391738.0,
    z = -497574.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "setru",
    Name = "SETRU",
    x = -205427.8,
    z = -140841.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "shiraz",
    Name = "SHIRAZ",
    x = 381027.1,
    z = -351862.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "sigdi",
    Name = "SIGDI",
    x = -83083.1,
    z = -56042.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "sigmo",
    Name = "SIGMO",
    x = -225998.4,
    z = -129849.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "silko",
    Name = "SILKO",
    x = 417609.8,
    z = 239249.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "sinpu",
    Name = "SINPU",
    x = -166125.4,
    z = -66197.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "sir",
    Name = "SIR",
    x = -26435.0,
    z = -171022.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "sirjan",
    Name = "SIRJAN",
    x = 375431.6,
    z = -54034.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "sirriisland",
    Name = "SIRRIISLAND",
    x = -26386.3,
    z = -171152.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "sisob",
    Name = "SISOB",
    x = -67245.9,
    z = -250637.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "sisug",
    Name = "SISUG",
    x = -187038.0,
    z = -144046.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "sitak",
    Name = "SITAK",
    x = 482959.9,
    z = 247448.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "siten",
    Name = "SITEN",
    x = 323817.8,
    z = -321137.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "sitib",
    Name = "SITIB",
    x = -236906.3,
    z = -117352.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "sivov",
    Name = "SIVOV",
    x = -179087.2,
    z = -188508.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "sixiv",
    Name = "SIXIV",
    x = -202175.3,
    z = -119297.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "sobob",
    Name = "SOBOB",
    x = -165431.9,
    z = -87062.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "sobun",
    Name = "SOBUN",
    x = -77731.0,
    z = -81560.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "sodel",
    Name = "SODEL",
    x = -166108.1,
    z = -178034.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "sodex",
    Name = "SODEX",
    x = -258571.0,
    z = -73568.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "sogap",
    Name = "SOGAP",
    x = -78110.0,
    z = -110776.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "sokak",
    Name = "SOKAK",
    x = -30785.0,
    z = -253587.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "sokev",
    Name = "SOKEV",
    x = 149437.0,
    z = -257244.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "sokov",
    Name = "SOKOV",
    x = -179014.2,
    z = -176977.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "solak",
    Name = "SOLAK",
    x = 298681.5,
    z = -34370.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "solil",
    Name = "SOLIL",
    x = -86790.4,
    z = -124983.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "solud",
    Name = "SOLUD",
    x = -180924.5,
    z = 49338.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "sutvo",
    Name = "SUTVO",
    x = -101197.7,
    z = 11784.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "suvdu",
    Name = "SUVDU",
    x = -173608.9,
    z = -187264.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "tadbu",
    Name = "TADBU",
    x = -169906.7,
    z = -170345.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "tadpi",
    Name = "TADPI",
    x = -66369.6,
    z = -85208.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "tagdu",
    Name = "TAGDU",
    x = -82620.1,
    z = -290090.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "tagta",
    Name = "TAGTA",
    x = 286914.7,
    z = -262454.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "taltu",
    Name = "TALTU",
    x = -109895.7,
    z = -61123.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "tapra",
    Name = "TAPRA",
    x = -192464.7,
    z = 38672.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "tapto",
    Name = "TAPTO",
    x = -215910.2,
    z = -145823.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "tardi",
    Name = "TARDI",
    x = -177149.7,
    z = -9892.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "tatla",
    Name = "TATLA",
    x = -39542.8,
    z = -157973.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "tatmo",
    Name = "TATMO",
    x = -133406.6,
    z = -138342.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "tavno",
    Name = "TAVNO",
    x = 223030.4,
    z = 31396.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "tomdo",
    Name = "TOMDO",
    x = -145917.6,
    z = -188391.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "tonki",
    Name = "TONKI",
    x = -189592.3,
    z = -145824.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "tonvo",
    Name = "TONVO",
    x = -120676.5,
    z = 28696.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "tosna",
    Name = "TOSNA",
    x = -93100.0,
    z = -358695.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "totku",
    Name = "TOTKU",
    x = -61091.3,
    z = -218611.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "totno",
    Name = "TOTNO",
    x = 343932.8,
    z = -421110.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "toviv",
    Name = "TOVIV",
    x = -67963.8,
    z = -92187.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "tovla",
    Name = "TOVLA",
    x = -131093.1,
    z = -155502.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "tubgo",
    Name = "TUBGO",
    x = -195149.6,
    z = -106237.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "tudis",
    Name = "TUDIS",
    x = -109959.4,
    z = -111671.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "tudop",
    Name = "TUDOP",
    x = -77720.8,
    z = -49906.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "tugva",
    Name = "TUGVA",
    x = -174444.1,
    z = -136466.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "tukak",
    Name = "TUKAK",
    x = -120661.8,
    z = -72247.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "tuksi",
    Name = "TUKSI",
    x = -92579.2,
    z = -15795.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "tulax",
    Name = "TULAX",
    x = 411411.6,
    z = -694936.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "tulom",
    Name = "TULOM",
    x = -71058.8,
    z = -106341.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "tulon",
    Name = "TULON",
    x = -137054.5,
    z = -147011.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "tumak",
    Name = "TUMAK",
    x = -31198.3,
    z = -306670.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "tumex",
    Name = "TUMEX",
    x = -182132.2,
    z = -158075.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ukili",
    Name = "UKILI",
    x = -166665.0,
    z = -233675.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "uknar",
    Name = "UKNAR",
    x = 442292.0,
    z = -689843.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "uknav",
    Name = "UKNAV",
    x = -158831.7,
    z = -177282.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ukpap",
    Name = "UKPAP",
    x = -170715.4,
    z = -139177.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ukrer",
    Name = "UKRER",
    x = -69372.5,
    z = -75518.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ukrim",
    Name = "UKRIM",
    x = -87992.1,
    z = -108995.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ukrol",
    Name = "UKROL",
    x = -79394.9,
    z = -77377.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "uksul",
    Name = "UKSUL",
    x = -157565.9,
    z = -82142.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "uktad",
    Name = "UKTAD",
    x = -87031.8,
    z = -65903.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ukuvo",
    Name = "UKUVO",
    x = -103104.5,
    z = -248202.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ukvak",
    Name = "UKVAK",
    x = -144377.9,
    z = -69921.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ulado",
    Name = "ULADO",
    x = -126991.5,
    z = -70182.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ulala",
    Name = "ULALA",
    x = -193741.0,
    z = -141699.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "uldot",
    Name = "ULDOT",
    x = -117986.5,
    z = -61824.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "uldun",
    Name = "ULDUN",
    x = 26217.1,
    z = -8350.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "uliva",
    Name = "ULIVA",
    x = -77389.3,
    z = -215587.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "uloda",
    Name = "ULODA",
    x = -173550.6,
    z = -138540.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "umami",
    Name = "UMAMI",
    x = -145831.3,
    z = -21254.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "umevu",
    Name = "UMEVU",
    x = -113731.4,
    z = -316195.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "umibu",
    Name = "UMIBU",
    x = -195039.8,
    z = -177038.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "vatan",
    Name = "VATAN",
    x = 461894.5,
    z = -638715.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "vatig",
    Name = "VATIG",
    x = -168062.7,
    z = -274129.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "vatob",
    Name = "VATOB",
    x = 310731.0,
    z = -482960.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "vavas",
    Name = "VAVAS",
    x = 348138.4,
    z = -225982.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "vaxab",
    Name = "VAXAB",
    x = -82130.0,
    z = -55656.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "vaxas",
    Name = "VAXAS",
    x = -160931.8,
    z = 5154.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "vebul",
    Name = "VEBUL",
    x = -63033.1,
    z = -66924.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "vedex",
    Name = "VEDEX",
    x = -175536.0,
    z = -181331.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "vegek",
    Name = "VEGEK",
    x = -92541.1,
    z = -212780.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "vegir",
    Name = "VEGIR",
    x = -217126.8,
    z = -150063.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "vekal",
    Name = "VEKAL",
    x = -122016.5,
    z = -119812.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "vekov",
    Name = "VEKOV",
    x = -132221.9,
    z = -143961.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "velar",
    Name = "VELAR",
    x = -111382.1,
    z = -57688.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "velut",
    Name = "VELUT",
    x = 352525.1,
    z = -616118.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "vuteb",
    Name = "VUTEB",
    x = -60444.1,
    z = -138765.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "vutok",
    Name = "VUTOK",
    x = -176939.0,
    z = -200391.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "vuton",
    Name = "VUTON",
    x = -104320.8,
    z = -53264.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "vuxod",
    Name = "VUXOD",
    x = -201556.9,
    z = -167057.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "xarta",
    Name = "XARTA",
    x = -125520.8,
    z = -133393.1,
})

NASG_ATC:Log("Persian Gulf ATC tracked points loaded")
