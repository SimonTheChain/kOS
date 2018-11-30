SET BreakStop TO False.

UNTIL BreakStop = True {
	PRINT "Radar height: " + ALT:RADAR AT(0,10).
	WAIT 0.001.
}.