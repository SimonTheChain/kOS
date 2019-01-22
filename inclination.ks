//kOS Script: Neutralize relative inclination
//Author: Simon Lachaîne

DECLARE PARAMETER Positive.
DECLARE PARAMETER StoppingTime.

FUNCTION PLANE_ANGLE {
    set a1 to sin(ship:obt:inclination)*cos(ship:obt:LAN).
    set a2 to sin(ship:obt:inclination)*sin(ship:obt:LAN).
    set a3 to cos(ship:obt:inclination).

    set b1 to sin(TARGET:obt:inclination)*cos(TARGET:obt:LAN).
    set b2 to sin(TARGET:obt:inclination)*sin(TARGET:obt:LAN).
    set b3 to cos(TARGET:obt:inclination).

    RETURN arccos(a1*b1+a2*b2+a3*b3).
}

FUNCTION ORBIT_NORMAL {
    PARAMETER OrbitIn.
    
    RETURN VCRS(OrbitIn:body:position - OrbitIn:position,
                OrbitIn:velocity:orbit):normalized.
}

FUNCTION SWAPYZ {
    PARAMETER VecIn.

    RETURN V(VecIn:X, VecIn:Z, VecIn:Y).
}

FUNCTION SWAPPED_ORBIT_NORMAL {
    PARAMETER OrbitIn.

    RETURN -SWAPYZ(ORBIT_NORMAL(OrbitIn)).
}

FUNCTION RELATIVEINC {
    PARAMETER OrbiterA, OrbiterB.

    RETURN VANG(SWAPPED_ORBIT_NORMAL(OrbiterA), SWAPPED_ORBIT_NORMAL(OrbiterB)).
}

FUNCTION MONITOR {
	PRINT "Monitor" AT (0,30).
	PRINT "-Relative inclination: " + ROUND(RELATIVEINC(SHIP,TARGET),2) + " degrees       " AT (0,33).
	PRINT "-Plane angle: " + ROUND(PLANE_ANGLE(),2) + " degrees       " AT (0,34).
}


local shipV is ship:obt:velocity:orbit.
local tarV is target:obt:velocity:orbit.
local shipN is vcrs(shipV,ship:position - body:position).
local tarN is vcrs(tarV,target:position - body:position).
if target:name = body:name { set tarN to body:angularvel. }
set intersectV to vcrs(shipN,tarN).
local shipVec is ship:position - body:position.
local done is false.
local time_mod is 100.
local increment is 100.
local last_angl is vang(shipVec,intersectV).
until done {
        set shipVec to positionat(ship, time:seconds + time_mod) - body:position.
        set angl to vang(shipVec,intersectV).
        set spd to (last_angl-angl)/increment.
               
        if increment = 1 or angl < 0.05 and angl > last_angl {
                // last iteration was closest to target
                set done to true.
                set time_mod to time_mod - increment.
        }
        else {
                set increment to max(min(angl/(spd*1.1),50000),1).
                set last_angl to angl.
                set time_mod to time_mod + increment.
        }
}
global nd is node(time:seconds + time_mod, 0,0,0).
add nd.

CLEARSCREEN.
PRINT "Neutralize inclination program started".
SAS OFF.
RCS ON.
SET STEERINGMANAGER:MAXSTOPPINGTIME TO StoppingTime.
SET STEERINGMANAGER:PITCHPID:KD TO StoppingTime / 10.
SET STEERINGMANAGER:YAWPID:KD TO StoppingTime / 10.
SET NextNd to NEXTNODE.
LOCK NdEta to NextNd:ETA.
LOCK normVec to VCRS(SHIP:BODY:POSITION,SHIP:VELOCITY:ORBIT).  // Cross-product these for a normal vector

IF Positive = "True" {
    LOCK STEERING TO LOOKDIRUP(normVec, SHIP:BODY:POSITION).

} ELSE {
    LOCK STEERING TO LOOKDIRUP(-normVec, SHIP:BODY:POSITION).
}

UNTIL NdEta <= 25 {
	MONITOR().
	WAIT 0.001.
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

PRINT "Engine ignition".
LOCK THROTTLE TO 1.0.
SET SHIP:CONTROL:FORE TO 0.

UNTIL RELATIVEINC(SHIP,TARGET) <= 0.05 {
	MONITOR().
	WAIT 0.001.
}

LOCK THROTTLE TO 0.
PRINT "Engine shutdown".
PRINT "Thrusters ignition".
SET SHIP:CONTROL:FORE TO 1.

UNTIL RELATIVEINC(SHIP,TARGET) <= 0.01 {
    MONITOR().
    WAIT 0.001.
}

SET SHIP:CONTROL:FORE TO 0.
PRINT "Thrusters shutdown".
UNLOCK STEERING.
UNLOCK THROTTLE.
WAIT 1.

REMOVE Nd.
SAS ON.
RCS OFF.
SET SHIP:CONTROL:NEUTRALIZE TO True.
PRINT "Neutralize inclination program completed.".