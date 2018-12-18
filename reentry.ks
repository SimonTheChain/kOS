//kOS Script: Earth Reentry
//Author: Simon Lachaîne

DECLARE PARAMETER NeedStaging.

CLEARSCREEN.
LOCK ShipAlt TO SHIP:ALTITUDE.
PRINT "Earth reentry program started".

WAIT UNTIL ShipAlt <= 200000.

SAS OFF.
RCS ON.
PRINT "Aligning ship for reentry".
LOCK Dir TO SHIP:RETROGRADE.

IF NeedStaging = "True" {
    STAGE.

    UNTIL STAGE:READY {
        WAIT 0.001.
    }.
}

UNTIL ShipAlt <= 10000 {
	LOCK STEERING TO Dir.
	WAIT 0.001.
}

PRINT "Arming Parachutes".
STAGE.

UNTIL STAGE:READY {
    WAIT 0.001.
}.

WAIT UNTIL SHIP:STATUS = "LANDED" OR SHIP:STATUS = "SPLASHED".

UNLOCK STEERING.
RCS OFF.
SAS ON.
SET SHIP:CONTROL:NEUTRALIZE to True.
PRINT "Earth reentry program completed.".