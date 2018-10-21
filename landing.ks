//kOS Script: Execute Maneuver Node
//Author: Simon Lachaîne

FUNCTION MONITOR {
	PARAMETER True_BURN.
	PRINT "Node parameters:" AT (0,30).
	PRINT "-DeltaV: " + ROUND(NdDeltaV) + " m/s       " AT (0,31).
	PRINT "-Node ETA: " + ROUND(NdEta) + " seconds       " AT (0,32).
	PRINT "-Burn time: " + ROUND(BurnTime) + " seconds       " AT (0,33).
	PRINT "-Remaining burn: " + ROUND(True_BURN) + " seconds       " AT (0,34).
}

FUNCTION LANDING_MONITOR {
	PARAMETER THRESHOLD_ALT.
	PARAMETER TARGET_SPEED.
	PRINT "Parameters:          " AT (0,30).
	PRINT "-Ship altitude: " + ROUND(ShipAlt) + " meters       " AT (0,31).
	PRINT "-Threshold altitude: " + THRESHOLD_ALT + " meters       " AT (0,32).
	PRINT "-Ship speed: " + ROUND(ShipSpeed) + " m/s       " AT (0,33).
	PRINT "-Reducing speed to: " + TARGET_SPEED + " m/s       " AT (0,34).
}

FUNCTION LANDING_STEER {
	PARAMETER THRESHOLD_ALT.
	PARAMETER TARGET_SPEED.
	LANDING_MONITOR(THRESHOLD_ALT,TARGET_SPEED).
	LOCK STEERING TO ShipRetro.
}

FUNCTION LANDING_LOOP {
	PARAMETER UNTIL_ALT.
	PARAMETER THROTTLE_START.
	PARAMETER THROTTLE_STOP.
	PARAMETER RCS_START.
	PARAMETER RCS_STOP.

	UNTIL ShipAlt <= UNTIL_ALT {
		LANDING_STEER(UNTIL_ALT,RCS_START).

		WHEN ShipSpeed > THROTTLE_START THEN {
			SET THROTTLE TO 1.0.
			
			IF ShipAlt >= UNTIL_ALT {
				RETURN True.
			}
		}

		WHEN ShipSpeed <= THROTTLE_STOP THEN {
			SET THROTTLE TO 0.
			
			IF ShipAlt >= UNTIL_ALT {
				RETURN True.
			}
		}

		WHEN ShipSpeed > RCS_START THEN {
			SET SHIP:CONTROL:FORE TO 1.
			
			IF ShipAlt >= UNTIL_ALT {
				RETURN True.
			}
		}

		WHEN ShipSpeed <= RCS_STOP THEN {
			SET SHIP:CONTROL:FORE TO 0.
			
			IF ShipAlt >= UNTIL_ALT {
				RETURN True.
			}
		}

		WAIT 0.001.
	}.
}

SAS ON.
RCS OFF.
SET Nd to NEXTNODE.
LOCK NdDeltaV TO Nd:DELTAV:MAG.
LOCK NdEta to Nd:ETA.
LOCK MaxAcc to SHIP:MAXTHRUST/SHIP:MASS.
SET BurnTime TO NdDeltaV/MaxAcc.
SET TrueBurn TO BurnTime.
LOCK ShipAlt TO ALT:RADAR.
LOCK ShipSpeed TO SHIP:VELOCITY:SURFACE:MAG.
LOCK ShipRetro TO SHIP:RETROGRADE.
CLEARSCREEN.

PRINT "Landing program started.".

UNTIL NdEta <= (BurnTime/2 + 100) {
	MONITOR(TrueBurn).
	WAIT 0.001.
}.

SAS OFF.
RCS ON.
SET Np to Nd:DELTAV.
LOCK STEERING TO Np.

//now we need to wait until the burn vector and ship's facing are aligned
UNTIL VANG(Np, SHIP:FACING:VECTOR) < 0.25 {
	MONITOR(TrueBurn).
	WAIT 0.001.
}.

