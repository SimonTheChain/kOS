//kOS Script: Execute Maneuver Node
//Author: Simon Lachaîne

FUNCTION MONITOR {
	PRINT "Node parameters:" AT (0,30).
	PRINT "-DeltaV: " + ROUND(NdDeltaV) + " m/s       " AT (0,31).
	PRINT "-Node ETA: " + ROUND(NdEta) + " seconds       " AT (0,32).
	PRINT "-Burn time: " + ROUND(BurnTime) + " seconds       " AT (0,33).
	PRINT "-Ignition: " + ROUND(BurnTime/2) + " seconds       " AT (0,34).
}

FUNCTION BURN_WAIT {
	//the ship is facing the right direction, let's wait for our burn time
	UNTIL NdEta <= (BurnTime/2){
		MONITOR().
		WAIT 0.001.
	}.
}

FUNCTION BURN {
	PARAMETER USE_RCS.
	
	PRINT "Using RCS: " + USE_RCS.
	PRINT "Ignition".
	SET RefDv TO NdDeltaV.
	
	IF USE_RCS = True {
		SET SHIP:CONTROL:FORE TO 1.

	} ELSE {
		LOCK THROTTLE TO 1.0.
		LIST ENGINES IN AllEngines.

		FOR e IN AllEngines {
		    IF e:IGNITION {
		        GLOBAL StageEngine IS e.
		    }
		}
	}

	SET LoopCount TO 0.
	SET LoopBreak TO False.
	SET TimeRef TO 0.

	UNTIL LoopBreak = True {
		MONITOR().
		SET RefDv TO NdDeltaV.
		SET BurnStart TO TIME.
		WAIT 0.001.	

		SET LoopCount TO LoopCount+1.
		SET BurnEnd TO TIME.
		SET TimeRef TO TimeRef + (BurnEnd:SECONDS - BurnStart:SECONDS).
		PRINT "LoopCount: " + LoopCount AT(0,20).
		PRINT "RefDv: " + RefDv AT(0,21).
		PRINT "NdDeltaV: " + NdDeltaV AT(0,22).
		PRINT "RefDv < NdDeltaV: " + (RefDv < NdDeltaV) AT(0,23).
		PRINT "TimeRef: " + TimeRef AT(0,24).
		
		IF LoopCount >= 10 AND (RefDv < NdDeltaV OR TimeRef >= BurnTime) {
			SET LoopBreak TO True.
		}

		IF USE_RCS = False {
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
		}
	}.

	IF USE_RCS = True {
		SET SHIP:CONTROL:FORE TO 0.
		PRINT "Thruster shutdown".
	
	} ELSE {
		LOCK THROTTLE TO 0.
		PRINT "Engine shutdown".

	}
}

CLEARSCREEN.
SAS ON.
RCS OFF.
SET Nd to NEXTNODE.
LOCK NdDeltaV TO Nd:DELTAV:MAG.
LOCK NdEta to Nd:ETA.
SET MaxAcc to SHIP:MAXTHRUST/SHIP:MASS.
SET BurnTime TO NdDeltaV/MaxAcc.
LIST ENGINES IN AllEngines.


PRINT "Node execution program started (201810161044).".

UNTIL NdEta <= (BurnTime/2 + 200) {
	MONITOR().
	WAIT 0.001.
}.

PRINT "Aligning vessel to maneuver".
SAS OFF.
RCS ON.
SET Np to Nd:DELTAV.
LOCK STEERING TO Np.

//now we need to wait until the burn vector and ship's facing are aligned
UNTIL VANG(Np, SHIP:FACING:VECTOR) < 0.25 {
	MONITOR().
	WAIT 0.001.
}.
WAIT 10.

IF BurnTime <= 2 {
	FOR e IN AllEngines {
	    e:SHUTDOWN.
	}
	PRINT "Testing RCS thrusters power".
	SET DvStart TO NdDeltaV.
	SET TimeStart TO TIME.
	// SET SHIP:CONTROL:FORE TO 1.
	LOCK THROTTLE TO 1.0.
	WAIT 5.
	// SET SHIP:CONTROL:FORE TO 0.
	LOCK THROTTLE TO 0.
	SET DvEnd TO NdDeltaV.
	SET TimeEnd TO TIME.
	
	SET DvDiff TO DvStart - DvEnd.
	SET TimeDiff TO TimeEnd - TimeStart.
	//SET BurnTime TO DvEnd * TimeDiff:SECONDS / DvDiff.
	SET BurnTotal TO DvEnd * DvDiff / TimeDiff:SECONDS.
	GLOBAL BurnTime IS BurnTotal.

	PRINT "DvStart: " + DvStart.
	PRINT "DvEnd: " + DvEnd.
	PRINT "DvDiff: " + DvDiff.
	PRINT "TimeDiff:SECONDS: " + TimeDiff:SECONDS.
	PRINT "Burn time set to " + BurnTime + " seconds".

	SET UseRcs TO False.
	BURN_WAIT().
	BURN(UseRcs).

} ELSE {
	SET UseRcs TO False.
	BURN_WAIT().
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