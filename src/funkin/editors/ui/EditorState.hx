package funkin.editors.ui;

import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;

class EditorState extends haxe.ui.backend.flixel.UIState {
    public var hudGroup:FlxTypedGroup<FlxSprite> = new FlxTypedGroup();

    override function new(script:String) {
        super(script);
    }

    override function create() {
        super.create();
        Main.fpsVar.visible = false;
    }

    override function destroy() {
        super.destroy();
        Main.fpsVar.visible = true;
    }
}