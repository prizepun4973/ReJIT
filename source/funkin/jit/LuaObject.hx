package funkin.jit;

import sys.FileSystem;
import funkin.options.*;
import flixel.FlxSubState;
import llua.Convert;
import llua.Lua;
import llua.LuaL;
import llua.State;
import flixel.FlxG;
import flixel.FlxSprite;
import StringTools;
import flixel.util.FlxColor;
import Type.ValueType;
import flixel.FlxBasic;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.sound.FlxSound;
import openfl.display.BlendMode;

import animateatlas.AtlasFrameMaker;
import flixel.FlxState;

import funkin.options.substates.*;
import funkin.menu.*;
import funkin.component.*;


class LuaObject
{

	// lua field
    public var parent:ILuaState;
	public static var Function_Stop:Dynamic = "##PSYCHLUA_FUNCTIONSTOP";
	public static var Function_Continue:Dynamic = "##PSYCHLUA_FUNCTIONCONTINUE";
	public static var Function_StopLua:Dynamic = "##PSYCHLUA_FUNCTIONSTOPLUA";
    public var lua:State = LuaL.newstate();
    public var scriptName:String = '';
    public var accessedProps:Map<String, Dynamic> = null;

	// ur stuff

    public function new(script:String, parent:ILuaState) {

        this.parent = parent;

		LuaL.openlibs(lua);
		Lua.init_callbacks(lua);

		if (!FileSystem.exists(Paths.getStateLua('', script))) {
			lua = null;
			return;
		}

        var result:Dynamic = LuaL.dofile(lua, Paths.getStateLua('', script));
		var resultStr:String = Lua.tostring(lua, result);

		if (resultStr != null && result != 0) {
			trace("Failed to load " + script);
			lua = null;
			return;
		}

        scriptName = script;
        trace('Loaded lua: ' + script);

        accessedProps = new Map();

		luaInit();
    }

	 // builtin
	 private function defFunction(name:String, callback:Dynamic) {
		 Lua_helper.add_callback(lua, name, callback); // dont replace
	 }

	private function error(text:String) {
		trace(scriptName + ": " + text);
	}

	public function set(variable:String, data:Dynamic) {
		if (lua == null) return;

		Convert.toLua(lua, data);
		Lua.setglobal(lua, variable);
	}

	public function getPropertyLoop(array:Array<String>, ?checkForTextsToo:Bool = true, ?getProperty:Bool = true):Dynamic {
		var result:Dynamic = getObjectDirectly(array[0], checkForTextsToo);
		var end = array.length;
		if (getProperty) end = array.length - 1;

		for (i in 1...end) {
			result = getVarInArray(result, array[i]);
		}
		return result;
	}

	public function getObjectDirectly(objectName:String, ?checkForTextsToo:Bool = true):Dynamic {
		var result:Dynamic = parent.getLuaObject(objectName, checkForTextsToo);
		if (result == null) return getVarInArray(parent, objectName);
		return result;
	}

	public function setVarInArray(instance:Dynamic, variable:String, value:Dynamic):Any {
		var array:Array<String> = variable.split('[');
		if (array.length > 1) {
			var result:Dynamic = null;
			if (parent.variables.exists(array[0])) {
				var retVal:Dynamic = parent.variables.get(array[0]);
				if (retVal != null) result = retVal;
			} else result = Reflect.getProperty(instance, array[0]);

			for (i in 1...array.length) {
				var leNum:Dynamic = array[i].substr(0, array[i].length - 1);
				if (i >= array.length - 1) result[leNum] = value; // Last array
				else result = result[leNum]; // Anything else
			}
			return result;
		}
		/*if(Std.isOfType(instance, Map))
				instance.set(variable,value);
			else */

		if (parent.variables.exists(variable)) {
			parent.variables.set(variable, value);
			return true;
		}

		Reflect.setProperty(instance, variable, value);
		return true;
	}

