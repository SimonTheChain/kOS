//kOS Script: Earth Orbit Insertion
//Author: Simon Lachaîne

DECLARE PARAMETER HasSecEngines.
DECLARE PARAMETER HasSeveralUpperStages.
DECLARE PARAMETER DesiredLat.
DECLARE PARAMETER DesiredPeri.

FUNCTION HEAD {
    PARAMETER FLIGHT_MODE.
    PARAMETER LAT.
    PARAMETER LON.

    SET ShipSteer TO HEADING(LAT,LON).
    PRINT "Flight Monitor:" AT(0,29).
    
    IF FLIGHT_MODE = 1 {
        PRINT "-Changing heading according to altitude" AT(0,30).
    
    } ELSE IF FLIGHT_MODE = 2 {
        PRINT "-Changing heading according to velocity" AT(0,30).
    
    } ELSE IF FLIGHT_MODE = 3 {
        PRINT "-Changing heading according to time to apoapsis     " AT(0,30).
    }
    
    PRINT "-Pitching to "+ROUND(LON)+" degrees"+"   " AT(0,32).
    PRINT "-Apoapsis: "+ROUND(SHIP:APOAPSIS,0)+"          " AT (0,33).
    PRINT "-Periapsis: "+ROUND(SHIP:PERIAPSIS,0)+"          " AT (0,34).
}.

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
LOCK ShipSpeed TO SHIP:VELOCITY:SURFACE:MAG.
LOCK ShipAlt TO SHIP:ALTITUDE.
LOCK ApoTime TO ETA:APOAPSIS.
LOCK TransTime TO ETA:TRANSITION.
LOCK ShipVertical TO SHIP:VERTICALSPEED.
SET Pitch TO 0.
LIST ENGINES IN AllEngines.
SET MainEngines TO LIST().
SET SecEngines TO LIST().
SET Boosters TO LIST().
SET UpperEngines TO LIST().

PRINT "_PHASE 0_: Launch".
SAS OFF.
RCS ON.
LOCK THROTTLE TO 1.0.

FROM {local Countdown is 10.} UNTIL Countdown = 0 STEP {SET Countdown TO Countdown - 1.} DO {

    IF Countdown = 3 {
        PRINT "Countdown: "+Countdown+" " AT(0,1).
        PRINT "C".
        PRINT "Main engine ignition".
        STAGE.

        UNTIL STAGE:READY {
            WAIT 0.001.
        }.

        FOR e IN AllEngines {
            IF e:IGNITION {
                MainEngines:ADD(e).
            }
        }

        IF HasSecEngines = "True" {
            PRINT "Secondary engines ignition".
            STAGE.

            UNTIL STAGE:READY {
                WAIT 0.001.
            }.

            FOR e IN AllEngines {
                IF e:IGNITION {
                    IF NOT MainEngines:CONTAINS(e) {
                        SecEngines:ADD(e).
                    }
                }
            }.

            IF SecEngines:LENGTH >= 1 {
                WHEN SecEngines[0]:FLAMEOUT THEN {
                    PRINT "Discarding secondary engines".
                    STAGE.

                    UNTIL STAGE:READY {
                        WAIT 0.001.
                    }.
                }.
            }
        }

    } ELSE {
        PRINT "Countdown: "+Countdown+" " AT(0,1).
    }
    WAIT 1.
}

PRINT "Wating for maximum thrust".
FOR e IN MainEngines {
    WAIT UNTIL e:THRUST >= e:AVAILABLETHRUST.
}
IF SecEngines:LENGTH >= 1 {
    FOR e IN SecEngines {
        WAIT UNTIL e:THRUST >= e:AVAILABLETHRUST.
    }
}

STAGE.
PRINT "Lift-off".
PRINT " ".
UNTIL STAGE:READY {
	WAIT 0.001.
}.

