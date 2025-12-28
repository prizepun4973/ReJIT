package funkin.jit.script;

import flixel.FlxState;

class Script {

    public static var Function_Stop:Dynamic = "##PSYCHLUA_FUNCTIONSTOP";
	public static var Function_Continue:Dynamic = "##PSYCHLUA_FUNCTIONCONTINUE";
	public static var Function_StopLua:Dynamic = "##PSYCHLUA_FUNCTIONSTOPLUA";

    public var target:FlxState;
    public function new(scriptName:String, target:FlxState) {}
    public function set(name:String, value:Any) {}
    public function call(name:String, args:Array<Dynamic>):Dynamic { return null; }
    public function stop() {}
    
}