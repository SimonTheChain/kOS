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
        PRINT "-Changing heading according to time to apoapsis" AT(0,31).
    
    } ELSE IF FLIGHT_MODE = 3 {
        PRINT "-Changing heading according to apoapsis height     " AT(0,31).
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
SET FinalApo TO 180000.
SET TempApo TO 200000.

PRINT "_PHASE 0_: Launch".
SAS OFF.
RCS ON.
LOCK THROTTLE TO 1.0.
PRINT "SAS OFF, RCS ON, throttle locked to 100%".

FROM {local Countdown is 10.} UNTIL Countdown = 0 STEP {SET Countdown TO Countdown - 1.} DO {

    IF Countdown = 3 {
        PRINT "Countdown to launch: "+Countdown+" " AT(0,2).
        PRINT "C".
        PRINT "Ignition sequence start".
        STAGE.

    } ELSE {
        PRINT "Countdown to launch: "+Countdown+" " AT(0,2).
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

PRINT "Launch".
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
    }.
}

SET ShipSteer TO HEADING(0,90).
LOCK STEERING TO ShipSteer.

UNTIL ShipAlt >= 200 {
    HEAD(1,0,90).
    WAIT 0.001.
}.

PRINT "Rolling to 90 degrees".

UNTIL ShipSpeed >= 100 {
    HEAD(1,90,90).
    WAIT 0.001.
}.

PRINT "Initiating tilt sequence".

WHEN ShipSpeed >= 2000 THEN {
	PRINT " ".
	PRINT "_PHASE 2_: Closed-loop control".
}.

UNTIL FirstStage:FLAMEOUT {

    IF ShipAlt < 1000 {
        HEAD(1,90,90).
    
    } ELSE IF ShipAlt >= 1000 AND ShipAlt < 2000 {
        HEAD(1,90,85).
    
    } ELSE IF ShipAlt >= 2000 AND ShipAlt < 3000 {
        HEAD(1,90,80).
    
    } ELSE IF ShipAlt >= 3000 {

        IF ShipSpeed >= 250 AND ShipSpeed < 300 {
            HEAD(1,90,75).

        } ELSE IF ShipSpeed >= 300 AND ShipSpeed < 350 {
            HEAD(1,90,70).

        } ELSE IF ShipSpeed >= 350 AND ShipSpeed < 450 {
            HEAD(1,90,65).

        } ELSE IF ShipSpeed >= 450 AND ShipSpeed < 550 {
            HEAD(1,90,60).

        } ELSE IF ShipSpeed >= 550 AND ShipSpeed < 650 {
            HEAD(1,90,55).
        
        } ELSE IF ShipSpeed >= 650 AND ShipSpeed < 800 {
            HEAD(1,90,50).

        } ELSE IF ShipSpeed >= 800 AND ShipSpeed < 900 {
            HEAD(1,90,45).

        } ELSE IF ShipSpeed >= 900 AND ShipSpeed < 1000 {
            HEAD(1,90,40).

        } ELSE IF ShipSpeed >= 1000 AND ShipSpeed < 1200 {
            HEAD(1,90,35).

        } ELSE IF ShipSpeed >= 1200 AND ShipSpeed < 1400 {
            HEAD(1,90,33).

        } ELSE IF ShipSpeed >= 1400 AND ShipSpeed < 1600 {
            HEAD(1,90,20).

        } ELSE IF ShipSpeed >= 1600 AND ShipSpeed < 2000 {
            HEAD(1,90,15).

        } ELSE IF ShipSpeed >= 2000 {
            
            IF ShipApo >= TempApo+1000 {
            	HEAD(3,90,-5).
            
            } ELSE IF ShipApo >= TempApo-1000 AND ShipApo < TempApo+1000 {
            	HEAD(3,90,0).

            } ELSE IF ShipApo <= TempApo-1000 {
            	HEAD(3,90,10).
            }
        
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

IF ApoTime >= 130 {
    LOCK THROTTLE TO 0.
    SET RefTime TO ROUND(ApoTime).

    FROM {LOCAL Mark IS RefTime-120.} UNTIL Mark = 0 STEP {SET Mark TO Mark-1.} DO {
    	PRINT "Waiting for "+Mark+" seconds                " AT(0,31).
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

UNTIL ShipPeri >= FinalApo {

    SET RefTime TO ApoTime.
    WAIT 0.001.
    
    IF ApoTime <= 600 {

        IF ShipApo > FinalApo+1000 {
            HEAD(3,90,-5).
        
        } ELSE IF ShipApo < FinalApo-1000 {
            HEAD(3,90,5).
        
        } ELSE {
            HEAD(3,90,0).
        }

    } ELSE IF ApoTime > 1800 AND ApoTime <= 3300 {

        IF ShipApo > FinalApo+1000 {
            HEAD(3,90,5).
        
        } ELSE IF ShipApo < FinalApo-1000 {
            HEAD(3,90,-5).
        
        } ELSE {
            HEAD(3,90,0).
        }

    } ELSE IF ApoTime > 3300 {

	    IF RefTime > ApoTime {
	    	HEAD(2,90,15).
	    	
    	} ELSE {
    		HEAD(2,90,10).
    	}
    }

    IF ShipApo >= 200000 AND ShipPeri >= 150000 {
        PRINT "Maximum apoapsis reached".
        BREAK.
    }

}.

PRINT "Staging".
STAGE.
PRINT "Payload delivered to orbit".
WAIT 1.
LOCK THROTTLE TO 0.
SAS ON.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
PRINT " ".
PRINT "Earth orbit insetion program completed.".