//kOS Script: Execute Maneuver Node
//Author: Simon Lachaîne

FUNCTION MONITOR {
	PRINT "Node parameters:" AT (0,30).
	PRINT "-DeltaV: " + ROUND(NdDeltaV) + " m/s       " AT (0,31).
	PRINT "-Node ETA: " + ROUND(NdEta) + " seconds       " AT (0,32).
	PRINT "-Burn time: " + ROUND(BurnTime) + " seconds       " AT (0,33).
	PRINT "-Ignition: " + ROUND(BurnTime/2) + " seconds       " AT (0,34).
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

FUNCTION BURN_WAIT {
	PARAMETER USE_RCS.

	IF USE_RCS = False {
		SET BurnTime TO BurnTime + 3.
	}

	UNTIL NdEta <= (BurnTime/2){
		MONITOR().
		WAIT 0.001.
	}.

	IF USE_RCS = False {
		PRINT "Stabilizing fuel".
		SET SHIP:CONTROL:FORE TO 1.
		SET Time1 to TIME.
		SET Time2 to TIME.

		UNTIL Time2:SECONDS - Time1:SECONDS >= 3 {
			MONITOR().
			WAIT 0.001.
			SET Time2 to TIME.
		}.

		SET SHIP:CONTROL:FORE TO 0.
	}
}

FUNCTION BURN {
	PARAMETER USE_RCS.

	IF USE_RCS = False {
		PRINT "Engine ignition".
		LOCK THROTTLE TO 1.0.

		UNTIL NdDeltaV <= 3 {
			MONITOR().
			WAIT 0.001.

			IF StageEngine:FLAMEOUT {
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
			}
		}.

		LOCK THROTTLE TO 0.
		PRINT "Engine shutdown".
	}

	PRINT "Thrusters ignition".
	SET RefDv TO NdDeltaV.
	SET TotalDv TO RefDv.
	SET SHIP:CONTROL:FORE TO 1.
	WAIT 0.1.
	
	UNTIL RefDv < NdDeltaV OR TotalDv <= 0 OR NdDeltaV <= 0.1 {
		MONITOR().
		SET RefDv TO NdDeltaV.
		SET TotalDv TO TotalDv - (TotalDv - RefDv).
		WAIT 0.001.
	}

	SET SHIP:CONTROL:FORE TO 0.
	PRINT "Thrusters shutdown".

}

CLEARSCREEN.
SAS ON.
RCS OFF.
SET Nd to NEXTNODE.
LOCK NdDeltaV TO Nd:DELTAV:MAG.
LOCK NdEta to Nd:ETA.
SET MaxAcc to SHIP:MAXTHRUST/SHIP:MASS.
SET BurnTime TO MANEUVER_TIME(NdDeltaV).
LIST ENGINES IN AllEngines.


PRINT "Node execution program started".

// UNTIL NdEta <= (BurnTime/2 + 200) {
// 	MONITOR().
// 	WAIT 0.001.
// }.

PRINT "Aligning vessel to maneuver".
SAS OFF.

IF NdDeltaV >= 25 {
	RCS ON.
}

SET Np to Nd:DELTAV.
LOCK STEERING TO Np.

//now we need to wait until the burn vector and ship's facing are aligned
UNTIL VANG(Np, SHIP:FACING:VECTOR) < 0.25 {
	MONITOR().
	WAIT 0.001.
}.

SET Time1 to TIME.
SET Time2 to TIME.
UNTIL Time2:SECONDS - Time1:SECONDS >= 10 {
	MONITOR().
	WAIT 0.001.
	SET Time2 to TIME.
}.

IF RCS = False {
	RCS ON.
}

IF NdDeltaV <= 25 AND NdDeltaV > 1 {
	PRINT "Testing RCS thrusters power".
	SET DvStart TO NdDeltaV.
	SET TimeStart TO TIME.
	SET SHIP:CONTROL:FORE TO 1.
	WAIT 0.5.
	SET SHIP:CONTROL:FORE TO 0.
	SET DvEnd TO NdDeltaV.
	SET TimeEnd TO TIME.
	SET DvDiff TO DvStart - DvEnd.
	SET TimeDiff TO TimeEnd - TimeStart.
	GLOBAL BurnTime IS DvEnd * TimeDiff:SECONDS / DvDiff.
	PRINT "Burn time set to " + ROUND(BurnTime) + " seconds".
	SET SHIP:CONTROL:FORE TO -1.
	WAIT 0.5.
	SET SHIP:CONTROL:FORE TO 0.
	SET UseRcs TO True.
	BURN_WAIT(UseRcs).
	BURN(UseRcs).

} ELSE IF NdDeltaV <= 1 {
	GLOBAL BurnTime IS 1.
	SET UseRcs TO True.
	BURN_WAIT(UseRcs).
	BURN(UseRcs).

} ELSE {
	SET UseRcs TO False.
	BURN_WAIT(UseRcs).
	BURN(UseRcs).

}

UNLOCK STEERING.
UNLOCK THROTTLE.
WAIT 1.

REMOVE Nd.
SAS ON.
RCS OFF.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
PRINT "Node execution program completed.".