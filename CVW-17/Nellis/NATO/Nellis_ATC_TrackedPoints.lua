NASG_ATC = NASG_ATC or {}

---------------------------------------------------------------------------
-- Nevada (NTTR) tracked points.
--
-- Named locations pilots can request a vector to that aren't flight-plan
-- waypoints: tankers, AWACS stations, bullseye, range entry points, etc.
-- Loaded after Nellis_ATC_Config.lua and before Nellis_ATC_Procedures.lua
-- (procedures reference these points by Id/Name/Alias).
--
-- Exactly one location method per point (checked in this priority order
-- if more than one is given): UnitName > GroupName > StaticName > a flat
-- coordinate (x/z, the DCS map grid, or lat/lon).
--
-- x/z values below are placeholders — replace with real NTTR mission-editor
-- coordinates for your mission; they only illustrate the schema here.
--
-- The four points below (shell71, cowboy_station, bullseye, dreamland_entry,
-- reno_gate) are referenced by Id from Nellis_ATC_Procedures.lua — keep
-- their Ids stable if you edit them.
---------------------------------------------------------------------------

-- Vector to a live tanker unit (tracks its current position).
NASG_ATC:RegisterTrackedPoint({
    Id = "shell71",
    Name = "Shell 71",
    UnitName = "Shell-7-1",
})

-- Vector to a live AWACS/E-3 group (uses the group leader's position).
NASG_ATC:RegisterTrackedPoint({
    Id = "cowboy_station",
    Name = "Cowboy Station",
    GroupName = "Cowboy AWACS Group",
})

-- Fixed DCS map coordinate (x/z) — bullseye.
NASG_ATC:RegisterTrackedPoint({
    Id = "bullseye",
    Name = "Bullseye",
    x = -270000.0,
    z = -430000.0,
})

-- Fixed lat/lon coordinate, with an alias — a range entry point.
NASG_ATC:RegisterTrackedPoint({
    Id = "dreamland_entry",
    Name = "Dreamland Entry",
    Aliases = { "Dreamland" },
    lat = 37.28,
    lon = -115.80,
})

-- Fixed x/z coordinate — a second range entry point, used by the map-wide
-- recovery procedure in Nellis_ATC_Procedures.lua.
NASG_ATC:RegisterTrackedPoint({
    Id = "reno_gate",
    Name = "Reno Gate",
    x = -180000.0,
    z = -520000.0,
})

---------------------------------------------------------------------------
-- NTTR nav fixes, imported from the mission-editor nav_points table for
-- this theater. 149 named fixes across the range complex, each reachable
-- via "request direct <name>" / "vector to <name>" from Center or
-- Clearance (see ATC_Command_Reference.txt). Coordinates are copied
-- straight from the source mission file's nav_points table (x = nav_points
-- x, z = nav_points y) -- no conversion needed.
---------------------------------------------------------------------------

