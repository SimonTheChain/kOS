//kOS Script: Earth Orbit Insertion
//Author: Simon Lachaîne

FUNCTION HEAD {
    PARAMETER FLIGHT_MODE.
    PARAMETER LAT.
    PARAMETER LON.

    SET ShipSteer TO HEADING(LAT,LON).
    PRINT "Flight Monitor:" AT(0,30).
    
    IF FLIGHT_MODE = 1 {
        PRINT "-Changing heading according to velocity" AT(0,31).
    
    } ELSE IF FLIGHT_MODE = 2 {
        PRINT "-Changing heading according to vertical speed" AT(0,31).
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
LIST ENGINES IN AllEngines.

FOR e IN AllEngines {
    IF e:IGNITION {
        GLOBAL FirstStage IS e.
    }
}

WAIT UNTIL FirstStage:THRUST >= FirstStage:AVAILABLETHRUST.
STAGE.
UNTIL STAGE:READY {
	WAIT 0.001.
}.

PRINT "Lift-off".
PRINT " ".
PRINT "_PHASE 1_: Open-loop control".

SET Boosters to LIST().

FOR e IN AllEngines {
    IF e:IGNITION AND e:NAME <> FirstStage:NAME {
        Boosters:ADD(e).
    }
}.

IF Boosters:LENGTH >= 1 {
    WHEN Boosters[0]:FLAMEOUT THEN {
        PRINT "Discarding boosters".
        STAGE.

        UNTIL STAGE:READY {
			WAIT 0.001.
		}.
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
    HEAD(1,90,90).
    WAIT 0.001.
}.

PRINT "Initiating tilt sequence".

UNTIL FirstStage:FLAMEOUT {

    IF ShipAlt < 1000 {
        HEAD(1,90,90).
    
    } ELSE IF ShipAlt >= 1000 AND ShipAlt < 2000 {
        HEAD(1,90,85).
    
    } ELSE IF ShipAlt >= 2000 AND ShipAlt < 3000 {
        HEAD(1,90,80).
    
    } ELSE IF ShipAlt >= 3000 {

        IF ShipSpeed >= 200 AND ShipSpeed < 300 {
            HEAD(1,90,75).

        } ELSE IF ShipSpeed >= 300 AND ShipSpeed < 350 {
            HEAD(1,90,70).

        } ELSE IF ShipSpeed >= 350 AND ShipSpeed < 450 {
            HEAD(1,90,65).

        } ELSE IF ShipSpeed >= 450 AND ShipSpeed < 550 {
            HEAD(1,90,60).

        } ELSE IF ShipSpeed >= 550 AND ShipSpeed < 600 {
            HEAD(1,90,55).
        
        } ELSE IF ShipSpeed >= 600 AND ShipSpeed < 800 {
            HEAD(1,90,50).

        } ELSE IF ShipSpeed >= 800 AND ShipSpeed < 1200 {
            HEAD(1,90,45).

        } ELSE IF ShipSpeed >= 1200 AND ShipSpeed < 1800 {
            HEAD(1,90,40).

        } ELSE IF ShipSpeed >= 1800 AND ShipSpeed < 2500 {
            HEAD(1,90,35).

        } ELSE IF ShipSpeed >= 2500 {
            HEAD(1,90,30).
        
        } ELSE {
            HEAD(1,90,80).
        }

    }
    WAIT 0.001.
}.

PRINT "Staging".
STAGE.

UNTIL STAGE:READY {
	WAIT 0.001.
}.

PRINT " ".
PRINT "_PHASE 2_: Closed-loop control".

IF ApoTime >= 370 {
    LOCK THROTTLE TO 0.
    SET RefTime TO ROUND(ApoTime).

    FROM {LOCAL Mark IS RefTime-3600.} UNTIL Mark = 0 STEP {SET Mark TO Mark-1.} DO {
    	PRINT "Waiting for "+Mark+" seconds                          " AT(0,31).
    	WAIT 1.
    }.

    PRINT "Stabilizing fuel".
    LOCK THROTTLE TO 1.
    WAIT 10.
}

PRINT "Ignition".
STAGE.

UNTIL STAGE:READY {
	WAIT 0.001.
}.

SET FinalApo TO ShipApo.

UNTIL ShipPeri >= FinalApo {

	IF ShipVertical >= 50 AND ShipVertical < 100 {
		HEAD(2,90,5).

	} ELSE IF ShipVertical >= 100 AND ShipVertical < 500 {
		HEAD(2,90,10).

	} ELSE IF ShipVertical >= 500 AND ShipVertical < 1000 {
		HEAD(2,90,15).

	} ELSE IF ShipVertical >= 1000 {
		HEAD(2,90,20).

	} ELSE IF ShipVertical <= -50 AND ShipVertical > -100 {
		HEAD(2,90,5).

	} ELSE IF ShipVertical <= -100 AND ShipVertical > -500 {
		HEAD(2,90,10).

	} ELSE IF ShipVertical <= -500 AND ShipVertical > -1000 {
		HEAD(2,90,15).

	} ELSE IF ShipVertical <= -1000 {
		HEAD(2,90,20).

	} ELSE {
		HEAD(2,90,0).
	}

	IF ShipApo >= 300000 AND ShipPeri >= 150000 {
		PRINT "Apoapsis threshold reached".
		BREAK.
	}

	WAIT 0.001.
}.

PRINT "SECO".
LOCK THROTTLE TO 0.
WAIT 1.
PRINT "Staging".
STAGE.

UNTIL STAGE:READY {
	WAIT 0.001.
}.

PRINT "Payload delivered to orbit".
LOCK THROTTLE TO 1.0.
WAIT 3.
LOCK THROTTLE TO 0.
RCS OFF.
SAS ON.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
PRINT " ".
PRINT "Earth orbit insetion program completed.".