//kOS Script: Moon Landing
//Author: Simon Lachaîne

DECLARE PARAMETER Offset.

FUNCTION MONITOR {
	PRINT "Node parameters:" AT (0,28).
	PRINT "-Node ETA: " + ROUND(NdEta) + " seconds       " AT (0,29).
}

FUNCTION LANDING_MONITOR {
	PARAMETER THRESHOLD_ALT.
	PARAMETER THRESHOLD_SPEED.
	PARAMETER TARGET_SPEED.
	PRINT "Parameters:          " AT (0,28).
	PRINT "-Ship altitude: " + ROUND(ShipAlt) + " meters       " AT (0,29).
	PRINT "-Threshold altitude: " + THRESHOLD_ALT + " meters       " AT (0,30).
	PRINT "-Ship speed: " + ROUND(ShipSpeed) + " m/s       " AT (0,31).
	PRINT "-Threshold speed: " + THRESHOLD_SPEED + " m/s       " AT (0,32).
	PRINT "-Target speed: " + TARGET_SPEED + " m/s       " AT (0,33).
}

FUNCTION LANDING_STEER {
	PARAMETER THRESHOLD_ALT.
	PARAMETER THRESHOLD_SPEED.
	PARAMETER TARGET_SPEED.
	LANDING_MONITOR(THRESHOLD_ALT,THRESHOLD_SPEED,TARGET_SPEED).
	LOCK STEERING TO (-1) * SHIP:VELOCITY:SURFACE.
}

FUNCTION LANDING_LOOP {
	PARAMETER UNTIL_ALT.
	PARAMETER THROTTLE_START.
	PARAMETER THROTTLE_STOP.
	PARAMETER RCS_START.
	PARAMETER RCS_STOP.

	UNTIL ShipAlt <= UNTIL_ALT {
		LANDING_STEER(UNTIL_ALT,THROTTLE_START,THROTTLE_STOP).

		IF ShipSpeed > THROTTLE_START {
			SET THROTTLE TO 1.0.
		}

		IF ShipSpeed <= THROTTLE_STOP {
			SET THROTTLE TO 0.
		}

		IF ShipSpeed > RCS_START {
			SET SHIP:CONTROL:FORE TO 1.
		}

		IF ShipSpeed <= RCS_STOP {
			SET SHIP:CONTROL:FORE TO 0.
		}

		SET RefAlt TO ShipAlt.
		WAIT 0.001.

		IF RefAlt <= ShipAlt {
			LOCK THROTTLE TO 0.
			SET SHIP:CONTROL:FORE TO 0.
		}
	}.
}

SAS ON.
RCS OFF.
SET Nd to NEXTNODE.
LOCK NdEta to Nd:ETA.
LOCK ShipAlt TO ALT:RADAR-Offset.
LOCK ShipSpeed TO SHIP:VELOCITY:SURFACE:MAG.
LOCK ShipRetro TO SHIP:RETROGRADE.
CLEARSCREEN.

PRINT "Landing program started.".

UNTIL NdEta <= 240 {
	MONITOR().
	WAIT 0.001.
}.

PRINT "Aligning vessel to maneuver".
SAS OFF.
RCS ON.
LOCK STEERING TO SHIP:RETROGRADE.

//the ship is facing the right direction, let's wait for our burn time
UNTIL NdEta <= 60 {
	MONITOR().
	WAIT 0.001.
}.

//we no longer need the maneuver node
REMOVE Nd.
WAIT 0.001.

PRINT "Neutralizing horizontal velocity".
LOCK THROTTLE TO 1.
UNTIL SHIP:GROUNDSPEED <= 5 {
	MONITOR().
	LOCK STEERING TO SHIP:RETROGRADE.
	WAIT 0.01.
}
LOCK THROTTLE TO 0.

PRINT "Descent sequence initiated".

WHEN ShipAlt <= 250 THEN {
	PRINT "Deploying gear".
	GEAR ON.
}.

WHEN ShipAlt <= 25 THEN {
	PRINT "Deploying lander".
	STAGE.

	UNTIL STAGE:READY {
		WAIT 0.001.
	}.
}.

LANDING_LOOP(2000,200,150,300,300).
LANDING_LOOP(1000,100,50,200,200).
LANDING_LOOP(500,50,25,100,100).
LANDING_LOOP(200,30,20,50,50).
LANDING_LOOP(100,20,10,25,25).
LANDING_LOOP(25,12,3,25,25).
LANDING_LOOP(2,8,3,2,1).

UNTIL SHIP:STATUS = "LANDED" {
	LANDING_MONITOR("Landed",4,3).
	LOCK STEERING TO "kill".

	IF ShipSpeed > 4 {
		SET SHIP:CONTROL:FORE TO 1.
	}

	IF ShipSpeed <= 3 {
		SET SHIP:CONTROL:FORE TO 0.
	}

	SET RefAlt TO ShipAlt.
	WAIT 0.001.

	IF RefAlt <= ShipAlt {
		LOCK THROTTLE TO 0.
		SET SHIP:CONTROL:FORE TO 0.
	}
}.

SET SHIP:CONTROL:FORE TO 0.
PRINT "Touchdown".
PRINT "Stabilizing".

FROM {local Countdown is 5.} UNTIL Countdown = 0 STEP {SET Countdown TO Countdown - 1.} DO {

    LOCK STEERING TO SHIP:UP.
    WAIT 1.
}

SAS ON.
RCS OFF.
SET SHIP:CONTROL:NEUTRALIZE to True.
PRINT "Landing program completed.".