NASG_ATC:RegisterTrackedPoint({
    Id = "nixon",
    Name = "NIXON",
    x = -365896.0,
    z = -63074.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "jettison_hill",
    Name = "JETTISON HILL",
    x = -387502.0,
    z = -16234.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "dry_lake",
    Name = "DRY LAKE",
    x = -372943.0,
    z = -3251.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "acton",
    Name = "ACTON",
    x = -341113.4,
    z = 19613.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "timbr",
    Name = "TIMBR",
    x = -340513.4,
    z = 7487.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "tbird_lake",
    Name = "TBIRD LAKE",
    x = -317196.0,
    z = -35991.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "arcoe",
    Name = "ARCOE",
    x = -342224.0,
    z = -8007.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "junno",
    Name = "JUNNO",
    x = -343010.0,
    z = -4641.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "bighorn",
    Name = "BIGHORN",
    x = -217183.4,
    z = -21008.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "reveille_gap",
    Name = "REVEILLE GAP",
    x = -191228.3,
    z = -18632.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "cesar",
    Name = "CESAR",
    x = -314150.0,
    z = -150279.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "student_gap",
    Name = "STUDENT GAP",
    x = -245289.4,
    z = -14381.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "dream",
    Name = "DREAM",
    x = -294162.0,
    z = -15746.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "duck",
    Name = "DUCK",
    x = -391036.6,
    z = -4055.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "flush",
    Name = "FLUSH",
    x = -331960.3,
    z = -134956.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "garth",
    Name = "GARTH",
    x = -281740.9,
    z = -136783.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "leach_lake",
    Name = "LEACH LAKE",
    x = -467592.0,
    z = -164819.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "leeee",
    Name = "LEEEE",
    x = -390018.6,
    z = -62284.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "stryk",
    Name = "STRYK",
    x = -377694.3,
    z = -60578.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "mesae",
    Name = "MESAE",
    x = -376975.1,
    z = -65970.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "dudbe",
    Name = "DUDBE",
    x = -384414.9,
    z = -45340.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "strip",
    Name = "STRIP",
    x = -386614.9,
    z = -39170.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "lotus",
    Name = "LOTUS",
    x = -283699.1,
    z = -16657.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "makzi",
    Name = "MAKZI",
    x = -314032.3,
    z = -135723.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "mintt",
    Name = "MINTT",
    x = -345405.1,
    z = -24720.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "moose",
    Name = "MOOSE",
    x = -243323.7,
    z = 63777.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "mopar",
    Name = "MOPAR",
    x = -283694.4,
    z = -171835.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "nugge",
    Name = "NUGGE",
    x = -298584.3,
    z = -6394.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "piute",
    Name = "PIUTE",
    x = -368975.4,
    z = -112935.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "rock",
    Name = "ROCK",
    x = -362711.7,
    z = -100043.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "queen",
    Name = "QUEEN",
    x = -304692.0,
    z = -22678.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "sarah",
    Name = "SARAH",
    x = -357353.7,
    z = -42007.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "stonewall",
    Name = "STONEWALL",
    x = -259686.3,
    z = -198416.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ronky",
    Name = "RONKY",
    x = -351382.6,
    z = -9437.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "vettt",
    Name = "VETTT",
    x = -354350.0,
    z = 21746.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "fyttr",
    Name = "FYTTR",
    x = -385650.0,
    z = -76565.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "tucky",
    Name = "TUCKY",
    x = -360451.4,
    z = -194146.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "acosu",
    Name = "ACOSU",
    x = -360766.3,
    z = 919.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kutme",
    Name = "KUTME",
    x = -367705.1,
    z = 8885.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "balbe",
    Name = "BALBE",
    x = -379382.0,
    z = -1376.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "carub",
    Name = "CARUB",
    x = -388319.8,
    z = -8766.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "rockx",
    Name = "ROCKX",
    x = -400637.7,
    z = -19570.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "engla",
    Name = "ENGLA",
    x = -408512.0,
    z = -26032.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "husts",
    Name = "HUSTS",
    x = -419319.1,
    z = -35048.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "lucil",
    Name = "LUCIL",
    x = -426996.3,
    z = -41454.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "hokum",
    Name = "HOKUM",
    x = -373228.0,
    z = -13679.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ryaan",
    Name = "RYAAN",
    x = -386756.6,
    z = -22639.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "elvis",
    Name = "ELVIS",
    x = -286689.6,
    z = -83139.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "alaska",
    Name = "ALASKA",
    x = -205863.7,
    z = -10992.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "boston",
    Name = "BOSTON",
    x = -205078.9,
    z = 21220.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "california",
    Name = "CALIFORNIA",
    x = -265212.3,
    z = -174832.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "chicago",
    Name = "CHICAGO",
    x = -206148.6,
    z = -24170.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "dover",
    Name = "DOVER",
    x = -229125.4,
    z = 21852.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "filtr",
    Name = "FILTR",
    x = -252961.4,
    z = 62278.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "hockum",
    Name = "HOCKUM",
    x = -306672.0,
    z = -20857.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "jackson",
    Name = "JACKSON",
    x = -267177.1,
    z = -22910.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "miami",
    Name = "MIAMI",
    x = -281548.0,
    z = -3028.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "mule",
    Name = "MULE",
    x = -180840.9,
    z = -5171.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "new_york",
    Name = "NEW YORK",
    x = -242853.1,
    z = -10167.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "phinn",
    Name = "PHINN",
    x = -00389987,
    z = -00010730,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "pine",
    Name = "PINE",
    x = -204794.9,
    z = 74096.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "raleigh",
    Name = "RALEIGH",
    x = -262415.7,
    z = 22720.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "salem",
    Name = "SALEM",
    x = -231898.9,
    z = -164632.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "san_diego",
    Name = "SAN DIEGO",
    x = -259634.6,
    z = -164533.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "seattle",
    Name = "SEATTLE",
    x = -217104.3,
    z = -164684.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "st_louis",
    Name = "ST LOUIS",
    x = -230190.0,
    z = -23672.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "virginia",
    Name = "VIRGINIA",
    x = -261346.0,
    z = -9758.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "faang",
    Name = "FAANG",
    x = -313981.4,
    z = -335030.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ewald",
    Name = "EWALD",
    x = -292370.3,
    z = -294278.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "hambo",
    Name = "HAMBO",
    x = -292775.4,
    z = -250940.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "harne",
    Name = "HARNE",
    x = -323459.1,
    z = -210770.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "heiny",
    Name = "HEINY",
    x = -446225.0,
    z = -151396.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "jenid",
    Name = "JENID",
    x = -386694.9,
    z = -181285.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "daggs",
    Name = "DAGGS",
    x = -538832.6,
    z = -189433.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "rosie",
    Name = "ROSIE",
    x = -552770.3,
    z = -304308.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "chads",
    Name = "CHADS",
    x = -508110.9,
    z = -338044.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "romof",
    Name = "ROMOF",
    x = -445254.6,
    z = -337184.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "swoop",
    Name = "SWOOP",
    x = -389789.4,
    z = -336280.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "kiote",
    Name = "KIOTE",
    x = -361493.1,
    z = -336263.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "mitel",
    Name = "MITEL",
    x = -348928.0,
    z = -335608.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "adder",
    Name = "ADDER",
    x = -331802.0,
    z = -53414.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "alamo_lz",
    Name = "ALAMO LZ",
    x = -273868.3,
    z = -33776.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "keno",
    Name = "KENO",
    x = -231036.3,
    z = -127623.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "mellan_lz",
    Name = "MELLAN LZ",
    x = -239169.7,
    z = -160814.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "pipeline",
    Name = "PIPELINE",
    x = -233016.0,
    z = -119088.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "rebel",
    Name = "REBEL",
    x = -225333.1,
    z = -131277.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "sand",
    Name = "SAND",
    x = -225721.7,
    z = -110630.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "token",
    Name = "TOKEN",
    x = -229008.3,
    z = -138544.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "tres_burros",
    Name = "TRES BURROS",
    x = -296242.9,
    z = -176936.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "mmm",
    Name = "MMM",
    x = -337286.6,
    z = 48996.5,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "bty",
    Name = "BTY",
    x = -337247.1,
    z = -171485.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "bih",
    Name = "BIH",
    x = -272455.7,
    z = -314983.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "jordn",
    Name = "JORDN",
    x = -380519.1,
    z = -36449.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "jaysn",
    Name = "JAYSN",
    x = -362012.3,
    z = -108169.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "lidat",
    Name = "LIDAT",
    x = -267396.9,
    z = -218591.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ins",
    Name = "INS",
    x = -360368.6,
    z = -75045.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "lsv",
    Name = "LSV",
    x = -397136.0,
    z = -16545.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "bld",
    Name = "BLD",
    x = -424416.0,
    z = -1461.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "mcynb",
    Name = "MCYNB",
    x = -356041.7,
    z = -107049.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "oal",
    Name = "OAL",
    x = -203562.3,
    z = -261642.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "mva",
    Name = "MVA",
    x = -140979.1,
    z = -283977.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "tph",
    Name = "TPH",
    x = -200809.4,
    z = -196937.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "grl",
    Name = "GRL",
    x = -288771.7,
    z = -87782.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "ilc",
    Name = "ILC",
    x = -173244.0,
    z = 34027.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "mlf",
    Name = "MLF",
    x = -156700.9,
    z = 154376.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "cdc",
    Name = "CDC",
    x = -220521.7,
    z = 152270.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "bce",
    Name = "BCE",
    x = -228309.7,
    z = 220166.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "pgs",
    Name = "PGS",
    x = -462206.9,
    z = 118969.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "gfs",
    Name = "GFS",
    x = -520916.9,
    z = -27855.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "janav",
    Name = "JANAV",
    x = -215371.0,
    z = -179400.8,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "modme",
    Name = "MODME",
    x = -238475.1,
    z = -169790.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "osrie",
    Name = "OSRIE",
    x = -223963.1,
    z = -175769.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "jadpu",
    Name = "JADPU",
    x = -196632.3,
    z = -187252.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "jepar",
    Name = "JEPAR",
    x = -203480.0,
    z = -184433.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "jirem",
    Name = "JIREM",
    x = -251224.0,
    z = -164253.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "hubon",
    Name = "HUBON",
    x = -256263.7,
    z = -157832.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "tumbe",
    Name = "TUMBE",
    x = -336674.6,
    z = -164336.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "stoff",
    Name = "STOFF",
    x = -268631.1,
    z = -153453.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "apex",
    Name = "APEX",
    x = -384009.5,
    z = -6010.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "flex",
    Name = "FLEX",
    x = -389881.7,
    z = -17981.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "craig",
    Name = "CRAIG",
    x = -396281.4,
    z = -26690.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "simns",
    Name = "SIMNS",
    x = -392500.3,
    z = -30481.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "lv_blvd",
    Name = "LV BLVD",
    x = -399346,
    z = -21715,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "tqq",
    Name = "TQQ",
    x = -227436.9,
    z = -174559.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "dag",
    Name = "DAG",
    x = -541074.6,
    z = -155482.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "hec",
    Name = "HEC",
    x = -559340.6,
    z = -144867.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "eed",
    Name = "EED",
    x = -560034.9,
    z = 37194.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "las",
    Name = "LAS",
    x = -415686.2,
    z = -28303.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "sand_dunes",
    Name = "SAND DUNES",
    x = -356037.6,
    z = -9513.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "rammm",
    Name = "RAMMM",
    x = -340093.8,
    z = 22959.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "tcn_lla_69y",
    Name = "TCN LLA - 69Y",
    x = -458054.7,
    z = -148858.0,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "stuckeys_pk",
    Name = "STUCKEYS PK",
    x = -305356.6,
    z = 7520.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "antelope_pk",
    Name = "ANTELOPE PK",
    x = -245476.3,
    z = -172790.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "belted_pk",
    Name = "BELTED PK",
    x = -251888.9,
    z = -112307.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "black_mt",
    Name = "BLACK MT",
    x = -283663.4,
    z = -162232.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "cedar_pk",
    Name = "CEDAR PK",
    x = -237287.7,
    z = -135227.7,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "coyote_pk",
    Name = "COYOTE PK",
    x = -244941.4,
    z = -73395.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "crystal_spring",
    Name = "CRYSTAL SPRING",
    x = -254522.3,
    z = -37904.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "gass_pk",
    Name = "GASS PK",
    x = -379923.1,
    z = -30694.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "mt_helen",
    Name = "MT HELEN",
    x = -260100.0,
    z = -171264.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "mt_irish",
    Name = "MT IRISH",
    x = -242765.7,
    z = -52834.3,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "nixon_pk",
    Name = "NIXON PK",
    x = -217580.6,
    z = -147505.4,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "reveille_pk",
    Name = "REVEILLE PK",
    x = -219577.4,
    z = -117758.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "quartzite_mt",
    Name = "QUARTZITE MT",
    x = -257623.1,
    z = -134345.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "caliente",
    Name = "CALIENTE",
    x = -243843.4,
    z = 25181.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "devils_gap",
    Name = "DEVILS GAP",
    x = -230553.4,
    z = 68349.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "mormon_pk",
    Name = "MORMON PK",
    x = -315120.3,
    z = 28478.6,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "alamo",
    Name = "ALAMO",
    x = -281037.4,
    z = -28138.9,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "hayford_pk",
    Name = "HAYFORD PK",
    x = -350780.6,
    z = -29579.1,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "eagle_mt",
    Name = "EAGLE MT",
    x = -402473.4,
    z = -135888.2,
})

NASG_ATC:RegisterTrackedPoint({
    Id = "india",
    Name = "INDIA",
    x = -229158.2,
    z = -100288.4,
})

NASG_ATC:Log("Nevada ATC tracked points loaded")
