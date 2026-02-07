package funkin.component.ui;

import flixel.FlxState;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxSprite;

import lime.ui.*;
import flixel.input.keyboard.FlxKey;

class TextBoxWidget extends FlxSprite {
    var onChange:TextBoxWidget -> Void;
    var displayText:FlxText;

    public var editing:Bool = false;

    public override function new(parent:flixel.group.FlxGroup.FlxTypedGroup<flixel.FlxBasic>, X:Float, Y:Float, width:Int, buttonText:String, onChange:TextBoxWidget -> Void) {
        super(X, Y);
        
        displayText = new FlxText(X + 2, Y + 2, width, buttonText, 18);
        displayText.wordWrap = false;
        displayText.autoSize = true;
        displayText.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

        makeGraphic(width + 4, Std.int(displayText.height) + 4);

        parent.add(this);
        parent.add(displayText);
        this.onChange = onChange;

        FlxG.stage.window.onKeyDown.add(onKeyDown);
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if (FlxG.mouse.justReleased) {
            if (!isHovering() && editing) onChange(this);
            editing = isHovering();
        }
    }

    public function isHovering() {
        return CoolUtil.mouseInRange(x, x + width, y, y + height);
    }

    public function onKeyDown(key:KeyCode, modifier:KeyModifier) {
        
        var soundKey:Bool = false;
        for (i in [FlxG.sound.muteKeys, FlxG.sound.volumeDownKeys, FlxG.sound.volumeUpKeys]) if (FlxG.keys.anyJustPressed(i)) soundKey = true;

        if (editing && !soundKey) {
            switch (key) {
                case ESCAPE | RETURN | NUMPAD_ENTER:
                    editing = false;
                    onChange(this);
                    return;
                case BACKSPACE | DELETE:
                    var result:String = '';
                    for (i in 0...(displayText.text.length - 1)) result += displayText.text.charAt(i);
                    displayText.text = result;
                    if (FlxG.keys.pressed.CONTROL) displayText.text = '';
                
                default:
                    displayText.text += getKeyName(FlxG.keys.firstJustPressed());
            }
        }
        
    }

    public function setText(result:String) {
        displayText.text = result;
    }

    public function getText() {
        return displayText.text;
    }

    public static function getKeyName(key:FlxKey):String {
        var blackList:Array<FlxKey> = [
            NONE,
            MENU,
            SHIFT,
            UP,
            DOWN,
            LEFT,
            RIGHT,
            CONTROL,
            ALT,
            MENU,
            PAGEUP,
            PAGEDOWN,
            END,
            HOME,
            INSERT,
            PRINTSCREEN,
            SCROLL_LOCK,
            F1,
            F2,
            F3,
            F4,
            F5,
            F6,
            F7,
            F8,
            F9,
            F10,
            F11,
            F12,
            NUMLOCK,
            CAPSLOCK,
            MENU,
            WINDOWS
        ];
        for (i in blackList) if (key == i) return '';

        var shift:Bool = FlxG.keys.pressed.SHIFT;
		switch (key) {
			case ZERO | NUMPADZERO:
				return (shift ? ")" : "0");
			case ONE | NUMPADONE:
				return (shift ? "!" : "1");
			case TWO | NUMPADTWO:
				return (shift ? "@" : "2");
			case THREE | NUMPADTHREE:
				return (shift ? "#" : "3");
			case FOUR | NUMPADFOUR:
				return (shift ? "$" : "4");
			case FIVE | NUMPADFIVE:
				return (shift ? "%" : "5");
			case SIX | NUMPADSIX:
				return (shift ? "^" : "6");
			case SEVEN | NUMPADSEVEN:
				return (shift ? "&" : "7");
			case EIGHT | NUMPADEIGHT:
				return (shift ? "*" : "8");
			case NINE | NUMPADNINE:
				return (shift ? "(" : "9");
			case NUMPADMULTIPLY:
				return (shift ? "(" : "9");
			case NUMPADPLUS:
				return (shift ? "+" : "=");
			case NUMPADMINUS:
				return (shift ? "_" : "-");
			case PERIOD | NUMPADPERIOD:
				return (shift ? ">" : ".");
			case SEMICOLON:
				return (shift ? ":" : ";");
			case COMMA:
				return (shift ? "<" : ",");
			case SLASH | NUMPADSLASH:
				return (shift ? "/" : "?");
			case GRAVEACCENT:
				return (shift ? "~" : "`");
			case LBRACKET:
				return (shift ? "{" : "[");
			case BACKSLASH:
				return (shift ? "|" : "\\");
			case RBRACKET:
				return (shift ? "}" : "]");
			case QUOTE:
				return (shift ? "\"" : "'");
            case TAB:
                return '    ';
            case SPACE:
                return ' ';
			default:
				var label:String = '' + key;
				if(label.toLowerCase() == 'null') return '';
                var result:String = ('' + label.charAt(0).toUpperCase() + label.substr(1).toLowerCase());
				return shift? result : result.toLowerCase();
		}
	}

    public function getInt():Dynamic {
        return Std.parseInt(getText());
    }

    public function getFloat() {
        return Std.parseFloat(getText());
    }
}