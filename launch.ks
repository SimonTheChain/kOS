//kOS Script: Earth Orbit Insertion
//Author: Simon Lachaîne

DECLARE PARAMETER DesiredPeri.

FUNCTION HEAD {
    PARAMETER FLIGHT_MODE.
    PARAMETER LAT.
    PARAMETER LON.

    SET ShipSteer TO HEADING(LAT,LON).
    PRINT "Flight Monitor:" AT(0,30).
    
    IF FLIGHT_MODE = 1 {
        PRINT "-Changing heading according to altitude" AT(0,31).
    
    } ELSE IF FLIGHT_MODE = 2 {
        PRINT "-Changing heading according to velocity" AT(0,31).
    
    } ELSE IF FLIGHT_MODE = 3 {
        PRINT "-Changing heading according to time to apoapsis     " AT(0,31).
    }
    
    PRINT "-Pitching to "+LON+" degrees"+"   " AT(0,32).
    PRINT "-Apoapsis: "+ROUND(SHIP:APOAPSIS,0)+"          " AT (0,33).
    PRINT "-Periapsis: "+ROUND(SHIP:PERIAPSIS,0)+"          " AT (0,34).
}.

CLEARSCREEN.
LOCK ShipApo TO SHIP:APOAPSIS.
LOCK ShipPeri TO SHIP:PERIAPSIS.
LOCK ShipSpeed TO SHIP:VELOCITY:SURFACE:MAG.
LOCK ShipAlt TO SHIP:ALTITUDE.
LOCK ApoTime TO ETA:APOAPSIS.
LOCK ShipVertical TO SHIP:VERTICALSPEED.
LIST ENGINES IN AllEngines.

PRINT "_PHASE 0_: Launch".
SAS OFF.
RCS ON.
LOCK THROTTLE TO 1.0.

FROM {local Countdown is 10.} UNTIL Countdown = 0 STEP {SET Countdown TO Countdown - 1.} DO {

    IF Countdown = 3 {
        PRINT "Countdown: "+Countdown+" " AT(0,1).
        PRINT "C".
        PRINT "Ignition".
        STAGE.

    } ELSE {
        PRINT "Countdown: "+Countdown+" " AT(0,1).
    }
    WAIT 1.
}

PRINT "Wating for maximum thrust".

SET FirstStageEngines TO LIST().
FOR e IN AllEngines {
    IF e:IGNITION {
        FirstStageEngines:ADD(e).
    }
}

FOR e IN FirstStageEngines {
    WAIT UNTIL e:THRUST >= e:AVAILABLETHRUST.
}

STAGE.
PRINT "Lift-off".
PRINT " ".
UNTIL STAGE:READY {
	WAIT 0.001.
}.

PRINT "_PHASE 1_: Open-loop control".

SET Boosters TO LIST().
FOR e IN AllEngines {
    IF e:IGNITION {
        IF NOT FirstStageEngines:CONTAINS(e) {
            Boosters:ADD(e).
        }
    }
}.

IF Boosters:LENGTH >= 1 {
    WHEN Boosters[0]:FLAMEOUT THEN {
        PRINT "Discarding boosters".
        STAGE.
    }.
}

SET ShipSteer TO HEADING(0,90).
LOCK STEERING TO ShipSteer.

UNTIL ShipAlt >= 200 {
    HEAD(1,0,90).
    WAIT 0.001.
}.

PRINT "Rolling to flight azimuth".

UNTIL ShipSpeed >= 100 {
    HEAD(2,90,90).
    WAIT 0.001.
}.

PRINT "Initiating tilt sequence".

UNTIL ShipApo >= DesiredPeri {

    IF ShipAlt < 1000 {
        HEAD(1,90,90).
    
    } ELSE IF ShipAlt >= 1000 AND ShipAlt < 2000 {
        HEAD(1,90,85).
    
    } ELSE IF ShipAlt >= 2000 AND ShipAlt < 3000 {
        HEAD(1,90,80).
    
    } ELSE IF ShipAlt >= 3000 {

        IF ShipSpeed >= 200 AND ShipSpeed < 300 {
            HEAD(2,90,75).

        } ELSE IF ShipSpeed >= 300 AND ShipSpeed < 350 {
            HEAD(2,90,70).

        } ELSE IF ShipSpeed >= 350 AND ShipSpeed < 450 {
            HEAD(2,90,65).

        } ELSE IF ShipSpeed >= 450 AND ShipSpeed < 550 {
            HEAD(2,90,60).

        } ELSE IF ShipSpeed >= 550 AND ShipSpeed < 600 {
            HEAD(2,90,55).
        
        } ELSE IF ShipSpeed >= 600 AND ShipSpeed < 800 {
            HEAD(2,90,50).

        } ELSE IF ShipSpeed >= 800 AND ShipSpeed < 1200 {
            HEAD(2,90,45).

        } ELSE IF ShipSpeed >= 1200 AND ShipSpeed < 1600 {
            HEAD(2,90,40).

        } ELSE IF ShipSpeed >= 1600 {
            HEAD(2,90,35).
        
        } ELSE {
            HEAD(2,90,80).
        }

    }
    WAIT 0.001.
}.

UNTIL FirstStageEngines[0]:FLAMEOUT {

    IF ApoTime <= 60 {
        HEAD(3,90,25).

    } ELSE IF ApoTime > 60 AND ApoTime <= 180 {
        HEAD(3,90,15).

    } ELSE {
        HEAD(3,90,5).
    }
    WAIT 0.001.
}

PRINT "Staging".
STAGE.

UNTIL STAGE:READY {
	WAIT 0.001.
}.

SET FinalPeri TO DesiredPeri.
PRINT " ".
PRINT "_PHASE 2_: Closed-loop control".
PRINT "Desired periapsis set to "+ROUND(FinalPeri)+" meters".
PRINT "Ignition".

STAGE.

UNTIL STAGE:READY {
    WAIT 0.001.
}.

LIST ENGINES IN UpperEngines.
FOR e IN UpperEngines {
    IF e:IGNITION {
        GLOBAL CurrentEngine IS e.
    }
}

IF ApoTime >= 180 {
    SET Pitch TO 0.

} ELSE {
    SET Pitch TO 5.

}

UNTIL ShipPeri >= FinalPeri {
    HEAD(3,90,Pitch).

    IF CurrentEngine:FLAMEOUT {
        PRINT "Staging".
        STAGE.

        UNTIL STAGE:READY {
            WAIT 0.001.
        }.

        PRINT "Ignition".
        STAGE.

        UNTIL STAGE:READY {
            WAIT 0.001.
        }.

        FOR e IN UpperEngines {
            IF e:IGNITION {
                SET CurrentEngine TO e.
            }
        }

    }
    WAIT 0.001.
}.

PRINT "SECO".
LOCK THROTTLE TO 0.
RCS OFF.
SAS ON.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
PRINT " ".
PRINT "Earth orbit insertion program completed.".