FOR e IN AllEngines {
    IF e:IGNITION {
        IF NOT SecEngines:CONTAINS(e) AND NOT MainEngines:CONTAINS(e) {
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

PRINT "_PHASE 1_: Open-loop control".

SET ShipSteer TO HEADING(0,90).
LOCK STEERING TO ShipSteer.

UNTIL ShipAlt >= 200 {
    HEAD(1,0,90).
    WAIT 0.001.
}.

PRINT "Rolling to flight azimuth".

UNTIL ShipSpeed >= 100 {
    HEAD(2,DesiredLat,90).
    WAIT 0.001.
}.

PRINT "Initiating tilt sequence".

UNTIL ShipApo >= DesiredPeri {

    IF ShipAlt < 1000 {
        HEAD(1,DesiredLat,90).
    
    } ELSE IF ShipAlt >= 1000 AND ShipAlt < 2000 {
        HEAD(1,DesiredLat,85).
    
    } ELSE IF ShipAlt >= 2000 AND ShipAlt < 3000 {
        HEAD(1,DesiredLat,80).
    
    } ELSE IF ShipAlt >= 3000 {

        IF ShipSpeed >= 200 AND ShipSpeed < 300 {
            HEAD(2,DesiredLat,75).

        } ELSE IF ShipSpeed >= 300 AND ShipSpeed < 350 {
            HEAD(2,DesiredLat,70).

        } ELSE IF ShipSpeed >= 350 AND ShipSpeed < 450 {
            HEAD(2,DesiredLat,65).

        } ELSE IF ShipSpeed >= 450 AND ShipSpeed < 550 {
            HEAD(2,DesiredLat,60).

        } ELSE IF ShipSpeed >= 550 AND ShipSpeed < 600 {
            HEAD(2,DesiredLat,55).
        
        } ELSE IF ShipSpeed >= 600 AND ShipSpeed < 800 {
            HEAD(2,DesiredLat,50).

        } ELSE IF ShipSpeed >= 800 AND ShipSpeed < 1200 {
            HEAD(2,DesiredLat,45).

        } ELSE IF ShipSpeed >= 1200 AND ShipSpeed < 1600 {
            HEAD(2,DesiredLat,40).

        } ELSE IF ShipSpeed >= 1600 {
            HEAD(2,DesiredLat,35).
        
        } ELSE {
            HEAD(2,DesiredLat,80).
        }

    }
    WAIT 0.001.
}.

UNTIL MainEngines[0]:FLAMEOUT {

    IF ApoTime <= 60 {
        HEAD(3,DesiredLat,35).
        SET Pitch TO 35.

    } ELSE IF ApoTime > 60 AND ApoTime <= 120 {
        HEAD(3,DesiredLat,25).
        SET Pitch TO 25.

    } ELSE IF ApoTime > 120 AND ApoTime <= 180 {
        HEAD(3,DesiredLat,20).
        SET Pitch TO 20.

    } ELSE {
        HEAD(3,DesiredLat,15).
        SET Pitch TO 15.
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

LIST ENGINES IN RemainingEngines.
FOR e IN RemainingEngines {
    IF e:IGNITION {
        UpperEngines:ADD(e).
    }
}

SET BurnTime TO MANEUVER_TIME(CIRCULARIZE(ShipAlt)).
PRINT ROUND(BurnTime) + " seconds burn needed to circularize the orbit".

WHEN ShipAlt >= 140001 THEN {
    PRINT ROUND(TransTime) + " seconds before reentry".
}.

UNTIL ShipPeri >= FinalPeri {
    HEAD(3,DesiredLat,Pitch).

    // Catching exception
    IF UpperEngines[0]:FLAMEOUT {
        PRINT " ".
        PRINT "FAILED to reach desired periapsis".
        PRINT " ".
        BREAK.
    }

    SET RefTime TO ApoTime.
    WAIT 0.001.
   
    IF RefTime > ApoTime + 0.001 {
        IF Pitch <= 5 {
            SET Pitch TO Pitch + 0.01.
        }
   
    } ELSE IF RefTime < ApoTime + 0.001 {
        IF Pitch >= -5 {
            SET Pitch TO Pitch - 0.01.
        }
    }

    IF HasSeveralUpperStages = "True" {
        IF UpperEngines[0]:FLAMEOUT {
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

            RemainingEngines:CLEAR().
            UpperEngines:CLEAR().
            LIST ENGINES IN RemainingEngines.
            FOR e IN RemainingEngines {
                IF e:IGNITION {
                    UpperEngines:ADD(e).
                }
            }
        }
    }
}.

PRINT "SECO".
LOCK THROTTLE TO 0.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
RCS OFF.
SAS ON.
SET SHIP:CONTROL:NEUTRALIZE TO True.
PRINT " ".
PRINT "Earth orbit insertion program completed.".