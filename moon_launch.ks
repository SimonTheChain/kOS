//kOS Script: Moon Orbit Insertion
//Author: Simon Lachaîne

DECLARE PARAMETER NeedStaging.
DECLARE PARAMETER Offset.

FUNCTION MONITOR {
    PARAMETER LAT.
    PARAMETER LON.

    SET ShipSteer TO HEADING(LAT,LON).
    PRINT "Flight Monitor:" AT(0,30).
    PRINT "-Pitching to "+LON+" degrees"+"   " AT(0,31).
    PRINT "-Apoapsis: "+ROUND(ShipApo,0)+"          " AT (0,32).
    PRINT "-Periapsis: "+ROUND(ShipPeri,0)+"          " AT (0,33).
}

CLEARSCREEN.
LOCK ShipApo TO SHIP:APOAPSIS.
LOCK ShipPeri TO SHIP:PERIAPSIS.
LOCK ShipAlt TO ALT:RADAR-Offset.
LOCK ApoTime TO ETA:APOAPSIS.
SET ShipSteer TO "kill".
LOCK STEERING TO ShipSteer.

PRINT "_PHASE 0_: Launch".
SAS OFF.
RCS ON.

FROM {local Countdown is 10.} UNTIL Countdown = 0 STEP {SET Countdown TO Countdown - 1.} DO {

    IF Countdown = 1 {
        PRINT "Countdown: "+Countdown+" " AT(0,1).
        PRINT "C".
        PRINT "Ignition".
        
        IF NeedStaging = True {
        	STAGE.

        	UNTIL STAGE:READY {
				WAIT 0.001.
			}.
        }
        LOCK THROTTLE TO 1.0.
        

    } ELSE {
        PRINT "Countdown: "+Countdown+" " AT(0,1).
    }
    WAIT 1.
}

UNTIL SHIP:STATUS <> "LANDED" {
	WAIT 0.001.
}

PRINT "Lift-off".
PRINT " ".
PRINT "_PHASE 1_: Reaching apoapsis".

UNTIL ShipAlt >= 20 {
	WAIT 0.001.
}

PRINT "Rolling to flight azimuth".
UNTIL ShipAlt >= 100 {
	MONITOR(90,90).
	WAIT 0.001.
}

IF GEAR = True {
	PRINT "Retracting gear".
	GEAR OFF.
}

PRINT "Initiating tilt sequence".
UNTIL ShipAlt >= 250 {
	MONITOR(90,65).
	WAIT 0.001.
}

UNTIL ShipAlt >= 500 {
	MONITOR(90,25).
	WAIT 0.001.
}

UNTIL ShipApo >= 20000 {
	MONITOR(90,5).
	WAIT 0.001.
}
LOCK THROTTLE TO 0.

PRINT "Waiting for apoapsis".
UNTIL ApoTime <= 15 {
	MONITOR(90,0).
	WAIT 0.001.
}

PRINT " ".
PRINT "_PHASE 2_: Raising the periapsis".
PRINT "Ignition".
LOCK THROTTLE TO 1.0.

UNTIL ShipPeri >= 12000 {
	MONITOR(90,0).
	WAIT 0.001.
}

LOCK THROTTLE TO 0.
RCS OFF.
SAS ON.
SET SHIP:CONTROL:NEUTRALIZE TO True.
PRINT " ".
PRINT "Moon orbit insertion program completed.".