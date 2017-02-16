/*
	
	Handles the visual effects such as:
	- Strip status
	- End of set visuals
	
*/

#define swRLVMethod$toggleVibrator 1			// (bool)on | Turns the vibrator feature on/off

#define swRLVEvt$vibrators 1					// [(bool)player1, (bool)player2...] | Vibrator state
#define swRLVEvt$clothes 2						// (int)clothes | 4x8bit chunks, the 2 rightmost bits are strip status between 0 (dressed) and 2 (stripped)

#define swRLV$toggleVibrator(on) runMethod((str)LINK_THIS, "sw RLV", swRLVMethod$toggleVibrator, [on], TNN)


