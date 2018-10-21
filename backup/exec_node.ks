//kOS Script: Execute Maneuver Node
//Author: Simon Lachaîne

SAS ON.
RCS OFF.
SET Nd to NEXTNODE.
LOCK NdDeltaV TO Nd:DELTAV:MAG.
LOCK NdEta to Nd:ETA.
LOCK MaxAcc to SHIP:MAXTHRUST/SHIP:MASS.
PRINT "Node parameters:".
PRINT "-DeltaV: " + ROUND(NdDeltaV).
PRINT "-Node in: " + ROUND(NdEta).

// Now we just need to divide deltav:mag by our ship's max acceleration
// to get the estimated time of the burn.
//
// Please note, this is not exactly correct.  The real calculation
// needs to take into account the fact that the mass will decrease
// as you lose fuel during the burn.  In fact throwing the fuel out
// the back of the engine very fast is the entire reason you're able
// to thrust at all in space.  The proper calculation for this
// can be found easily enough online by searching for the phrase
//   "Tsiolkovsky rocket equation".
// This example here will keep it simple for demonstration purposes,
// but if you're going to build a serious node execution script, you
// need to look into the Tsiolkovsky rocket equation to account for
// the change in mass over time as you burn.
//
SET BurnTime TO NdDeltaV/MaxAcc.
PRINT "Estimated burn duration: " + ROUND(BurnTime) + " seconds".

WAIT UNTIL NdEta <= (BurnTime/2 + 60).

SAS OFF.
RCS ON.
SET Np to Nd:DELTAV.
LOCK STEERING TO Np.

//now we need to wait until the burn vector and ship's facing are aligned
WAIT UNTIL VANG(Np, SHIP:FACING:VECTOR) < 0.25.

//the ship is facing the right direction, let's wait for our burn time
WAIT UNTIL NdEta <= (BurnTime/2).

//we only need to lock throttle once to a certain variable in the beginning of the loop,
//and adjust only the variable itself inside it
SET ThSet TO 0.
LOCK THROTTLE TO ThSet.

SET Done TO FALSE.
//initial deltav
SET Dv0 TO Nd:DELTAV.

UNTIL Done {
	//throttle is 100% until there is less than 1 second of time left to burn
    //when there is less than 1 second - decrease the throttle linearly
    SET ThSet TO MIN(NdDeltaV/MaxAcc, 1).

    //here's the tricky part, we need to cut the throttle as soon as our nd:deltav 
    //and initial deltav start facing opposite directions
    //this check is done via checking the dot product of those 2 vectors
    IF VDOT(Dv0, Nd:DELTAV) < 0 {
        PRINT "End burn, remaining delta-v: " + ROUND(NdDeltaV,1) + "m/s, vdot: " + ROUND(VDOT(Dv0, Nd:DELTAV),1).
        LOCK THROTTLE TO 0.
        BREAK.
    }

    //we have very little left to burn, less then 0.1m/s
    IF NdDeltaV < 0.1 {
        PRINT "Finalizing burn, remaining delta-v " + ROUND(NdDeltaV,1) + "m/s, vdot: " + ROUND(VDOT(Dv0, Nd:DELTAV),1).
        //we burn slowly until our node vector starts to drift significantly from initial vector
        //this usually means we are on point
        WAIT UNTIL VDOT(Dv0, Nd:DELTAV) < 0.5.

        LOCK THROTTLE TO 0.
        PRINT "End burn, remaining delta-v " + ROUND(NdDeltaV,1) + "m/s, vdot: " + ROUND(VDOT(Dv0, Nd:DELTAV),1).
        SET Done TO TRUE.
    }
    WAIT 0.001.
}
UNLOCK STEERING.
UNLOCK THROTTLE.
WAIT 1.

//we no longer need the maneuver node
REMOVE Nd.
SAS ON.
RCS OFF.
//set throttle to 0 just in case.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.