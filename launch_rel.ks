// kOS Script: Earth Orbit Insertion Relative to a Target
// Author: Simon Lachaîne

// This script is meant to be used with RSS and RO.
// The following rocket parameters are recommended:
// 1st stage: TWR 1.5, 3 minutes burn
// Upper stage(s): TWR 0.6, 6 minutes burn
// The target must be selected before starting the script.

// Set to True if using liquid-fuel boosters;
// They must be set on their own stage after the main engine(s)
DECLARE PARAMETER HasSecEngines.
// Set to True if using several upper stages
DECLARE PARAMETER HasSeveralUpperStages.
// Set to the desired periapsis
DECLARE PARAMETER DesiredPeri.

// https://www.reddit.com/r/Kos/comments/4nxkfh/mechjebs_relative_inclination_in_kos/
FUNCTION ORBIT_NORMAL {
    PARAMETER OrbitIn.
    
    RETURN VCRS(OrbitIn:body:position - OrbitIn:position,
                OrbitIn:velocity:orbit):normalized.
}

FUNCTION SWAPYZ {
    PARAMETER VecIn.

    RETURN V(VecIn:X, VecIn:Z, VecIn:Y).
}

FUNCTION SWAPPED_ORBIT_NORMAL {
    PARAMETER OrbitIn.

    RETURN -SWAPYZ(ORBIT_NORMAL(OrbitIn)).
}

FUNCTION RELATIVEINC {
    PARAMETER OrbiterA, OrbiterB.

    RETURN VANG(SWAPPED_ORBIT_NORMAL(OrbiterA), SWAPPED_ORBIT_NORMAL(OrbiterB)).
}

// Returns the Delta-V required to circularize the orbit
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

// Returns the time needed to execute a burn of given Delta-V
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

// Adjusts the timewarp according to the relative inclination
FUNCTION ADJUST_WARP {
    IF RelInclRef >= 20 {
        SET KUNIVERSE:TIMEWARP:RATE to 10000.
    
    } ELSE IF RelInclRef >= 10 AND RelInclRef < 20 {
        SET KUNIVERSE:TIMEWARP:RATE to 1000.
    
    } ELSE IF RelInclRef >= 5 AND RelInclRef < 10 {
        SET KUNIVERSE:TIMEWARP:RATE to 100.

    } ELSE {
        SET KUNIVERSE:TIMEWARP:RATE to 10.
    }
}

// Adjusts the heading according to the relative inclination
FUNCTION ADJUST_HEADING {
    IF RelInclRef < RelIncl {

        IF RelIncl >= 0 {
            SET TrueHeading TO TrueHeading - 0.1.

        } ELSE {
            SET TrueHeading TO TrueHeading + 0.1.
        }
    
    } ELSE {

        IF RelIncl >= 0 {
            SET TrueHeading TO TrueHeading + 0.1.

        } ELSE {
            SET TrueHeading TO TrueHeading - 0.1.
        }
    }

    SET RelInclRef TO RelIncl.
}

// https://github.com/space-is-hard/kOS-Utils/blob/master/boot_kos_utils.ks
FUNCTION DEPLOY_FAIRING {
    SET ModuleFairing TO SHIP:MODULESNAMED("ModuleProceduralFairing").
    SET ProceduralFairing TO SHIP:MODULESNAMED("ProceduralFairingDecoupler").

    IF ModuleFairing:LENGTH > 0 {
        // Iterates over a list of all parts with the stock fairings module
        FOR module IN ModuleFairing { // Stock and KW Fairings

            // and deploys them
            module:DOEVENT("deploy").
            PRINT "Deploying fairing".

        }.
    }

    IF ProceduralFairing:LENGTH > 0 {
        // Iterates over a list of all parts using the fairing module from the Procedural Fairings Mod
        FOR module IN ProceduralFairing { // Procedural Fairings
        
            // and jettisons them (PF uses the word jettison in the right click menu instead of deploy)
            module:DOEVENT("jettison").
            PRINT "Deploying fairing".
            
        }.
    }
}

