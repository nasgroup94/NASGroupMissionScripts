-- This is an example of a global
local ACMI = MISSILETRAINER
  :New( 200, "ACMI pods now active" )
  :InitMessagesOnOff(true)
  :InitAlertsToAll(true) 
  :InitAlertsHitsOnOff(true)
  :InitAlertsLaunchesOnOff(false) -- I'll put it on below ...
  :InitBearingOnOff(false)
  :InitRangeOnOff(false)
  :InitTrackingOnOff(false)
  :InitTrackingToAll(false)
  :InitMenusOnOff(false)

ACMI:InitAlertsToAll(true) -- Now alerts are also on