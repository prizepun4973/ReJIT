package funkin.game.jit.event;

import funkin.game.component.*;

// https://github.com/CodenameCrew/CodenameEngine
class NoteHitEvent extends Cancellable {
	/**
	 * Note that has been pressed
	 */
	public var note:Note;
	/**
	 * Character that pressed the note.
	 */
	public var character:Character;
	/**
	 * Whenever the Character is a player
	 */
	public var player:Bool;

	/**
	 * Prefix of the rating sprite path. Defaults to "game/score/"
	 */
	public var ratingPrefix:String = !PlayState.isPixelStage ? "" : 'pixelUI/';
	/**
	 * Suffix of the rating sprite path.
	 */
	public var ratingSuffix:String = !PlayState.isPixelStage ? "" : '-pixel';

	/**
	 * Score gained after note press.
	 */
	public var score:Int;
	/**
	 * The amount of health that'll be gained from pressing that note. If called from `onPlayerMiss`, the value will be negative.
	 */
	public var healthGain:Float;

	/**
	 * Scale of combo numbers.
	 */
	public var numScale:Float = !PlayState.isPixelStage ? 0.5 : 6; // TODO: 0.5
	/**
	 * Whenever antialiasing should be enabled on combo number.
	 */
	public var numAntialiasing:Bool = !PlayState.isPixelStage ? ClientPrefs.globalAntialiasing : false;
	/**
	 * Scale of ratings.
	 */
	public var ratingScale:Float = !PlayState.isPixelStage ? 0.7 : 5.1; // TODO: 0.7
	/**
	 * Whenever antialiasing should be enabled on ratings.
	 */
	public var ratingAntialiasing:Bool = !PlayState.isPixelStage ? ClientPrefs.globalAntialiasing : false;

    public function new(note:Note, character:Character, player:Bool, score:Int, healthGain:Float) {
        super();
		this.note = note;
		this.character = character;
		this.player = player;
		this.score = score;
		this.healthGain = healthGain;
    }

	@:dox(hide) public var strumGlowCancelled:Bool = false;
	@:dox(hide) public var deleteNote:Bool = true;

	/**
	 * Prevents the default sing animation from being played.
	 */
	public function preventAnim() {
		note.noAnimation = true;
	}

	@:dox(hide)
	public function cancelAnim() {preventAnim();}

	/**
	 * Prevents the note from being deleted.
	 */
	public function preventDeletion() {
		deleteNote = false;
	}
	@:dox(hide)
	public function cancelDeletion() {preventDeletion();}

	/**
	 * Forces the note to be deleted.
	**/
	public function forceDeletion() {
		deleteNote = true;
	}

	/**
	 * Prevents the strum from glowing after this note has been pressed.
	 */
	public function preventStrumGlow() {
		strumGlowCancelled = true;
	}
	@:dox(hide)
	public function cancelStrumGlow() {preventStrumGlow();}
}