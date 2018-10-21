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

    UNTIL LoopBreak = True {
        MONITOR().
        SET RefDv TO NdDeltaV.
        WAIT 0.001. 

        SET LoopCount TO LoopCount+1.
        PRINT "LoopCount: " + LoopCount AT(0,20).
        PRINT "RefDv: " + RefDv AT(0,21).
        PRINT "NdDeltaV: " + NdDeltaV AT(0,22).
        PRINT "RefDv < NdDeltaV: " + (RefDv < NdDeltaV) AT(0,23).
        
        IF LoopCount >= 10 AND RefDv < NdDeltaV {
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

SAS ON.
RCS OFF.
SET Nd to NEXTNODE.
LOCK NdDeltaV TO Nd:DELTAV:MAG.
LOCK NdEta to Nd:ETA.
LOCK MaxAcc to SHIP:MAXTHRUST/SHIP:MASS.
SET BurnTime TO NdDeltaV/MaxAcc.
CLEARSCREEN.

PRINT "Node execution program started.".

UNTIL NdEta <= (BurnTime/2 + 100) {
    MONITOR().
    WAIT 0.001.
}.

SAS OFF.
RCS ON.
SET Np to Nd:DELTAV.
LOCK STEERING TO Np.

//now we need to wait until the burn vector and ship's facing are aligned
UNTIL VANG(Np, SHIP:FACING:VECTOR) < 0.25 {
    MONITOR().
    WAIT 0.001.
}.

IF BurnTime <= 2 {
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
    SET DvPercent TO DvDiff / (DvStart * 100).
    SET BurnTime TO DvEnd * TimeDiff:SECONDS / (DvDiff - TimeDiff:SECONDS).

    PRINT "DvDiff: " + DvDiff.
    PRINT "DvPercent: " + DvPercent.
    PRINT "TimeDiff:SECONDS: " + TimeDiff:SECONDS.
    PRINT "Burn time set to " + BurnTime + " seconds".

    SET UseRcs TO True.
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
RCS OFF.
PRINT "Burn completed".

WAIT UNTIL SHIP:ALTITUDE <= 150000.
PRINT "Staging".
RCS ON.

SET Dir TO SHIP:PROGRADE.
LOCK STEERING TO Dir.
WAIT UNTIL VANG(SHIP:FACING:FOREVECTOR,Dir:FOREVECTOR) < 2.
STAGE.

UNTIL STAGE:READY {
	WAIT 0.001.
}.

SET SHIP:CONTROL:FORE TO 1.
SET Now to TIME:SECONDS.
WAIT UNTIL TIME:SECONDS > Now + 3.
SET SHIP:CONTROL:FORE to 0.0.

PRINT "Aligning ship for reentry".
LOCK Dir TO SHIP:RETROGRADE.

UNTIL SHIP:ALTITUDE <= 5000 {
	LOCK STEERING TO Dir.
	WAIT 0.001.
}

PRINT "Arming Parachutes".
STAGE.


UNLOCK STEERING.
UNLOCK THROTTLE.
RCS OFF.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
SET SHIP:CONTROL:NEUTRALIZE to TRUE.