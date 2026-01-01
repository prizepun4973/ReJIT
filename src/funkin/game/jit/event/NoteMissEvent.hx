package funkin.game.jit.event;

import funkin.game.component.Note;
import funkin.game.component.Character;

// https://github.com/CodenameCrew/CodenameEngine
class NoteMissEvent extends Cancellable {

    /**
	 * Note that has been missed
	 */
	public var note:Note;

    public var muteVocals:Bool;

    /**
	 * The amount of health that'll be gained from missing that note. If called from `onPlayerMiss`, the value will be negative.
	 */
	public var healthGain:Float;
    
    public var missVolume:Float;

	/**
	 * Suffix of the animation. "miss" for miss notes, "-alt" for alt notes, "" for normal ones.
	 */
	public var animSuffix:String;

    /**
	 * Character that pressed the note.
	 */
	public var character:Character;

	/**
	 * Direction of the press (0 = Left, 1 = Down, 2 = Up, 3 = Right)
	 */
	public var direction:Int;

    public function new(note:Note, muteVocals:Bool, healthGain:Float, missVolume:Float, animSuffix:String, character:Character, direction:Int) {
        super();
        this.note = note;
        this.muteVocals = muteVocals;
        this.healthGain = healthGain;
        this.missVolume = missVolume;
		this.animSuffix = animSuffix;
        this.character = character;
		this.direction = direction;
    }

    @:dox(hide) public var animCancelled:Bool = false;
    @:dox(hide) public var deleteNote:Bool = true;
	@:dox(hide) public var resetCombo:Bool = true;

    /**
	 * Prevents the default sing animation from being played.
	 */
	public function preventAnim() {
		animCancelled = true;
	}
    @:dox(hide)
    public function cancelAnim() {preventAnim();}

    /**
	 * Prevents the vocals volume from being set to 1 after pressing the note.
	 */
	public function preventVocalsUnmute() {
		muteVocals = true;
	}
    @:dox(hide)
	public function cancelVocalsUnmute() {preventVocalsUnmute();}

    /**
	 * Prevents the vocals volume from being muted in case its a parameter of `onPlayerMiss`
	 */
	public function preventVocalsMute() {
		muteVocals = false;
	}
	@:dox(hide)
	public function cancelVocalsMute() {preventVocalsMute();}
}