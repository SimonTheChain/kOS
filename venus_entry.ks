//kOS Script: Venus Entry
//Author: Simon Lachaîne

DECLARE PARAMETER NeedStaging.

CLEARSCREEN.
LOCK ShipAlt TO SHIP:ALTITUDE.
LOCK ShipPeri TO SHIP:PERIAPSIS.
PRINT "Venus entry program started".
SAS OFF.
RCS ON.

WHEN ShipAlt <= 150000 THEN {
    PRINT "Entry interface reached".
}.

IF NeedStaging = "True" {
    STAGE.

    UNTIL STAGE:READY {
        WAIT 0.001.
    }.
}

PRINT "Aligning ship for retroburn".
LOCK Dir TO SHIP:RETROGRADE.
LOCK STEERING TO Dir.

UNTIL VANG(Dir, SHIP:FACING:VECTOR) < 0.5 {
    WAIT 0.001.
}.

PRINT "Engine ignition".
LOCK THROTTLE TO 1.0.

UNTIL ShipPeri <= 40000 {
    WAIT 0.001.
}.

PRINT "Engine shutdown".
LOCK THROTTLE TO 0.

PRINT "Staging".
LOCK Dir TO SHIP:PROGRADE.

UNTIL VANG(Dir, SHIP:FACING:VECTOR) < 1 {
    WAIT 0.001.
}.

STAGE.

UNTIL STAGE:READY {
    WAIT 0.001.
}.

PRINT "Aligning ship for entry interface".
LOCK Dir TO SHIP:RETROGRADE.

UNTIL ShipAlt <= 10000 {
	WAIT 0.001.
}.

PRINT "Arming Parachutes".
STAGE.

UNTIL STAGE:READY {
    WAIT 0.001.
}.

WAIT UNTIL SHIP:STATUS = "LANDED" OR SHIP:STATUS = "SPLASHED".
PANELS ON.
UNLOCK STEERING.
RCS OFF.
SET SHIP:CONTROL:NEUTRALIZE to True.
PRINT "Venus entry program completed.".