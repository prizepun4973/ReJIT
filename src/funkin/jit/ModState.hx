package funkin.jit;

import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.sound.FlxSound;
import flixel.text.FlxText;

class ModState extends BuiltinJITState implements IModState {

    public function new(path:String) {
        super(path);
    }

    override function create() {
        super.create();
        call("create", []);
    }

    override function update(elapsed:Float) {
        super.update(elapsed);
        call("update", [elapsed]);
    }

    override function destroy() {
        call("destroy", []);
        super.destroy();
    }

    override function onFocus() {
        super.onFocus();
        call("onFocus", []);
    }

    override function onFocusLost() {
        super.onFocusLost();
        call("onFocusLost", []);
    }
}