	function getGroupStuff(group:Dynamic, variable:String)
	{
		var array:Array<String> = variable.split('.');
		if (array.length > 1) {
			var property:Dynamic = Reflect.getProperty(group, array[0]);
			for (i in 1...array.length - 1) {
				property = Reflect.getProperty(property, array[i]);
			}
			switch (Type.typeof(property)) {
				case ValueType.TClass(haxe.ds.StringMap) | ValueType.TClass(haxe.ds.ObjectMap) | ValueType.TClass(haxe.ds.IntMap) | ValueType.TClass(haxe.ds.EnumValueMap):
					return property.get(array[array.length - 1]);
				default:
					return Reflect.getProperty(property, array[array.length - 1]);
			};
		}
		switch (Type.typeof(group)) {
			case ValueType.TClass(haxe.ds.StringMap) | ValueType.TClass(haxe.ds.ObjectMap) | ValueType.TClass(haxe.ds.IntMap) | ValueType.TClass(haxe.ds.EnumValueMap):
				return group.get(variable);
			default:
				return Reflect.getProperty(group, variable);
		};
	}

	function setGroupStuff(group:Dynamic, variable:String, value:Dynamic)
	{
		var array:Array<String> = variable.split('.');
		if (array.length > 1) {
			var property:Dynamic = Reflect.getProperty(group, array[0]);
			for (i in 1...array.length - 1) {
				property = Reflect.getProperty(property, array[i]);
			}
			Reflect.setProperty(property, array[array.length - 1], value);
			return;
		}
		Reflect.setProperty(group, variable, value);
	}

	public function getVarInArray(instance:Dynamic, variable:String):Any {
		var array:Array<String> = variable.split('[');
		if (array.length > 1) {
			var result:Dynamic = null;
			if (parent.variables.exists(array[0])) {
				var retVal:Dynamic = parent.variables.get(array[0]);
				if (retVal != null)
					result = retVal;
			} else result = Reflect.getProperty(instance, array[0]);

			for (i in 1...array.length) {
				var leNum:Dynamic = array[i].substr(0, array[i].length - 1);
				result = result[leNum];
			}
			return result;
		}

		if (parent.variables.exists(variable)) {
			var retVal:Dynamic = parent.variables.get(variable);
			if (retVal != null) return retVal;
		}

		return Reflect.getProperty(instance, variable);
	}

	public function call(event:String, args:Array<Dynamic>):Dynamic {
		if (lua == null) return Function_Continue;

		Lua.getglobal(lua, event);

		for (arg in args) {
			Convert.toLua(lua, arg);
		}

		var result:Null<Int> = Lua.pcall(lua, args.length, 1, 0);

		// Makes it ignore warnings

		var allowed;

		switch (Lua.type(lua, result)) {
			case Lua.LUA_TNIL | Lua.LUA_TBOOLEAN | Lua.LUA_TNUMBER | Lua.LUA_TSTRING | Lua.LUA_TTABLE:
				allowed = true;
			default:
				allowed = false;
		}

		if (result != null && allowed) {
			/*
			var resultStr:String = Lua.tostring(lua, result);
			var error:String = Lua.tostring(lua, -1);
			Lua.pop(lua, 1);
			*/
			if (Lua.type(lua, -1) == Lua.LUA_TSTRING) {
				var error:String = Lua.tostring(lua, -1);
				Lua.pop(lua, 1);
				if (error == 'attempt to call a nil value') return Function_Continue; // Makes it ignore warnings and not break stuff if you didn't put the functions on your lua file
			} return Convert.fromLua(lua, result);
		}

		return Function_Continue;
	}

	public function stop() {
		if (lua == null) return;

		if (accessedProps != null) accessedProps.clear();
		Lua.close(lua);
		lua = null;
	}

	// ur stuff
	function getState(state:String):FlxState {
		switch(state) {
			case "AchievementsMenuState":
				return new AchievementsMenuState();
			case "CreditsState":
				return new CreditsState();
			case "FlashingState":
				return new FlashingState();
			case "FreeplayState":
				return new FreeplayState();
			case "MainMenuState":
				return new MainMenuState();
			case "ModsMenuState":
				return new ModsMenuState();
			case "StoryMenuState":
				return new StoryMenuState();
			case "TitleState":
				return new TitleState();
			case "PlayState":
				return new PlayState();
			default:
				return new LuaState(state);
		}
	}

