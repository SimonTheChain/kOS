//kOS Script: Neutralize relative inclination
//Author: Simon Lachaîne

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

    RETURN ABS(VANG(SWAPPED_ORBIT_NORMAL(OrbiterA), SWAPPED_ORBIT_NORMAL(OrbiterB))).
}

FUNCTION MONITOR {
	PRINT "Monitor" AT (0,30).
	PRINT "-Relative inclination: " + ROUND(RELATIVEINC(SHIP,TARGET),2) + " degrees       " AT (0,31).
	PRINT "-Plane angle: " + ROUND(PLANE_ANGLE(),2) + " degrees       " AT (0,32).
}

SET Stop TO False.
UNTIL Stop = True {
	MONITOR().
	WAIT 0.001.
}.