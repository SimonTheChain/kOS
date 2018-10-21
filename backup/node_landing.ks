//kOS Script: Execute Maneuver Node
//Author: Simon Lachaîne

FUNCTION MONITOR {
	PARAMETER TRUE_BURN.
	PRINT "Node parameters:" AT (0,30).
	PRINT "-DeltaV: " + ROUND(NdDeltaV) + " m/s       " AT (0,31).
	PRINT "-Node ETA: " + ROUND(NdEta) + " seconds       " AT (0,32).
	PRINT "-Burn time: " + ROUND(BurnTime) + " seconds       " AT (0,33).
	PRINT "-Remaining burn: " + ROUND(TRUE_BURN) + " seconds       " AT (0,34).
}

FUNCTION LANDING_MONITOR {
	PRINT "Parameters:          " AT (0,30).
	PRINT "-Ship altitude: " + ROUND(ShipAlt) + " meters       " AT (0,31).
	PRINT "-Ship speed: " + ROUND(ShipSpeed) + " m/s       " AT (0,32).
	PRINT "-Terrain height: " + ROUND(MAX(0.001,((ALTITUDE-GEOPOSITION:TERRAINHEIGHT)-5)),3) + " meters       " AT (0,33).
	PRINT "                                             " AT (0,34).
}

FUNCTION LANDING_STEER {
	LANDING_MONITOR().
	LOCK STEERING TO ShipRetro.
}

FUNCTION LANDING_LOOP {
	PARAMETER SHIP_ALTITUDE.
	PARAMETER SHIP_SPEED.

	UNTIL ShipAlt <= SHIP_ALTITUDE {
		LANDING_STEER().

		IF ShipSpeed > SHIP_SPEED {
			LOCK THROTTLE TO 1.0.
			
			UNTIL ShipSpeed <= SHIP_SPEED-5 {
				LANDING_STEER().

				SET RefAlt TO ShipAlt.
				WAIT 0.001.
				
				IF RefAlt < ShipAlt  {
					BREAK.
				}
				
			}.

		} ELSE {
			LOCK THROTTLE TO 0.
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

PRINT "Ignition".
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
PRINT "Engine shutdown".
WAIT 1.

//we no longer need the maneuver node
REMOVE Nd.

UNTIL ShipAlt <= 20000 {
	LANDING_STEER().
}.

PRINT "Starting descent burn".

LANDING_LOOP(5000,200).

//UNTIL ShipAlt <= 5000 {
//	LANDING_LOOP().

//	IF ShipSpeed > 200 {
//		LOCK THROTTLE TO 1.0.
//		UNTIL ShipSpeed <= 190 {
//			LANDING_LOOP().
//			WAIT 0.001.
//		}.

//	} ELSE {
//		LOCK THROTTLE TO 0.
//	}

//	WAIT 0.001.
//}.

PRINT "Deploying gear".
GEAR ON.

LANDING_LOOP(1000,100).

//UNTIL ShipAlt <= 1000 {
//	LANDING_LOOP().

//	IF ShipSpeed > 50 {
//		LOCK THROTTLE TO 1.0.
//		UNTIL ShipSpeed <= 40 {
//			LANDING_LOOP().

//			SET RefAlt TO ShipAlt.
//			WAIT 0.001.
			
//			IF RefAlt < ShipAlt  {
//				BREAK.
//			}
			
//		}.

//	} ELSE {
//		LOCK THROTTLE TO 0.
//	}
//	WAIT 0.001.
//}.

UNTIL ShipAlt <= 500 {
	LOCK STEERING TO HEADING(0,90).
	LANDING_MONITOR().

	IF ShipSpeed > 50 {
		LOCK THROTTLE TO 1.0.

		WHEN ShipSpeed <= 45 THEN {
			LOCK THROTTLE TO 0.
		}

	} ELSE {
		LOCK THROTTLE TO 0.
	}

	SET RefAlt TO ShipAlt.
	WAIT 0.001.

	WHEN RefAlt < ShipAlt THEN  {
		LOCK THROTTLE TO 0.
	}
}.

UNTIL ShipAlt <= 25 {
	LOCK STEERING TO HEADING(0,90).
	LANDING_MONITOR().

	IF SHIP:STATUS = "LANDED" {
		LOCK THROTTLE TO 0.
		BREAK.
	}

	IF ShipSpeed > 6 {
		LOCK THROTTLE TO 1.0.

		WHEN ShipSpeed <= 4 THEN {
			LOCK THROTTLE TO 0.
		}

	} ELSE {
		LOCK THROTTLE TO 0.
	}

	SET RefAlt TO ShipAlt.
	WAIT 0.001.

	WHEN RefAlt < ShipAlt THEN  {
		LOCK THROTTLE TO 0.
	}
}.

LOCK THROTTLE TO 0.
SAS ON.
RCS OFF.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
PRINT "Landing program completed.".