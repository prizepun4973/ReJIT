package funkin.editors.ui;

import flixel.FlxBasic;
import flixel.group.FlxGroup.FlxTypedGroup;
import funkin.jit.InjectedSubState;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.FlxSprite;
import funkin.component.ui.*;

import lime.ui.*;

class EditorSubState extends haxe.ui.backend.flixel.UISubState {
    var mainView:String;

    override function new(mainView:String, script:String) {
        super(script);
        this.mainView = mainView;
    }

    override function create() {
        super.create();
        Main.fpsVar.visible = false;
        addComponent(haxe.ui.ComponentBuilder.fromFile(mainView + '.xml'));
    }

    override function destroy() {
        super.destroy();
        Main.fpsVar.visible = true;
    }
}