	// Better optimized than using some getProperty shit or idk
	function getFlxEaseByString(?ease:String = '') {
		switch (StringTools.trim(ease.toLowerCase())) {
			case 'backin':
				return FlxEase.backIn;
			case 'backinout':
				return FlxEase.backInOut;
			case 'backout':
				return FlxEase.backOut;
			case 'bouncein':
				return FlxEase.bounceIn;
			case 'bounceinout':
				return FlxEase.bounceInOut;
			case 'bounceout':
				return FlxEase.bounceOut;
			case 'circin':
				return FlxEase.circIn;
			case 'circinout':
				return FlxEase.circInOut;
			case 'circout':
				return FlxEase.circOut;
			case 'cubein':
				return FlxEase.cubeIn;
			case 'cubeinout':
				return FlxEase.cubeInOut;
			case 'cubeout':
				return FlxEase.cubeOut;
			case 'elasticin':
				return FlxEase.elasticIn;
			case 'elasticinout':
				return FlxEase.elasticInOut;
			case 'elasticout':
				return FlxEase.elasticOut;
			case 'expoin':
				return FlxEase.expoIn;
			case 'expoinout':
				return FlxEase.expoInOut;
			case 'expoout':
				return FlxEase.expoOut;
			case 'quadin':
				return FlxEase.quadIn;
			case 'quadinout':
				return FlxEase.quadInOut;
			case 'quadout':
				return FlxEase.quadOut;
			case 'quartin':
				return FlxEase.quartIn;
			case 'quartinout':
				return FlxEase.quartInOut;
			case 'quartout':
				return FlxEase.quartOut;
			case 'quintin':
				return FlxEase.quintIn;
			case 'quintinout':
				return FlxEase.quintInOut;
			case 'quintout':
				return FlxEase.quintOut;
			case 'sinein':
				return FlxEase.sineIn;
			case 'sineinout':
				return FlxEase.sineInOut;
			case 'sineout':
				return FlxEase.sineOut;
			case 'smoothstepin':
				return FlxEase.smoothStepIn;
			case 'smoothstepinout':
				return FlxEase.smoothStepInOut;
			case 'smoothstepout':
				return FlxEase.smoothStepInOut;
			case 'smootherstepin':
				return FlxEase.smootherStepIn;
			case 'smootherstepinout':
				return FlxEase.smootherStepInOut;
			case 'smootherstepout':
				return FlxEase.smootherStepOut;
		}
		return FlxEase.linear;
	}

	function blendModeFromString(blend:String):BlendMode {
		switch (StringTools.trim(blend.toLowerCase())) {
			case 'add':
				return ADD;
			case 'alpha':
				return ALPHA;
			case 'darken':
				return DARKEN;
			case 'difference':
				return DIFFERENCE;
			case 'erase':
				return ERASE;
			case 'hardlight':
				return HARDLIGHT;
			case 'invert':
				return INVERT;
			case 'layer':
				return LAYER;
			case 'lighten':
				return LIGHTEN;
			case 'multiply':
				return MULTIPLY;
			case 'overlay':
				return OVERLAY;
			case 'screen':
				return SCREEN;
			case 'shader':
				return SHADER;
			case 'subtract':
				return SUBTRACT;
		}
		return NORMAL;
	}

	function resetSpriteTag(tag:String) {
		if (!parent.sprites.exists(tag)) return;

		var sprite:FlxSprite = parent.sprites.get(tag);
		sprite.kill();
		if (sprite.active) convertedParent().remove(sprite, true);

		sprite.destroy();
		parent.sprites.remove(tag);
	}

	function addAnimByIndices(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24, loop:Bool = false) {
		var strIndices:Array<String> = StringTools.trim(indices).split(',');
		var indices:Array<Int> = [];
		for (i in 0...strIndices.length) {
			indices.push(Std.parseInt(strIndices[i]));
		}

		if (parent.sprites.exists(obj)) {
			var sprite:FlxSprite = parent.sprites.get(obj);
			sprite.animation.addByIndices(name, prefix, indices, '', framerate, loop);
			if (sprite.animation.curAnim == null) sprite.animation.play(name, true);
			return true;
		}

		return false;
	}

	function cancelTimer(tag:String) {
		if (parent.timers.exists(tag)) {
			var timer:FlxTimer = parent.timers.get(tag);
			timer.cancel();
			timer.destroy();
			parent.timers.remove(tag);
		}
	}

	function cancelTween(tag:String) {
		if (parent.tweens.exists(tag)) {
			parent.tweens.get(tag).cancel();
			parent.tweens.get(tag).destroy();
			parent.tweens.remove(tag);
		}
	}