// Controls the heading and pitch and displays information
FUNCTION HEAD {
    PARAMETER FLIGHT_MODE.
    PARAMETER LAT.
    PARAMETER LON.

    SET ShipSteer TO HEADING(LAT,LON).
    PRINT "Flight Monitor:" AT(0,28).
    
    IF FLIGHT_MODE = 0 {
        PRINT "-Waiting for lift-off" AT(0,29).

    } ELSE IF FLIGHT_MODE = 1 {
        PRINT "-Changing heading according to altitude" AT(0,29).
    
    } ELSE IF FLIGHT_MODE = 2 {
        PRINT "-Changing heading according to velocity" AT(0,29).
    
    } ELSE IF FLIGHT_MODE = 3 {
        PRINT "-Changing heading according to time to apoapsis" AT(0,29).
    }
    
    PRINT "-Relative inclination: " + ROUND(RelIncl,6) + " degrees   " AT(0,30).
    PRINT "-Heading to "+ROUND(LAT,2) + " degrees   " AT(0,31).
    PRINT "-Pitching to "+ROUND(LON,2) + " degrees   " AT(0,32).
    PRINT "-Apoapsis: "+ROUND(SHIP:APOAPSIS,0)+"          " AT (0,33).
    PRINT "-Periapsis: "+ROUND(SHIP:PERIAPSIS,0)+"          " AT (0,34).
}.

// Program start
CLEARSCREEN.
PRINT "Earth Orbit Insertion program started".
LOCK ShipApo TO SHIP:APOAPSIS.
LOCK ShipPeri TO SHIP:PERIAPSIS.
LOCK ShipSpeed TO SHIP:VELOCITY:SURFACE:MAG.
LOCK ShipAlt TO SHIP:ALTITUDE.
LOCK ApoTime TO ETA:APOAPSIS.
LOCK TransTime TO ETA:TRANSITION.
LOCK ShipVertical TO SHIP:VERTICALSPEED.
SET ShipSteer TO HEADING(0,90).
LOCK STEERING TO ShipSteer.
SET TrueHeading TO 0.
LOCK RelIncl TO RELATIVEINC(SHIP,TARGET).
SET RelInclRef TO RelIncl.
SET Pitch TO 0.
LIST ENGINES IN AllEngines.
SET MainEngines TO LIST().
SET SecEngines TO LIST().
SET Boosters TO LIST().
SET UpperEngines TO LIST().
WAIT 1.

PRINT "_PHASE -1_: Waiting for launch window".

// If the relative inclination is decreasing
IF RelInclRef > RelIncl {

    UNTIL RelInclRef < RelIncl {
        HEAD(0,TrueHeading,90).
        SET RelInclRef TO RelIncl.
        WAIT 0.001.
    }.

// If the relative inclination is increasing
} ELSE IF RelInclRef < RelIncl {

    UNTIL RelInclRef > RelIncl {
        HEAD(0,TrueHeading,90).
        SET RelInclRef TO RelIncl.
        WAIT 0.001.
    }.

    UNTIL RelInclRef < RelIncl {
        HEAD(0,TrueHeading,90).
        SET RelInclRef TO RelIncl.
        WAIT 0.001.
    }.
}

//// If the relative inclination is decreasing
//IF RelInclRef > RelIncl {

//    UNTIL RelInclRef < RelIncl {
//        HEAD(0,0,90).
//        ADJUST_WARP().
//        SET RelInclRef TO RelIncl.
//        WAIT 0.001.
//    }.

//// If the relative inclination is increasing
//} ELSE IF RelInclRef < RelIncl {

//    UNTIL RelInclRef > RelIncl {
//        HEAD(0,0,90).
//        ADJUST_WARP().
//        SET RelInclRef TO RelIncl.
//        WAIT 0.001.
//    }.

//    UNTIL RelInclRef < RelIncl {
//        HEAD(0,0,90).
//        ADJUST_WARP().
//        SET RelInclRef TO RelIncl.
//        WAIT 0.001.
//    }.
//}

SET KUNIVERSE:TIMEWARP:RATE to 1.
KUNIVERSE:TIMEWARP:CANCELWARP().

PRINT "_PHASE 0_: Launch".

UNTIL KUNIVERSE:TIMEWARP:ISSETTLED {
    HEAD(0,TrueHeading,90).
    WAIT 0.001.
}

SAS OFF.
RCS ON.
LOCK THROTTLE TO 1.0.

