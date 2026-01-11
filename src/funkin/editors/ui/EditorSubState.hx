package funkin.editors.ui;

import flixel.group.FlxGroup.FlxTypedGroup;
import funkin.jit.InjectedSubState;
import flixel.util.FlxColor;
import funkin.component.ui.*;

import lime.ui.*;

class EditorSubState extends funkin.jit.InjectedSubState {
    var textBoxs:Array<TextBoxWidget> = [];

    override public function new(script:String) {
        super(script);
        flixel.FlxG.stage.window.onKeyDown.add(onKeyDown);
    }

    public function addButton(X:Float, Y:Float, text:String, onClick:Void -> Void) {
        add(new ButtonWidget(this, X, Y, text, onClick));
    }

    public function addTextBox(X:Float, Y:Float, width:Int, buttonText:String, onChange:TextBoxWidget -> Void) {
        var textBox:TextBoxWidget = new TextBoxWidget(this, X, Y, width, buttonText, onChange);
        textBoxs.push(textBox);
        add(textBox);
    }

    public function onKeyDown(key:KeyCode, modifier:KeyModifier) {
        switch (key) {
            default:
                return;
            case ESCAPE:
                var canExit:Bool = false;
                for (textBox in textBoxs) {
                    if (!textBox.editing) canExit = true;
                }
                if (canExit) close();
        }
    }
}