	function doTween(tag:String, vars:String, values:Dynamic, duration:Float, ease:String) {
		cancelTween(tag);
		var variables:Array<String> = vars.split('.');
		var tweenTarget:Dynamic = getObjectDirectly(variables[0]);
		if (variables.length > 1) tweenTarget = getVarInArray(getPropertyLoop(variables), variables[variables.length - 1]);

		if (tweenTarget != null) {
			parent.tweens.set(tag, FlxTween.tween(tweenTarget, values, duration, {
				ease: getFlxEaseByString(ease),
				onComplete: function(twn:FlxTween) {
					// TODO PlayState
//					if (!Std.isOfType(parent, PlayState)) {
						 call("onTweenCompleted", [tag]);
						parent.tweens.remove(tag);
//					}
				}}));
		} else error('doTween: Couldnt find object: ' + vars);
	}

	function convertedParent():FlxState {
		return Std.isOfType(parent, BuiltinJITState) ? (cast (parent, BuiltinJITState)) : (cast (parent, FlxState));
	}

	// lua var & functions

	private function luaInit() {

		defFunction("trace",function (text:String) {trace(text);});

		// State JIT

		defFunction("openSubState", function(name:String){
			if (!Std.isOfType(parent, FlxSubState)) {
				var parent:FlxState = (cast (this.parent, FlxState));
				var target:FlxSubState;
				switch (name) {
					default:
						target = new LuaSubState(name);
					case "GameplayChangersSubState":
						target = new GameplayChangersSubstate();
					// case "Prompt":
					// 	target = new Prompt();
					// case "ResetScoreSubState":
					// 	target = new ResetScoreSubState();
					case "ControlsSubState":
						target = new ControlsSubState();
					case "NotesSubState":
						target = new NotesSubState();
					case "BaseOptionsMenu":
						target = new BaseOptionsMenu();
					case "GameplaySettingsSubState":
						target = new GameplaySettingsSubState();
					case "GraphicsSettingsSubState":
						target = new GraphicsSettingsSubState();
					case "VisualsUISubState":
						target = new VisualsUISubState();
				}
				parent.openSubState(target);
			}
		});
		defFunction("closeSubState", function(){
			if (Std.isOfType(parent, BuiltinJITState)) (cast (parent, BuiltinJITState)).closeSubState();
			else (cast (parent, BuiltinJITSubState)).close();
		});
		defFunction("switchState", function (state:String){MusicBeatState.switchState(getState(state));});
		defFunction("instantSwitchState", function (state:String){FlxG.switchState(getState(state));});
		defFunction("cancel", function(){parent._cancel = true;});

		// Properties
		defFunction("getProperty",
		function (variable:String) {
			var result:Dynamic = null;
			var array:Array<String> = variable.split('.');
			if (array.length > 1)
				result = getVarInArray(getPropertyLoop(array), array[array.length - 1]);
			else
				result = getVarInArray(parent, variable);
			return result;
		});
		defFunction("setProperty",
		function (variable:String, value:Dynamic) {
			var array:Array<String> = variable.split('.');
			if (array.length > 1)
			{
				setVarInArray(getPropertyLoop(array), array[array.length - 1], value);
				return true;
			}
			setVarInArray(parent, variable, value);
			return true;
		});
		defFunction( "getPropertyFromClass", 
		function(classVar:String, variable:String) {
			@:privateAccess
			var array:Array<String> = variable.split('.');
			if (array.length > 1) {
				var target:Dynamic = getVarInArray(Type.resolveClass(classVar), array[0]);
				for (i in 1...array.length - 1) {
					target = getVarInArray(target, array[i]);
				}
				return getVarInArray(target, array[array.length - 1]);
			}
			return getVarInArray(Type.resolveClass(classVar), variable);
		});
		defFunction( "setPropertyFromClass", 
		function(classVar:String, variable:String, value:Dynamic) {
			@:privateAccess
			var array:Array<String> = variable.split('.');
			if (array.length > 1) {
				var target:Dynamic = getVarInArray(Type.resolveClass(classVar), array[0]);
				for (i in 1...array.length - 1) {
					target = getVarInArray(target, array[i]);
				}
				setVarInArray(target, array[array.length - 1], value);
				return true;
			}
			setVarInArray(Type.resolveClass(classVar), variable, value);
			return true;
		});
		defFunction("getPropertyFromGroup",
		function (obj:String, index:Int, variable:Dynamic) {
			var array:Array<String> = obj.split('.');
			var realObject:Dynamic = Reflect.getProperty(parent, obj);
			if (array.length > 1)
				realObject = getPropertyLoop(array, true, false);

			if (Std.isOfType(realObject, FlxTypedGroup)) {
				var result:Dynamic = getGroupStuff(realObject.members[index], variable);
				return result;
			}

			var group:Dynamic = realObject[index];
			if (group != null) {
				var result:Dynamic = null;

				if (Type.typeof(variable) == ValueType.TInt) result = group[variable];
				else result = getGroupStuff(group, variable);
				return result;
			}
			error("getPropertyFromGroup: Object #" + index + " from group: " + obj + " doesn't exist!");
			return null;
		});
 		defFunction("removeFromGroup",
		function (obj:String, index:Int, dontDestroy:Bool = false) {
			if (Std.isOfType(Reflect.getProperty(parent, obj), FlxTypedGroup)) {
				var target = Reflect.getProperty(parent, obj).members[index];
				if (!dontDestroy) target.kill();
				Reflect.getProperty(parent, obj).remove(target, true);
				if (!dontDestroy) target.destroy();
				return;
			}
			Reflect.getProperty(parent, obj).remove(Reflect.getProperty(parent, obj)[index]);
		});
		defFunction("setPropertyFromGroup",
		function (obj:String, index:Int, variable:Dynamic, value:Dynamic) {
			var array:Array<String> = obj.split('.');
			var realObject:Dynamic = Reflect.getProperty(parent, obj);
			if (array.length > 1) realObject = getPropertyLoop(array, true, false);

			if (Std.isOfType(realObject, FlxTypedGroup)) {
				setGroupStuff(realObject.members[index], variable, value);
				return;
			}

			var group:Dynamic = realObject[index];
			if (group != null) {
				if (Type.typeof(variable) == ValueType.TInt) {
					group[variable] = value;
					return;
				}
				setGroupStuff(group, variable, value);
			}
		});
		defFunction("getObjectOrder", function(obj:String)
		{
			var array:Array<String> = obj.split('.');
			var target:FlxBasic = getObjectDirectly(array[0]);
			if (array.length > 1) target = getVarInArray(getPropertyLoop(array), array[array.length - 1]);

			if (target != null) return convertedParent().members.indexOf(target);

			error("getObjectOrder: Object " + obj + " doesn't exist!");
			return -1;
		});
		defFunction("setObjectOrder", function(obj:String, position:Int)
		{
			var array:Array<String> = obj.split('.');
			var target:FlxBasic = getObjectDirectly(array[0]);
			if (array.length > 1) target = getVarInArray(getPropertyLoop(array), array[array.length - 1]);

			if (target != null) {
				convertedParent().remove(target, true);
				convertedParent().insert(position, target);
				return;
			}
			error("setObjectOrder: Object " + obj + " doesn't exist!");
		});


		/*
		 	flixel stuff
		*/

		// FlxSprite
		defFunction("makeLuaSprite",
		function (tag:String, image:String, x:Float, y:Float) {
			tag = StringTools.replace(tag, ".", "");
			resetSpriteTag(tag);

			var sprite:FlxSprite = new FlxSprite(x, y);
			if (image != null && image.length > 0) sprite.loadGraphic(Paths.image(image));

			sprite.antialiasing = ClientPrefs.globalAntialiasing;

			parent.sprites.set(tag, sprite);
			sprite.active = true;
		});
		defFunction("makeGraphic",
		function (obj:String, width:Int, height:Int, r:Int = 255, g:Int = 255, b:Int = 255, a:Int = 255) {
			var spr:FlxSprite = parent.sprites.get(obj);
			var color:FlxColor = new FlxColor();
			if (spr != null) spr.makeGraphic(width, height, color.setRGB(r, g, b, a));
		});
		defFunction("makeAnimatedLuaSprite",
		function (tag:String, image:String, x:Float, y:Float, ?spriteType:String = "sparrow") {
			tag = StringTools.replace(tag, ".", "");
			resetSpriteTag(tag);

			var sprite:FlxSprite = new FlxSprite(x, y);
			if (image != null && image.length > 0) sprite.loadGraphic(Paths.image(image));

			// loadFrames

			switch (StringTools.trim(spriteType.toLowerCase()))
			{
				case "texture" | "textureatlas" | "tex":
					sprite.frames = AtlasFrameMaker.construct(image);

				case "texture_noaa" | "textureatlas_noaa" | "tex_noaa":
					sprite.frames = AtlasFrameMaker.construct(image, null, true);

				case "packer" | "packeratlas" | "pac":
					sprite.frames = Paths.getPackerAtlas(image);

				default:
					sprite.frames = Paths.getSparrowAtlas(image);
			}

			sprite.antialiasing = ClientPrefs.globalAntialiasing;

			parent.sprites.set(tag, sprite);
		});
		defFunction("addLuaSprite",
		function (tag:String, front:Bool = false) {
			if (parent.sprites.exists(tag)) {
				convertedParent().add(parent.sprites.get(tag));
			}
		});
		defFunction("addAnimationByPrefix",
		function (obj:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true) {
			var sprite:FlxSprite = parent.sprites.get(obj);
			if (sprite != null) {
				sprite.animation.addByPrefix(name, prefix, framerate, loop);
				if (sprite.animation.curAnim == null) sprite.animation.play(name, true);
			}
		});
		defFunction("addAnimationByIndices",
		function (obj:String, name:String, prefix:String, indices:String, framerate:Int = 24) {
			return addAnimByIndices(obj, name, prefix, indices, framerate, false);
		});
		defFunction("addAnimationByIndicesLoop",
		function (obj:String, name:String, prefix:String, indices:String, framerate:Int = 24) {
			return addAnimByIndices(obj, name, prefix, indices, framerate, true);
		});
		defFunction("addAnimation",
		function (obj:String, name:String, frames:Array<Int>, framerate:Int = 24, loop:Bool = true) {
			var sprite:FlxSprite = parent.sprites.get(obj);
			if (sprite != null)
			{
				sprite.animation.add(name, frames, framerate, loop);
				if (sprite.animation.curAnim == null)
				{
					sprite.animation.play(name, true);
				}
			}
		});
		defFunction("playAnim",
		function (obj:String, name:String, forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0) {
			if (parent.sprites.exists(obj)) {
				var sprite:FlxSprite = parent.sprites.get(obj);
				if (sprite.animation.getByName(name) != null) {
					sprite.animation.play(name, forced, reverse, startFrame);
				}
			}
		});
		defFunction("loadGraphic", function(variable:String, image:String, ?gridX:Int = 0, ?gridY:Int = 0) {
			var split:Array<String> = variable.split('.');
			var spr:FlxSprite = getObjectDirectly(split[0]);
			var animated = gridX != 0 || gridY != 0;

			if(split.length > 1) spr = getVarInArray(getPropertyLoop(split), split[split.length-1]);
			if(spr != null && image != null && image.length > 0) spr.loadGraphic(Paths.image(image), animated, gridX, gridY);
		});
		defFunction("loadFrames", function(variable:String, image:String, spriteType:String = 'auto') {
			var split:Array<String> = variable.split('.');
			var spr:FlxSprite = getObjectDirectly(split[0]);
			if(split.length > 1) spr = getVarInArray(getPropertyLoop(split), split[split.length-1]);

			if(spr != null && image != null && image.length > 0) {
				switch (StringTools.trim(spriteType.toLowerCase())) {
					case "texture" | "textureatlas" | "tex":
						spr.frames = AtlasFrameMaker.construct(image);

					case "texture_noaa" | "textureatlas_noaa" | "tex_noaa":
						spr.frames = AtlasFrameMaker.construct(image, null, true);

					case "packer" | "packeratlas" | "pac":
						spr.frames = Paths.getPackerAtlas(image);

					default:
						spr.frames = Paths.getSparrowAtlas(image);
				}
			}
		});
		defFunction("setBlendMode",
		function(obj:String, blend:String = '') {
			var real = parent.getLuaObject(obj);
			if (real != null)
			{
				real.blend = blendModeFromString(blend);
				return true;
			}

			var killMe:Array<String> = obj.split('.');
			var spr:FlxSprite = getObjectDirectly(killMe[0]);
			if (killMe.length > 1) spr = getVarInArray(getPropertyLoop(killMe), killMe[killMe.length - 1]);

			if (spr != null) {
				spr.blend = blendModeFromString(blend);
				return true;
			}
			error("setBlendMode: Object " + obj + " doesn't exist!");
			return false;
		});
		// FlxTween
		defFunction("doTweenX", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			doTween(tag, vars, {x: value}, duration, ease);});
		defFunction("doTweenY", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			doTween(tag, vars, {y: value}, duration, ease);});
		defFunction("doTweenAngle", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			doTween(tag, vars, {angle: value}, duration, ease);});
		defFunction("doTweenAlpha", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			doTween(tag, vars, {alpha: value}, duration, ease);});
		defFunction("doTweenZoom", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String) {
			doTween(tag, vars, {zoom: value}, duration, ease);});
		defFunction("doTweenColor", function(tag:String, vars:String, r:Int = 255, g:Int = 255, b:Int = 255, a:Int = 255, duration:Float, ease:String) {
			if(tag != null) cancelTween(tag);
			var variables:Array<String> = vars.split('.');
			var penisExam:Dynamic = getObjectDirectly(variables[0]);
			if(variables.length > 1) penisExam = getVarInArray(getPropertyLoop(variables), variables[variables.length-1]);
			if (penisExam != null) {
				var color:FlxColor = new FlxColor();

				var curColor:FlxColor = penisExam.color;
				curColor.alphaFloat = penisExam.alpha;
				parent.tweens.set(tag, FlxTween.color(penisExam, duration, curColor, color.setRGB(r, g, b, a), {
					ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						parent.tweens.remove(tag);
						call("onTweenCompleted", [tag]);
					}}));
			} else error('doTweenColor: Couldnt find object: ' + vars);
		});
		// FlxTimer
		defFunction("runTimer", function(tag:String, time:Float = 1, loops:Int = 1) {
			cancelTimer(tag);
			parent.timers.set(tag, new FlxTimer().start(time, function(tmr:FlxTimer) {
				if(tmr.finished) parent.timers.remove(tag);
					call('onTimerCompleted', [tag, tmr.loops, tmr.loopsLeft]);
			}, loops));
			return tag;
		});
		defFunction("cancelTimer", function(tag:String) cancelTimer(tag));