// Countdown sequence
FROM {local Countdown is 10.} UNTIL Countdown = 0 STEP {SET Countdown TO Countdown - 1.} DO {

    IF Countdown = 3 {
        PRINT "Countdown: " + Countdown + " " AT(0,3).
        PRINT "C".
        PRINT " ".
        PRINT "Main engine(s) ignition".
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
        PRINT "Countdown: "+Countdown+" " AT(0,3).
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

WHEN ShipAlt >= 141000 THEN {
    DEPLOY_FAIRING().
}

PRINT "_PHASE 1_: Open-loop control".

UNTIL ShipAlt >= 200 {
    HEAD(1,TrueHeading,90).
    WAIT 0.001.
}.

PRINT "Rolling to flight azimuth".
SET TrueHeading TO 90.

UNTIL ShipSpeed >= 100 {
    HEAD(2,TrueHeading,90).
    WAIT 0.001.
}.

PRINT "Initiating tilt sequence".

UNTIL ShipApo >= DesiredPeri {

    IF ShipAlt < 1000 {
        HEAD(1,TrueHeading,90).
    
    } ELSE IF ShipAlt >= 1000 AND ShipAlt < 2000 {
        HEAD(1,TrueHeading,85).
    
    } ELSE IF ShipAlt >= 2000 AND ShipAlt < 3000 {
        HEAD(1,TrueHeading,80).
    
    } ELSE IF ShipAlt >= 3000 {

        IF ShipSpeed >= 200 AND ShipSpeed < 300 {
            HEAD(2,TrueHeading,75).

        } ELSE IF ShipSpeed >= 300 AND ShipSpeed < 350 {
            HEAD(2,TrueHeading,70).

        } ELSE IF ShipSpeed >= 350 AND ShipSpeed < 450 {
            HEAD(2,TrueHeading,65).

        } ELSE IF ShipSpeed >= 450 AND ShipSpeed < 550 {
            HEAD(2,TrueHeading,60).

        } ELSE IF ShipSpeed >= 550 AND ShipSpeed < 600 {
            HEAD(2,TrueHeading,55).
        
        } ELSE IF ShipSpeed >= 600 AND ShipSpeed < 800 {
            HEAD(2,TrueHeading,50).

        } ELSE IF ShipSpeed >= 800 AND ShipSpeed < 1200 {
            HEAD(2,TrueHeading,45).

        } ELSE IF ShipSpeed >= 1200 AND ShipSpeed < 1600 {
            HEAD(2,TrueHeading,40).

        } ELSE IF ShipSpeed >= 1600 {
            HEAD(2,TrueHeading,35).
        
        } ELSE {
            HEAD(2,TrueHeading,80).
        }
    }

    WAIT 0.001.
}.

UNTIL MainEngines[0]:FLAMEOUT {

    IF ApoTime <= 60 {
        HEAD(3,TrueHeading,35).
        SET Pitch TO 35.

    } ELSE IF ApoTime > 60 AND ApoTime <= 120 {
        HEAD(3,TrueHeading,25).
        SET Pitch TO 25.

    } ELSE IF ApoTime > 120 AND ApoTime <= 180 {
        HEAD(3,TrueHeading,20).
        SET Pitch TO 20.

    } ELSE {
        
        IF ShipApo > DesiredPeri + 50000 {
            HEAD(3,TrueHeading,0).
            SET Pitch TO 0.
        
        } ELSE {
            HEAD(3,TrueHeading,15).
            SET Pitch TO 15.
        }
        
    }

    //ADJUST_HEADING().
    WAIT 0.001.
}

PRINT "Staging".
STAGE.

UNTIL STAGE:READY {
	WAIT 0.001.
}.

PRINT " ".
PRINT "_PHASE 2_: Closed-loop control".
PRINT "Desired periapsis set to "+ROUND(DesiredPeri)+" meters".
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

UNTIL ShipPeri >= DesiredPeri {
    //ADJUST_HEADING().
    HEAD(3,TrueHeading,Pitch).
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
    
    } ELSE {
        // Catching exception
        IF UpperEngines[0]:FLAMEOUT {
            PRINT " ".
            PRINT "FAILED to reach desired periapsis".
            PRINT " ".
            BREAK.
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
PRINT "Earth Orbit Insertion program completed.".