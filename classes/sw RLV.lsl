/*
	
	Handles the visual effects such as:
	- Strip status
	- End of set visuals
	
*/

#define swRLVMethod$toggleVibrator 1			// (bool)on | Turns the vibrator feature on/off


#define swRLV$toggleVibrator(on) runMethod((str)LINK_THIS, "sw RLV", swRLVMethod$toggleVibrator, [on], TNN)

