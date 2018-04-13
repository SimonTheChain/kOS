//kOS Script: Earth to Low Orbit
//Author: Simon Lachaîne

FUNCTION CHANGE_HEADING {
    PARAMETER FLIGHT_MODE.
    PARAMETER LAT.
    PARAMETER LON.

    SET SHIPSTEER TO HEADING(LAT,LON).
    PRINT "Flight Monitor:" AT(0,30).
    
    IF FLIGHT_MODE = 1 {
        PRINT "-Changing heading according to velocity" AT(0,31).
    
    } ELSE IF FLIGHT_MODE = 2 {
        PRINT "-Changing heading according to time to apoapsis" AT(0,31).
    
    } ELSE IF FLIGHT_MODE = 3 {
        PRINT "-Changing heading according to apoapsis height"+"     " AT(0,31).
    }
    
    PRINT "-Pitching to "+LON+" degrees"+"   " AT(0,32).
    PRINT "-Apoapsis: "+ROUND(SHIP:APOAPSIS,0)+"          " AT (0,33).
    PRINT "-Periapsis: "+ROUND(SHIP:PERIAPSIS,0)+"          " AT (0,34).
}.

CLEARSCREEN.
PRINT "_PHASE 0_: Launch".
SAS OFF.
RCS ON.
LOCK THROTTLE TO 1.0.
PRINT "SAS OFF, RCS ON, throttle locked to 100%".

FROM {local countdown is 10.} UNTIL countdown = -1 STEP {SET countdown to countdown - 1.} DO {

    IF countdown = 3 {
        PRINT "Countdown to launch: "+countdown+" " AT(0,2).
        PRINT " ".
        PRINT "Ignition sequence start".
        STAGE.

    } ELSE {
        PRINT "Countdown to launch: "+countdown+" " AT(0,2).
    }

    WAIT 1.
}

PRINT "Wating for maximum thrust".
LIST ENGINES IN AllEngines.

FOR e IN AllEngines {
        IF e:IGNITION {
            GLOBAL MainEngine IS e.
        }
}

WAIT UNTIL MainEngine:THRUST >= MainEngine:AVAILABLETHRUST.
STAGE.

PRINT "Launch".
PRINT " ".
PRINT "_PHASE 1_: Getting out of the atmosphere".
SET Boosters to LIST().

FOR e IN AllEngines {
    IF e:IGNITION AND e:NAME <> MainEngine:NAME {
        Boosters:ADD(e).
    }
}.

IF Boosters:LENGTH >= 1 {
    WHEN Boosters[0]:FLAMEOUT THEN {
        PRINT "Discarding boosters".
        STAGE.
    }.
}

WHEN MainEngine:FLAMEOUT THEN {
    PRINT "Staging".
    STAGE.
}.

WHEN SHIP:APOAPSIS > 140000 THEN {
    PRINT "140km apoapsis reached".
    PRINT " ".
    PRINT "_PHASE 2_: Increasing lateral velocity".
}.

WHEN SHIP:PERIAPSIS > 140000 THEN {
    PRINT "140km periapsis reached".
    PRINT " ".
    PRINT "_PHASE 3_: Circularizing orbit".
}.

SET SHIPSTEER TO HEADING(0,90).
LOCK STEERING TO SHIPSTEER.

UNTIL SHIP:ALTITUDE >= 200 {
    CHANGE_HEADING(1,0,90).
    WAIT 0.001.
}.

PRINT "Rolling to 90 degrees".
SET SHIPSTEER TO HEADING(90,90).

