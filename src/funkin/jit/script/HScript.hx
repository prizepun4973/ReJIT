package funkin.jit.script;

#if sys
import sys.FileSystem;
import sys.io.File;
#end
import funkin.jit.InjectedState;
import hscript.Parser;
import hscript.Interp;
import hscript.Expr;

import flixel.FlxState;
import funkin.game.component.Character;
import funkin.jit.script.Script;

typedef ClassRegistry = {
	var className:String;
	var classPackage:String;
}

class HScript extends Script {

	static var registeredClass:Array<ClassRegistry>;

    function setup() {

		if (registeredClass.length > 0) {
			for (i in registeredClass) {
				var libName = i.className;
				var libPackage = i.classPackage;
				interp.variables.set(libName, Type.resolveClass(libPackage != "" ? libPackage + "." + libName : libName));
			}
		}
		

		interp.variables.set('Function_Stop', Script.Function_Stop);
		interp.variables.set('Function_Continue', Script.Function_Continue);
		interp.variables.set('Function_StopLua', Script.Function_StopLua);
		
        /**
		 * lua jit
		 */
		interp.variables.set('game', 'PlayState.instance');
		interp.variables.set('CustomSubstate', funkin.game.jit.FunkinLua.CustomSubstate);

		interp.variables.set('setVar', function(name:String, value:Dynamic) { convertedParent().variables.set(name, value); });
		interp.variables.set('getVar', function(name:String){ 
			if (convertedParent().variables.exists(name)) return convertedParent().variables.get(name);
			return null;
		});
		interp.variables.set('removeVar', function(name:String) {
			if (convertedParent().variables.exists(name)) {
				convertedParent().variables.remove(name);
				return true;
			}
			return false;
		});

		// // flixel
        // addClass('FlxG', 'flixel');
		// addClass('FlxSprite', 'flixel');
		// addClass('FlxCamera', 'flixel');
		// addClass('FlxTimer', 'flixel.util');
		// addClass('FlxTween', 'flixel.tweens');
		// addClass('FlxEase', 'flixel.tweens');
		// #if (!flash && sys) addClass('FlxRuntimeShader', 'flixel.addons.display'); #end
		// addClass('ShaderFilter', 'openfl.filters');
		
		// // haxe
		// addClass('StringTools', '');

		// // funkin
		
		// addClass('PlayState', '');
		// addClass('Paths', '');
		// addClass('Conductor', '');
		// addClass('ClientPrefs', '');
		// addClass('Character', 'funkin.game.component');
		// addClass('Alphabet', 'funkin.component');
		
		// addClass('ModState', 'funkin.jit');
		// addClass('ModSubState', 'funkin.jit');
    }

	public var parser:Parser = new Parser();
	public var interp:Interp;
    public var code:String = "";

    public var path:String;
	public var parentLua:Dynamic = null; // LuaScript

	public function new(path:String, target:FlxState) {
        super(path, target);
		interp = new Interp();
        interp.scriptObject = target;
        this.target = target;
        this.path = path;

        // https://github.com/CodenameCrew/CodenameEngine
        interp.variables.set("trace", Reflect.makeVarArgs((args) -> {
			var v:String = Std.string(args.shift());
			for (a in args) v += ", " + Std.string(a);
			Sys.println(path + '.hx: ' + Std.string(v));
		}));

        setup();

        if (FileSystem.exists(path) && !StringTools.endsWith(path, ".lua")) {
			trace("path: " + path);
			execute(File.getContent(path));
		}
	}

	public function execute(codeToRun:String):Dynamic {
		@:privateAccess
		parser.line = 1;
		parser.allowTypes = true;

        code = codeToRun;

		try {
			return interp.execute(parser.parseString(codeToRun));
		}
		catch (e:Dynamic) {
			Sys.println(StringTools.replace(e, "hscript:", path + (parentLua != null ? parentLua.scriptName + " - " + parentLua.lastCalledFunction : "") + ": "));
			return null;
		}
	}

    function convertedParent():Dynamic {
        return Std.isOfType(target, IModState) ? (cast (target, IModState)) : (cast (target, PlayState));
    }

	// https://github.com/CodenameCrew/CodenameEngine
	override function call(funcName:String, args:Array<Dynamic>) {
		if (interp == null) return null;
		if (!interp.variables.exists(funcName)) return null;

		var func = interp.variables.get(funcName);
		if (func != null && Reflect.isFunction(func)) {
			try {
				return Reflect.callMethod(null, func, args);
			}
			catch (e:Dynamic) {
				Sys.println(e);
				return null;
			}
		}
		
		return null;
	}

	public static function loadMappings() {
		if (!FileSystem.exists("mappings.json")) return;
		try {
			registeredClass = cast haxe.Json.parse(File.getContent("mappings.json"));
		}
		catch (e:Dynamic) {
			trace("Invalid mappings file");
		}
	}
}