// FlxText
		defFunction("makeLuaText",
		function(tag:String, text:String, width:Int, x:Float, y:Float) {
			tag = StringTools.replace(tag, '.', '');

			if (parent.texts.exists(tag)) {
				var textRemove:FlxText = parent.texts.get(tag);
				textRemove.kill();
				
				if (textRemove.active) convertedParent().remove(textRemove, true);
				
				textRemove.destroy();
				parent.texts.remove(tag);
			}

			var text:FlxText = new FlxText(x, y, text, width);
			text.active = false;
			parent.texts.set(tag, text);
		});
		defFunction( "setTextFont",
		function(tag:String, newFont:String) {
			var obj:FlxText = parent.texts.get(tag);
			if (obj != null) {
				obj.font = Paths.font(newFont);
				return true;
			}

			error("setTextFont: Object " + tag + " doesn't exist!");
			return false;
		});
		defFunction( "setTextColor", function(tag:String, r:Int = 255, g:Int = 255, b:Int = 255, a:Int = 255) {
			var obj:FlxText = parent.texts.get(tag);
			if (obj != null) {
				var color:FlxColor = new FlxColor();
				obj.color = color.setRGB(r, g, b, a);
				return true;
			}
			error("setTextColor: Object " + tag + " doesn't exist!");
			return false;
		});
		defFunction( "addLuaText",
		function(tag:String) {
			if (parent.texts.exists(tag)) {
				var shit:FlxText = parent.texts.get(tag);
				if (!shit.active) {
					convertedParent().add(shit);
					shit.active = true;
					// trace('added a thing: ' + tag);
				}
			}
		});
		defFunction( "removeLuaText",
		function(tag:String, destroy:Bool = true) {
			if (!parent.texts.exists(tag)) return;

			var textRemove:FlxText = parent.texts.get(tag);
			if (destroy) textRemove.kill();

			if (textRemove.active) {
				convertedParent().remove(textRemove, true);
				textRemove.active = false;
			}

			if (destroy) {
				textRemove.destroy();
				parent.texts.remove(tag);
			}
		});
		// FlxG.keys
		defFunction("keyboardJustPressed",
		function(name:String) {
			return Reflect.getProperty(FlxG.keys.justPressed, name);
		});
		defFunction("keyboardPressed",
		function(name:String) {
			return Reflect.getProperty(FlxG.keys.pressed, name);
		});
		defFunction("keyboardReleased",
		function(name:String) {
			return Reflect.getProperty(FlxG.keys.justReleased, name);
		});
		// FlxG.sound
		defFunction("playMusic",
		function(sound:String, volume:Float = 1, loop:Bool = false) {
			FlxG.sound.playMusic(Paths.music(sound), volume, loop);
		});
		defFunction("playSound",
		function(sound:String, volume:Float = 1, ?tag:String = null) {
			if (tag != null && tag.length > 0) {
				tag = StringTools.replace(tag, '.', '');
				if (parent.sounds.exists(tag)) parent.sounds.get(tag).stop();
				parent.sounds.set(tag, FlxG.sound.play(Paths.sound(sound), volume, false, function() {
					parent.sounds.remove(tag);
					call('onSoundFinished', [tag]);
				}));
				return;
			}
			FlxG.sound.play(Paths.sound(sound), volume);
		});
		defFunction("stopSound",
		function(tag:String) {
			if (tag != null && tag.length > 1 && parent.sounds.exists(tag)) {
				parent.sounds.get(tag).stop();
				parent.sounds.remove(tag);
			}
		});
		defFunction("pauseSound",
		function(tag:String) {
			if (tag != null && tag.length > 1 && parent.sounds.exists(tag)) parent.sounds.get(tag).pause();
		});
		defFunction("resumeSound",
		function(tag:String) {
			if (tag != null && tag.length > 1 && parent.sounds.exists(tag)) parent.sounds.get(tag).play();
		});
		defFunction("soundFadeIn",
		function(tag:String, duration:Float, fromValue:Float = 0, toValue:Float = 1) {
			if (tag == null || tag.length < 1) FlxG.sound.music.fadeIn(duration, fromValue, toValue);
			else if (parent.sounds.exists(tag)) parent.sounds.get(tag).fadeIn(duration, fromValue, toValue);
		});
		defFunction("soundFadeOut",
		function(tag:String, duration:Float, toValue:Float = 0) {
			if (tag == null || tag.length < 1) FlxG.sound.music.fadeOut(duration, toValue);
			else if (parent.sounds.exists(tag)) parent.sounds.get(tag).fadeOut(duration, toValue);
		});
		defFunction("soundFadeCancel",
		function(tag:String) {
			if (tag == null || tag.length < 1) {
				if (FlxG.sound.music.fadeTween != null)
					FlxG.sound.music.fadeTween.cancel();
			}
			else if (parent.sounds.exists(tag)) {
				var theSound:FlxSound = parent.sounds.get(tag);
				if (theSound.fadeTween != null) {
					theSound.fadeTween.cancel();
					parent.sounds.remove(tag);
				}
			}
		});
		defFunction("getSoundVolume",
		function(tag:String) {
			if (tag == null || tag.length < 1) if (FlxG.sound.music != null) return FlxG.sound.music.volume;
			else if (parent.sounds.exists(tag)) return parent.sounds.get(tag).volume;
			return 0;
		});
		defFunction("setSoundVolume",
		function(tag:String, value:Float) {
			if (tag == null || tag.length < 1) if (FlxG.sound.music != null) FlxG.sound.music.volume = value;
			else if (parent.sounds.exists(tag)) parent.sounds.get(tag).volume = value;
		});
		defFunction("getSoundTime",
		function(tag:String) {
			if (tag != null && tag.length > 0 && parent.sounds.exists(tag)) return parent.sounds.get(tag).time;
			return 0;
		});
		defFunction("setSoundTime",
		function(tag:String, value:Float) {
			if (tag != null && tag.length > 0 && parent.sounds.exists(tag)) {
				var theSound:FlxSound = parent.sounds.get(tag);
				if (theSound != null) {
					var wasResumed:Bool = theSound.playing;
					theSound.pause();
					theSound.time = value;
					if (wasResumed)
						theSound.play();
				}
			}
		});
		
		defFunction("stringStartsWith", function(str:String, start:String) {return StringTools.startsWith(str, start);});
		defFunction("stringEndsWith",function(str:String, end:String) {return StringTools.endsWith(str, end);});
		defFunction("stringSplit",function(str:String, split:String) {return str.split(split);});
		defFunction("stringTrim",function(str:String) {return StringTools.trim(str);});
	}
}