//the ship is facing the right direction, let's wait for our burn time
UNTIL NdEta <= (BurnTime/2){
	MONITOR(TrueBurn).
	WAIT 0.001.
}.

PRINT "Deorbit burn".
SET Time0 TO TIME.
LOCK THROTTLE TO 1.0.
LIST ENGINES IN AllEngines.

FOR e IN AllEngines {
    IF e:IGNITION {
        GLOBAL StageEngine IS e.
    }
}

WAIT UNTIL StageEngine:THRUST >= StageEngine:AVAILABLETHRUST.
SET TimeSecs TO TIME-Time0.
SET TrueBurn TO BurnTime-TimeSecs.

UNTIL TrueBurn:SECONDS <= 0 {
	SET RefTime TO TIME.
	SET RefDv TO NdDeltaV.
	MONITOR(TrueBurn:SECONDS).
	WAIT 0.001.
	SET TimeDiff TO TIME-RefTime.
	SET TrueBurn TO TrueBurn-TimeDiff.

	IF NdDeltaV >= RefDv {
		BREAK.
	}
}.

LOCK THROTTLE TO 0.
WAIT 1.

//we no longer need the maneuver node
REMOVE Nd.

UNTIL ShipAlt <= 20000 {
	LANDING_STEER(20000,"n/a").
}.

PRINT "Descent burn".
LANDING_LOOP(5000,200,195,200,195).
LANDING_LOOP(1000,100,95,100,95).
LANDING_LOOP(500,55,46,45,44).
LANDING_LOOP(200,35,26,25,24).
PRINT "Deploying gear".
GEAR ON.
LANDING_LOOP(50,20,16,15,14).

UNTIL ShipAlt <= 10 {
	LOCK STEERING TO SHIP:UP.
	LANDING_MONITOR(10,6).

	WHEN ShipSpeed > 8 THEN {
		LOCK THROTTLE TO 1.0.
		
		IF ShipAlt >= 10 {
			RETURN True.
		}
	}

	WHEN ShipSpeed <= 7 THEN {
		LOCK THROTTLE TO 0.
		
		IF ShipAlt >= 10 {
			RETURN True.
		}
	}

	WHEN ShipSpeed > 6 THEN {
		SET SHIP:CONTROL:FORE TO 1.
		
		IF ShipAlt >= 10 {
			RETURN True.
		}
	}

	WHEN ShipSpeed <= 5 THEN {
		SET SHIP:CONTROL:FORE TO 0.
		
		IF ShipAlt >= 10 {
			RETURN True.
		}
	}

	SET RefAlt TO ShipAlt.
	WAIT 0.001.

	IF RefAlt <= ShipAlt {
		LOCK THROTTLE TO 0.
		SET SHIP:CONTROL:FORE TO 0.
	}
}.

LOCK THROTTLE TO 0.
SET SHIP:CONTROL:FORE TO 0.

UNTIL SHIP:STATUS = "LANDED" {
	LOCK STEERING TO SHIP:UP.
	LANDING_MONITOR("Landed",6).

	WHEN ShipSpeed > 6 THEN {
		SET SHIP:CONTROL:FORE TO 1.
		
		IF SHIP:STATUS = "LANDED" {
			RETURN False.
		
		} ELSE IF ShipAlt >= 5 {
			RETURN True.
		}
	}

	WHEN ShipSpeed <= 5 THEN {
		SET SHIP:CONTROL:FORE TO 0.
		
		IF SHIP:STATUS = "LANDED" {
			RETURN False.
		
		} ELSE IF ShipAlt >= 5 {
			RETURN True.
		}
	}

	WAIT 0.001.
}.

SET SHIP:CONTROL:FORE TO 0.
PRINT "Touchdown".

FROM {local Countdown is 10.} UNTIL Countdown = 0 STEP {SET Countdown TO Countdown - 1.} DO {

    LOCK STEERING TO SHIP:UP.
    WAIT 1.
}

SAS ON.
RCS OFF.
SET SHIP:CONTROL:NEUTRALIZE to True.
PRINT "Landing program completed.".