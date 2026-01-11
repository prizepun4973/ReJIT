package funkin.editors.ui;

import flixel.group.FlxGroup.FlxTypedGroup;
import funkin.jit.InjectedSubState;
import flixel.util.FlxColor;
import funkin.component.ui.*;
import flixel.FlxSprite;
import flixel.FlxG;

import lime.ui.*;

class EditorSubState extends funkin.jit.InjectedSubState {
    public var widgets:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();

    override public function new(script:String) {
        super(script);
        add(widgets);
        FlxG.stage.window.onKeyDown.add(onKeyDown);
    }

    public function addButton(X:Float, Y:Float, text:String, onClick:Void -> Void) {
        widgets.add(new ButtonWidget(this, X, Y, text, onClick));
    }

    public function addTextBox(X:Float, Y:Float, width:Int, buttonText:String, onChange:TextBoxWidget -> Void) {
        widgets.add(new TextBoxWidget(this, X, Y, width, buttonText, onChange));
    }

    public function onKeyDown(key:KeyCode, modifier:KeyModifier) {
        switch (key) {
            default:
                return;
            case ESCAPE:
                var canExit:Bool = false;
                widgets.forEachAlive(function (widget:FlxSprite) {
                    if (Std.isOfType(widget, TextBoxWidget)) {
                        var textBox:TextBoxWidget = cast (widget, TextBoxWidget);
                        if (!textBox.editing) canExit = true;
                    }
                });
                if (canExit) close();
        }
    }
}