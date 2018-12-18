//kOS Script: Rendez-Vous
//Author: Simon Lachaîne

FUNCTION MONITOR {
	PRINT "Parameters:" AT (0,30).
	PRINT "-Target distance: " + ROUND(TargetDist) + " meters       " AT (0,31).
	PRINT "-Relative velocity: " + ROUND(RelVel,1) + " m/s       " AT (0,32).
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

// Uncomment for heavy ships with low RCS power
//SET STEERINGMANAGER:MAXSTOPPINGTIME TO 5.
//SET STEERINGMANAGER:PITCHPID:KD TO 1.
//SET STEERINGMANAGER:YAWPID:KD TO 1.
CLEARSCREEN.

PRINT "Rendez-Vous program started.".
SAS OFF.
RCS OFF.

WAIT_LOOP(5000).

IF RelVel > 100 {
	BURN_LOOP(100).
}

WAIT_LOOP(1000).

IF RelVel > 50 {
	BURN_LOOP(50).
}

WAIT_LOOP(500).

IF RelVel > 3 {
	BURN_LOOP(3).
}

PRINT "Neutralizing relative velocity".
PRINT "Thrusters ignition".
SET RefVel TO RelVel.
RCS ON.
SET SHIP:CONTROL:FORE TO 1.
WAIT 0.1.

UNTIL RefVel <= RelVel OR RelVel <= 0.1 {
	MONITOR().
	LOCK STEERING TO ShipSteer.
	SET RefVel TO RelVel.
	WAIT 0.001.
}.

PRINT "Thrusters shutdown".
SET SHIP:CONTROL:FORE TO 0.
RCS OFF.
PRINT "Relative velocity neutralized".

PRINT "Aligning to target".
SET ShipSteer TO TARGET:POSITION.
LOCK STEERING TO ShipSteer.

UNTIL VANG(SHIP:FACING:FOREVECTOR, TARGET:POSITION) < 2 {
	MONITOR().
	WAIT 0.001.
}.

PRINT "Approaching target".
RCS ON.
SET SHIP:CONTROL:FORE TO 1.

UNTIL TargetDist <= 150 {
	MONITOR().

	IF RelVel >= 3 {
		SET SHIP:CONTROL:FORE TO 0.
	}

	WAIT 0.001.
}

SET RefVel TO RelVel.
SET SHIP:CONTROL:FORE TO -1.
WAIT 0.1.

UNTIL RefVel <= RelVel OR RelVel <= 0.1 {
	MONITOR().
	SET RefVel TO RelVel.
	WAIT 0.001.
}.

SET SHIP:CONTROL:FORE TO 0.
RCS OFF.
PRINT "Final approach".

SET ShipSteer TO TARGET:POSITION.
LOCK STEERING TO ShipSteer.

UNTIL VANG(SHIP:FACING:FOREVECTOR, TARGET:POSITION) < 5 {
	MONITOR().
	WAIT 0.001.
}.

RCS ON.
SET SHIP:CONTROL:FORE TO 1.

UNTIL TargetDist <= 50 {
	MONITOR().

	IF RelVel >= 1 {
		SET SHIP:CONTROL:FORE TO 0.
	}

	WAIT 0.001.
}

SET RefVel TO RelVel.
SET SHIP:CONTROL:FORE TO -1.
WAIT 0.1.

UNTIL RefVel <= RelVel OR RelVel <= 0.1 {
	MONITOR().
	SET RefVel TO RelVel.
	WAIT 0.001.
}.

SET SHIP:CONTROL:FORE TO 0.

UNLOCK STEERING.
UNLOCK THROTTLE.
SAS ON.
RCS OFF.
SET SHIP:CONTROL:NEUTRALIZE to True.
PRINT "Rendez-Vous program completed.".