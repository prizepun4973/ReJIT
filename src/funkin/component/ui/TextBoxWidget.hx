package funkin.component.ui;

import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxSprite;

import lime.ui.*;

class TextBoxWidget extends FlxSprite {
    var onChange:Void -> Void;
    var displayText:FlxText;
    var indicator:FlxSprite;

    var editing:Bool = false;

    public override function new(parent:flixel.group.FlxGroup.FlxTypedGroup<flixel.FlxBasic>, X:Float, Y:Float, width:Int, buttonText:String, onChange:Void -> Void) {
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
        var hovering:Bool = FlxG.mouse.x < x + width && FlxG.mouse.y > y && FlxG.mouse.y < y + height && FlxG.mouse.justReleased;

        if (FlxG.mouse.justReleased) {
            if (!hovering && editing) onChange();
            editing = hovering;
        }
    }

    public function onKeyDown(e:KeyCode, modifier:KeyModifier) {
        
        var soundKey:Bool = false;
        for (i in [FlxG.sound.muteKeys, FlxG.sound.volumeDownKeys, FlxG.sound.volumeUpKeys]) if (FlxG.keys.anyJustPressed(i)) soundKey = true;

        if (editing && !soundKey) {
            switch (e) {
                case BACKSPACE:
                    // delete
                case DELETE:
                    // delete:
                case LEFT:
                    // left
                case RIGHT:
                    //
                case ESCAPE | RETURN:
                    editing = false;
                    onChange();

                default:
                    displayText.text = Std.string(FlxG.keys.firstJustPressed());
            }
        }
        
    }
}