package funkin.jit;

import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import funkin.jit.script.*;

import funkin.component.*;

class InjectedSubState extends MusicBeatSubstate implements IModState {

    public var script:Script;
    public var _cancel:Bool;

    public var sprites:Map<String, FlxSprite> = new Map();
    public var texts:Map<String, FlxText> = new Map();
    public var tweens:Map<String, FlxTween> = new Map();
    public var timers:Map<String, FlxTimer> = new Map();
    public var sounds:Map<String, FlxSound> = new Map();
    public var variables:Map<String, Dynamic> = new Map();

    public function new(path:String) {
        super();
        _cancel = false;
        script = new LuaScript("scripts/state/substate/"+ path, this, function (lua:LuaScript) { InjectedState.registerCallback(lua); });
    }

    override function destroy() {
        super.destroy();
        clearCache();
    }

    public function clearVar() { variables.clear(); }
    function clearSprites():Void { sprites.clear(); }
    function clearTweens():Void { tweens.clear(); }
    function clearTimers():Void { timers.clear(); }
    function clearSounds():Void { sounds.clear(); }
    function clearTexts():Void { texts.clear(); }
    function clearCache():Void {
        clearSprites();
        clearTweens();
        clearTimers();
        clearSounds();
        clearTexts();
        clearVar();
    }

    function call(name:String, args:Array<Dynamic>):Bool {
        if (script != null) return script.call(name, args) == Script.Function_Stop;
        return false;
    }

    public function getLuaObject(tag:String, text:Bool=true):FlxSprite {
        if(sprites.exists(tag)) return sprites.get(tag);
        if(text && texts.exists(tag)) return texts.get(tag);
        if(variables.exists(tag)) return variables.get(tag);
        return null;
    }
}