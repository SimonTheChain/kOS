FUNCTION CHANGE_HEADING {
    PARAMETER PHASE.
    PARAMETER LAT.
    PARAMETER LON.

    SET SHIPSTEER TO HEADING(LAT,LON).
    PRINT "Flight Monitor:" AT(0,30).
    IF PHASE = 1 {
        PRINT "-Changing heading according to velocity" AT(0,31).
    } ELSE IF PHASE = 2 {
        PRINT "-Changing heading according to time to apoapsis" AT(0,31).
    } ELSE IF PHASE = 3 {
        PRINT "-Changing heading according to apoapsis altitude" AT(0,31).
    }
    PRINT "-Pitching to "+LON+" degrees" AT(0,32).
    PRINT "-Apoapsis: "+ROUND(SHIP:APOAPSIS,0) AT (0,33).
    PRINT "-Periapsis: "+ROUND(SHIP:PERIAPSIS,0) AT (0,34).
}.

CLEARSCREEN.
//Phase 0
PRINT "_PHASE 0_: Launch".
SAS OFF.
RCS ON.
LOCK THROTTLE TO 1.0.
PRINT "SAS OFF, RCS ON, throttle locked to 100%".
PRINT "Countdown to launch:".

FROM {local countdown is 10.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
    
    IF countdown = 3 {
        PRINT "..."+countdown AT(0,3).
        PRINT " ".
        PRINT "...Ignition sequence start".
        STAGE.
    } ELSE {
        PRINT "..."+countdown AT(0,3).
    }
    WAIT 1.
}

PRINT "    " AT(0,3).
PRINT " ".
PRINT "...Wating for maximum thrust".
LIST ENGINES IN AllEngines.
FOR e IN AllEngines {
    IF e:IGNITION {
        GLOBAL MainEngine IS e.
    }
}.

WAIT UNTIL MainEngine:THRUST >= MainEngine:AVAILABLETHRUST.
STAGE.
PRINT "Launch".

WHEN MAXTHRUST = 0 THEN {
    PRINT "Staging".
    STAGE.
    LIST ENGINES IN StagingEngines.

    IF StagingEngines:LENGTH > 2 {
        PRESERVE.
    }
}.

SET SHIPSTEER TO HEADING(90,90).
LOCK STEERING TO SHIPSTEER.

//Phase 1
PRINT " ".
PRINT "_PHASE 1_: Getting out of the atmosphere".
UNTIL SHIP:APOAPSIS > 140000 {

    IF SHIP:VELOCITY:SURFACE:MAG < 100 {
        CHANGE_HEADING(1,90,90).

    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 100 AND SHIP:VELOCITY:SURFACE:MAG < 150 {
        CHANGE_HEADING(1,90,85).

    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 150 AND SHIP:VELOCITY:SURFACE:MAG < 350 {
        CHANGE_HEADING(1,90,80).

    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 350 AND SHIP:VELOCITY:SURFACE:MAG < 450 {
        CHANGE_HEADING(1,90,75).

    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 450 AND SHIP:VELOCITY:SURFACE:MAG < 500 {
        CHANGE_HEADING(1,90,70).

    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 500 AND SHIP:VELOCITY:SURFACE:MAG < 650 {
        CHANGE_HEADING(1,90,65).

    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 650 AND SHIP:VELOCITY:SURFACE:MAG < 800 {
        CHANGE_HEADING(1,90,60).

    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 800 AND SHIP:VELOCITY:SURFACE:MAG < 850 {
        CHANGE_HEADING(1,90,55).

    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 850 AND SHIP:VELOCITY:SURFACE:MAG < 900 {
        CHANGE_HEADING(1,90,50).

    } ELSE IF SHIP:VELOCITY:SURFACE:MAG > 900 {
        CHANGE_HEADING(1,90,45).
    }.
    WAIT 0.001.
}.
PRINT "140km apoapsis reached".

UNTIL MainEngine:FLAMEOUT {
    CHANGE_HEADING(2,90,40).
}.

//Phase 2
PRINT " ".
PRINT "_PHASE 2_: Increasing lateral velocity".
LIST ENGINES IN StageEngines.
FOR e IN StageEngines {
    IF e:IGNITION {
        GLOBAL CurrentEngine IS e.
    }
}.

UNTIL CurrentEngine:FLAMEOUT {
    
    IF ETA:APOAPSIS < 60 {
        CHANGE_HEADING(2,90,40).
    
    } ELSE IF ETA:APOAPSIS >= 60 AND ETA:APOAPSIS < 120 {
        CHANGE_HEADING(2,90,35).

    } ELSE IF ETA:APOAPSIS >= 120 AND ETA:APOAPSIS < 180 {
        CHANGE_HEADING(2,90,30).

    } ELSE IF ETA:APOAPSIS >= 180 AND ETA:APOAPSIS < 240 {
        CHANGE_HEADING(2,90,25).

    } ELSE IF ETA:APOAPSIS >= 240 AND ETA:APOAPSIS < 300 {
        CHANGE_HEADING(2,90,20).
    
    } ELSE {
        CHANGE_HEADING(2,90,15).
    } 
    WAIT 0.001.
}
PRINT "Engine flame-out".
LOCK THROTTLE TO 0.

//Phase 3
PRINT " ".
PRINT "_PHASE 3_: Circularizing the orbit".
SET apo TO ETA:APOAPSIS.
SET mark TO apo/2+120.
WAIT UNTIL mark.
PRINT "Throttle to 100% for 10s".
LOCK THROTTLE TO 1.
WAIT 10.
PRINT "Staging".
STAGE.

UNTIL SHIP:PERIAPSIS > 150000 {

    IF ETA:APOAPSIS < 15 {
        CHANGE_HEADING(2,90,0).
    
    } ELSE IF ETA:APOAPSIS >= 15 AND ETA:APOAPSIS < 30 {
        CHANGE_HEADING(2,90,2).

    } ELSE IF ETA:APOAPSIS >= 30 AND ETA:APOAPSIS < 60 {
        CHANGE_HEADING(2,90,4).

    } ELSE IF ETA:APOAPSIS >= 60 AND ETA:APOAPSIS < 90 {
        CHANGE_HEADING(2,90,8).

    } ELSE IF ETA:APOAPSIS >= 90 AND ETA:APOAPSIS < 120 {
        CHANGE_HEADING(2,90,12).
    
    } ELSE {
        CHANGE_HEADING(2,90,-8).
    } 
    WAIT 0.001.
}.
PRINT "150km periapsis reached".

PRINT "Engine cut-off".
LOCK THROTTLE TO 0.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
RCS OFF.
SAS ON.
PRINT " ".
PRINT "Orbital launch program completed.".