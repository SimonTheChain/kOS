//kOS Script: Earth Reentry
//Author: Simon Lachaîne

DECLARE PARAMETER PreStage.

CLEARSCREEN.
LOCK ShipAlt TO SHIP:ALTITUDE.
PRINT "Earth reentry program started (20181027-1244)".

WAIT UNTIL ShipAlt <= 200000.

SAS OFF.
RCS ON.
PRINT "Aligning ship for reentry".
LOCK Dir TO SHIP:RETROGRADE.

IF PreStage = "True" {
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

WAIT UNTIL SHIP:STATUS = "LANDED".

UNLOCK STEERING.
RCS OFF.
SAS ON.
SET SHIP:CONTROL:NEUTRALIZE to True.
PRINT "Earth reentry program completed.".