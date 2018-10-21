//kOS Script: Rendez-Vous
//Author: Simon Lachaîne

FUNCTION MONITOR {
	PRINT "Parameters:" AT (0,30).
	PRINT "-Target distance: " + ROUND(TargetDist) + " meters       " AT (0,31).
	PRINT "-Relative velocity: " + ROUND(RelVel) + " m/s       " AT (0,32).
	//PRINT "-Encounter ETA: " + ROUND(EncEta) + " seconds       " AT (0,33).
}

FUNCTION WAIT_LOOP {
	PARAMETER TARGET_DISTANCE.

	PRINT "Waiting for " + TARGET_DISTANCE + " meters distance".
	SET LoopBreak TO False.

	UNTIL LoopBreak = True {
		MONITOR().
		LOCK STEERING TO ShipSteer.

		IF TargetDist <= TARGET_DISTANCE {
			SET LoopBreak TO True.
		}
	}.
}

FUNCTION BURN_LOOP {
	PARAMETER RELATIVE_SPEED.

	PRINT "Reducing relative velocity to " + RELATIVE_SPEED + " m/s".
	LOCK THROTTLE TO 1.0.
	SET LoopBreak TO False.

	UNTIL LoopBreak = True {
		MONITOR().
		LOCK STEERING TO ShipSteer.
		WAIT 0.001.

		IF RelVel <= RELATIVE_SPEED {
			SET LoopBreak TO True.
		}
	}.
	LOCK THROTTLE TO 0.
}

SAS ON.
RCS OFF.
LOCK TargetDist TO TARGET:DISTANCE.
LOCK RelVelVec TO TARGET:VELOCITY:ORBIT - SHIP:VELOCITY:ORBIT.
LOCK RelVel TO RelVelVec:MAG.
LOCK ShipSteer TO LOOKDIRUP(RelVelVec, SHIP:FACING:UPVECTOR).
CLEARSCREEN.

PRINT "Rendez-Vous program started.".
SAS OFF.
RCS ON.

WAIT_LOOP(5000).
BURN_LOOP(100).
WAIT_LOOP(1000).
BURN_LOOP(50).
WAIT_LOOP(500).
BURN_LOOP(10).

PRINT "Neutralizing relative velocity".
SET SHIP:CONTROL:FORE TO 1.
SET LoopCount TO 0.
SET LoopBreak TO False.

UNTIL LoopBreak = True {
	MONITOR().
	LOCK STEERING TO ShipSteer.
	SET RefVel TO RelVel.
	SET LoopCount TO LoopCount+1.
	WAIT 0.001.

	IF LoopCount >= 10 AND RefVel <= RelVel {
		SET LoopBreak TO True.
	}
}.

SET SHIP:CONTROL:FORE TO 1.
PRINT "Engine shutdown".
UNLOCK STEERING.
UNLOCK THROTTLE.
SAS ON.
RCS OFF.
SET SHIP:CONTROL:NEUTRALIZE to True.
PRINT "Rendez-Vous program completed.".