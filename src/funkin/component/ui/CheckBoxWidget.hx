package funkin.component.ui;

import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class CheckBoxWidget extends flixel.FlxSprite {
    var onClick:Bool -> Void;
    var text:FlxText;

    var activated:Bool = false;

    public override function new(parent:flixel.group.FlxGroup.FlxTypedGroup<flixel.FlxBasic>, X:Float, Y:Float, checkBoxText:String, activated:Bool, onClick:Bool -> Void) {
        super(X, Y);
        
        text = new FlxText(X, Y, 400, checkBoxText, 18);
        text.wordWrap = false;
        text.autoSize = true;
        text.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

        this.activated = activated;

        makeGraphic(Std.int(text.height), Std.int(text.height));

        x += text.width + 6;

        parent.add(this);
        parent.add(text);
        this.onClick = onClick;
    }

    override function update(elapsed:Float) {
        if (CoolUtil.mouseInRange(x, x + width, y, y + height) && FlxG.mouse.justPressed) {
            activated = !activated;
            onClick(activated);
            color = activated ? 0xFFFFFFFF : 0xFFFFFF00;
        }
        
        super.update(elapsed);
    }
}