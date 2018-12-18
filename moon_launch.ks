//kOS Script: Moon Orbit Insertion
//Author: Simon Lachaîne

DECLARE PARAMETER HeadingDirection.
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

FUNCTION CIRCULARIZE {
    PARAMETER ALT.

    LOCAL mu IS BODY:MU.
    LOCAL br IS BODY:RADIUS.

    // present orbit properties
    LOCAL vom IS VELOCITY:ORBIT:MAG.               // actual velocity
    LOCAL r IS br + altitude.                      // actual distance to body
    LOCAL ra IS br + apoapsis.                     // radius at burn apsis
    LOCAL v1 IS sqrt( vom^2 + 2*mu*(1/ra - 1/r) ). // velocity at burn apsis

    LOCAL sma1 IS (periapsis + 2*br + apoapsis)/2. // semi major axis present orbit

    // future orbit properties
    LOCAL r2 IS br + apoapsis.               // distance after burn at apoapsis
    LOCAL sma2 IS ((alt * 1000) + 2*br + apoapsis)/2. // semi major axis target orbit
    LOCAL v2 IS sqrt( vom^2 + (mu * (2/r2 - 2/r + 1/sma1 - 1/sma2 ) ) ).

    RETURN v2 - v1.
}

FUNCTION MANEUVER_TIME {
    PARAMETER dV.

    LIST ENGINES IN AllEngines.
    SET StageRef TO 0.

    FOR e IN AllEngines {
        IF e:STAGE > StageRef {
            SET StageRef TO e:STAGE.
        }
    }.

    SET StageEngines to LIST().

    FOR e IN AllEngines {
        IF e:STAGE = StageRef {
            StageEngines:ADD(e).
        }
    }.

    GLOBAL StageEngine IS StageEngines[0].
    SET EnginesThrust TO 0.

    FOR e IN StageEngines {
        SET EnginesThrust TO EnginesThrust + e:MAXTHRUST.
    }.

    LOCAL f IS EnginesThrust * 1000.  // Engine Thrust (kg * m/s²)
    LOCAL m IS SHIP:MASS * 1000.        // Starting mass (kg)
    LOCAL e IS CONSTANT():E.            // Base of natural log
    LOCAL p IS StageEngine:VISP.               // Engine ISP (s)
    LOCAL g IS 9.80665.                 // Gravitational acceleration constant (m/s²)

    RETURN g * m * p * (1 - e^(-dV/(g*p))) / f.
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
        
        IF NeedStaging = "True" {
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

UNTIL ShipAlt >= 25 {
	WAIT 0.001.
}

PRINT "Rolling to flight azimuth".
UNTIL ShipAlt >= 100 {
	MONITOR(HeadingDirection,90).
	WAIT 0.001.
}

IF GEAR = True {
	PRINT "Retracting gear".
	GEAR OFF.
}

PRINT "Initiating tilt sequence".
UNTIL ShipAlt >= 250 {
	MONITOR(HeadingDirection,75).
	WAIT 0.001.
}

UNTIL ShipAlt >= 500 {
	MONITOR(HeadingDirection,50).
	WAIT 0.001.
}

UNTIL ShipAlt >= 750 {
	MONITOR(HeadingDirection,25).
	WAIT 0.001.
}

UNTIL ShipAlt >= 1000 {
	MONITOR(HeadingDirection,15).
	WAIT 0.001.
}

UNTIL ShipApo >= 30000 {
	MONITOR(HeadingDirection,5).
	WAIT 0.001.
}
LOCK THROTTLE TO 0.

SET BurnTime TO MANEUVER_TIME(CIRCULARIZE(ShipAlt)).
PRINT ROUND(BurnTime) + " seconds burn needed to circularize the orbit".

UNTIL ApoTime <= BurnTime / 2 {
	MONITOR(HeadingDirection,0).
	WAIT 0.001.
}

PRINT " ".
PRINT "_PHASE 2_: Raising the periapsis".
PRINT "Ignition".
LOCK THROTTLE TO 1.0.

UNTIL ShipPeri >= 20000 {
	MONITOR(HeadingDirection,0).
	WAIT 0.001.
}

LOCK THROTTLE TO 0.
RCS OFF.
SAS ON.
SET SHIP:CONTROL:NEUTRALIZE TO True.
PRINT " ".
PRINT "Moon orbit insertion program completed.".