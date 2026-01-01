package funkin.game.jit.event;

// https://github.com/CodenameCrew/CodenameEngine
class CountdownEvent extends Cancellable {
    /**
	 * At which count the countdown is.
	 */
	public var swagCounter:Int;

    public function new(swagCounter:Int) {
        super();
        this.swagCounter = swagCounter;
    }
}