UNTIL SHIP:ALTITUDE >= 8000 {

    IF SHIP:VELOCITY:SURFACE:MAG < 100 {
        CHANGE_HEADING(1,90,90).

    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 100 AND SHIP:VELOCITY:SURFACE:MAG < 150 {
        CHANGE_HEADING(1,90,85).

    } ELSE IF SHIP:VELOCITY:SURFACE:MAG > 400 {
        BREAK.

    } ELSE {
        CHANGE_HEADING(1,90,80).
    }

    WAIT 0.001.
}.

UNTIL MainEngine:FLAMEOUT {

    IF SHIP:VELOCITY:SURFACE:MAG >= 150 AND SHIP:VELOCITY:SURFACE:MAG < 400 {
        CHANGE_HEADING(1,90,80).

    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 400 AND SHIP:VELOCITY:SURFACE:MAG < 500 {
        CHANGE_HEADING(1,90,75).

    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 500 AND SHIP:VELOCITY:SURFACE:MAG < 550 {
        CHANGE_HEADING(1,90,70).

    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 550 AND SHIP:VELOCITY:SURFACE:MAG < 650 {
        CHANGE_HEADING(1,90,65).

    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 650 AND SHIP:VELOCITY:SURFACE:MAG < 700 {
        CHANGE_HEADING(1,90,60).

    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 700 AND SHIP:VELOCITY:SURFACE:MAG < 850 {
        CHANGE_HEADING(1,90,55).

    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 850 AND SHIP:VELOCITY:SURFACE:MAG < 900 {
        CHANGE_HEADING(1,90,50).

    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 900 AND SHIP:VELOCITY:SURFACE:MAG < 1100 {
        CHANGE_HEADING(1,90,45).

    } ELSE IF SHIP:VELOCITY:SURFACE:MAG >= 1100 AND SHIP:VELOCITY:SURFACE:MAG < 1500 {
        CHANGE_HEADING(1,90,40).

    } ELSE IF SHIP:VELOCITY:SURFACE:MAG > 1500 {
        CHANGE_HEADING(1,90,30).
    }.
    
    WAIT 0.001.
}.

FOR e IN AllEngines {
    IF e:IGNITION AND NOT e:FLAMEOUT {
        GLOBAL CurrentEngine IS e.
    }
}

LOCK apo_time TO ETA:APOAPSIS.

UNTIL CurrentEngine:FLAMEOUT{
    SET elapsed_time TO ETA:APOAPSIS.
    WAIT 0.001.
    SET time_diff TO (elapsed_time/apo_time).

    IF time_diff >= 0 AND time_diff < 1 {
        CHANGE_HEADING(2,90,15).
    
    } ELSE IF time_diff >= 1 AND time_diff < 2 {
        CHANGE_HEADING(2,90,20).
    }
}.

IF apo_time >= 130 {
    LOCK THROTTLE TO 0.
    SET mark TO apo_time-120.
    PRINT "Waiting for "+ROUND(mark)+" seconds".
    WAIT mark.
    PRINT "Stabilizing fuel".
    LOCK THROTTLE TO 1.
    WAIT 10.
}

PRINT "Staging".
STAGE.
SET final_apo TO SHIP:APOAPSIS.

FOR e IN AllEngines {
    IF e:IGNITION AND NOT e:FLAMEOUT {
        GLOBAL LastEngine IS e.
    }
}.

UNTIL SHIP:PERIAPSIS >= final_apo {
    
    IF apo_time <= 600 {

        IF SHIP:APOAPSIS > final_apo+1000 {
            CHANGE_HEADING(3,90,-5).
        
        } ELSE IF SHIP:APOAPSIS < final_apo-1000 {
            CHANGE_HEADING(3,90,5).
        
        } ELSE {
            CHANGE_HEADING(3,90,0).
        }

    } ELSE {

        IF SHIP:APOAPSIS > final_apo+1000 {
            CHANGE_HEADING(3,90,10).
        
        } ELSE IF SHIP:APOAPSIS < final_apo-1000 {
            CHANGE_HEADING(3,90,-10).
        
        } ELSE {
            CHANGE_HEADING(3,90,0).
        }

    }

    IF SHIP:APOAPSIS >= 500000 AND SHIP:PERIAPSIS >= 150000 {
        PRINT "Maximum apoapsis reached".
        BREAK.
    }

    IF LastEngine:FLAMEOUT {
        PRINT "Engine flameout".
        BREAK.
    }

    WAIT 0.001.
}.

LOCK THROTTLE TO 0.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
RCS OFF.
SAS ON.
PRINT "SAS ON, RCS OFF, throttle locked to 0%".
//STAGE.
//PRINT "Payload delivered to orbit".
PRINT " ".
PRINT "Earth to orbit program completed.".