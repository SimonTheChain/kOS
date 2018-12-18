//kOS Script: Execute Maneuver Node
//Author: Simon Lachaîne

DECLARE PARAMETER StageOnFlameout.
DECLARE PARAMETER StoppingTime.

FUNCTION MONITOR {
	PRINT "Node parameters:" AT (0,30).
	PRINT "-DeltaV: " + ROUND(NdDeltaV) + " m/s       " AT (0,31).
	PRINT "-Node ETA: " + ROUND(NdEta) + " seconds       " AT (0,32).
	PRINT "-Burn time: " + ROUND(BurnTime) + " seconds       " AT (0,33).
	PRINT "-Ignition: " + ROUND(BurnTime/2) + " seconds       " AT (0,34).
}

FUNCTION MANEUVER_TIME {
	PARAMETER dV.

	SET StageRef TO 0.

	FOR e IN AllEngines {
	    IF e:STAGE > StageRef {
	    	SET StageRef TO e:STAGE.
	    }
	}.

	FOR e IN AllEngines {
	    IF e:STAGE = StageRef {
	    	StageEngines:ADD(e).
	    }
	}.

	SET EnginesThrust TO 0.

	FOR e IN StageEngines {
	    SET EnginesThrust TO EnginesThrust + e:MAXTHRUST.
	}.

	LOCAL f IS EnginesThrust * 1000.  // Engine Thrust (kg * m/s²)
	LOCAL m IS SHIP:MASS * 1000.        // Starting mass (kg)
	LOCAL e IS CONSTANT():E.            // Base of natural log
	LOCAL p IS StageEngines[0]:VISP.               // Engine ISP (s)
	LOCAL g IS 9.80665.                 // Gravitational acceleration constant (m/s²)

	RETURN g * m * p * (1 - e^(-dV/(g*p))) / f.
}

FUNCTION BURN_WAIT {
	PARAMETER USE_RCS.

	UNTIL NdEta <= (BurnTime/2){
		MONITOR().
		WAIT 0.001.
	}.

	IF USE_RCS = False {
		SET RcsFire TO (BurnTime / 2) + 12.
		
		UNTIL NdEta <= RcsFire {
			MONITOR().
			WAIT 0.001.
		}.
		
		IF RCS = False {
			RCS ON.
		}

		PRINT "Stabilizing fuel".
		SET SHIP:CONTROL:FORE TO 1.
		SET Time1 to TIME.
		SET Time2 to TIME.

		UNTIL Time2:SECONDS - Time1:SECONDS >= 12 {
			MONITOR().
			WAIT 0.001.
			SET Time2 to TIME.
		}.

		SET SHIP:CONTROL:FORE TO 0.
	}
}

FUNCTION STAGE_ENGINES {
	IF StageEngines[0]:FLAMEOUT {
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

        AllEngines:CLEAR().
        StageEngines:CLEAR().
        LIST ENGINES IN AllEngines.
        FOR e IN AllEngines {
            IF e:IGNITION {
                StageEngines:ADD(e).
            }
        }
	}
}

FUNCTION BURN {
	PARAMETER USE_RCS.

	IF RCS = False {
		RCS ON.
	}

	SET RefDv TO NdDeltaV.
	
	IF USE_RCS = False {
		SET MaxDv TO RefDv.
		PRINT "Engine ignition".
		LOCK THROTTLE TO 1.0.

		UNTIL NdDeltaV <= MaxDv / 2 {
			MONITOR().
			WAIT 0.001.

			IF StageOnFlameout = "True" {
				STAGE_ENGINES().
			}
		}

		UNTIL NdDeltaV <= 3 OR RefDv < NdDeltaV {
			MONITOR().
			SET RefDv TO NdDeltaV.
			WAIT 0.001.

			IF StageOnFlameout = "True"{
				STAGE_ENGINES().
			}
		}.

		LOCK THROTTLE TO 0.
		PRINT "Engine shutdown".
	}

	PRINT "Thrusters ignition".
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
LIST ENGINES IN AllEngines.
SET StageEngines TO LIST().
SET MaxAcc to SHIP:MAXTHRUST/SHIP:MASS.
SET BurnTime TO MANEUVER_TIME(NdDeltaV).

PRINT "Node execution program started".

UNTIL NdEta <= (BurnTime/2 + 500) {
	MONITOR().
	WAIT 0.001.
}.

PRINT "Aligning vessel to maneuver".
SET STEERINGMANAGER:MAXSTOPPINGTIME TO StoppingTime.
SET STEERINGMANAGER:PITCHPID:KD TO StoppingTime / 10.
SET STEERINGMANAGER:YAWPID:KD TO StoppingTime / 10.
SAS OFF.

IF NdDeltaV >= 10 {
	RCS ON.
}

SET Np to Nd:DELTAV.
LOCK STEERING TO Np.

//now we need to wait until the burn vector and ship's facing are aligned
UNTIL VANG(Np, SHIP:FACING:VECTOR) < 0.25 {
	MONITOR().
	WAIT 0.001.
}.

IF NdDeltaV <= 25 AND NdDeltaV > 1 {
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
	PRINT "Testing RCS thrusters power".
	SET DvStart TO NdDeltaV.
	SET TimeStart TO TIME.
	SET SHIP:CONTROL:FORE TO 1.
	WAIT 1.
	SET SHIP:CONTROL:FORE TO 0.
	SET DvEnd TO NdDeltaV.
	SET TimeEnd TO TIME.
	SET DvDiff TO DvStart - DvEnd.
	SET TimeDiff TO TimeEnd - TimeStart.
	GLOBAL BurnTime IS DvEnd * TimeDiff:SECONDS / DvDiff.
	PRINT "Burn time set to " + ROUND(BurnTime) + " seconds".
	SET SHIP:CONTROL:FORE TO -1.
	WAIT 1.
	SET SHIP:CONTROL:FORE TO 0.
	RCS OFF.
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
SET SHIP:CONTROL:NEUTRALIZE TO True.
PRINT "Node execution program completed.".