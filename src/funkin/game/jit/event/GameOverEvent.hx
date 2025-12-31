package funkin.game.jit.event;
// https://github.com/CodenameCrew/CodenameEngine

class GameOverEvent extends Cancellable {
    /**
	 * The X pos of where the gameover character will be.
	 */
	public var x:Float;

	/**
	 * The Y pos of where the gameover character will be.
	 */
	public var y:Float;

    public var camX:Float;
    public var camY:Float;

    /**
	 * Song for the game over screen. Default to `this.gameOverSong` (`gameOver`)
	 */
	public var gameOverSong:String;

	/**
	 * SFX at the beginning of the game over (Mic drop). Default to `this.lossSFX` (`gameOverSFX`)
	 */
	public var lossSFX:String;

	/**
	 * SFX played whenever the player retries. Defaults to `retrySFX` (`gameOverEnd`)
	 */
	public var retrySFX:String;

    public function new(x:Float, y:Float, camX:Float, camY:Float, gameOverSong:String, lossSFX:String, retrySFX:String) {
        super();
        this.x = x;
        this.y = y;
        this.camX = camX;
        this.camY = camY;
        this.gameOverSong = gameOverSong;
        this.lossSFX = lossSFX;
        this.retrySFX = retrySFX;
    }
}