package funkin.game.jit.event;
// https://github.com/CodenameCrew/CodenameEngine

import flixel.FlxState;

class StateEvent extends Cancellable {
    /**
	 * Substate or State that is about to be opened/closed
	 */
	public var substate:FlxState;  // WHY is it named substate :sob:  - Nex

    public function new(substate:FlxState) {
        super();
        this.substate = substate;
    }
}