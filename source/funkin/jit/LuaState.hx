package funkin.jit;

import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.sound.FlxSound;
import flixel.text.FlxText;

class LuaState extends BuiltinJITState implements ILuaState {

    public function new(path:String) {
        super(path);
    }

    override function create() {
        super.create();
        call("onCreatePost", []);
    }

    override function update(elapsed:Float) {
        super.update(elapsed);
        call("onUpdatePost", [elapsed]);
    }

    override function destroy() {
        call("onDestroy", []);
        super.destroy();
    }
}