package funkin.editors.ui;

import flixel.group.FlxGroup.FlxTypedGroup;
import funkin.jit.InjectedSubState;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import funkin.component.ui.*;

import lime.ui.*;

class EditorSubState extends funkin.jit.InjectedSubState {
    var textBoxs:Array<TextBoxWidget> = [];

    override public function new(script:String) {
        super(script);
        flixel.FlxG.stage.window.onKeyDown.add(onKeyDown);
    }

    public function addButton(X:Float, Y:Float, text:String, onClick:Void -> Void) {
        var button:ButtonWidget = new ButtonWidget(this, X, Y, text, onClick);
        add(button);
        return button;
    }

    public function addText(X, Y, _text:String) {
        var text = new FlxText(X + 2, Y + 2, 114, _text, 18);
        text.wordWrap = false;
        text.autoSize = true;
        text.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(text);
        return text;
    }

    public function addTextList(X:Float, Y:Float, width:Int, buttonText:String, suggestions:Array<String>, onChange:TextBoxWidget -> Void) {
        var textBox:TextBoxWidget = new TextListWidget(this, X, Y, width, buttonText, suggestions, onChange);
        textBoxs.push(textBox);
        add(textBox);
        return textBox;
    }

    public function addTextBox(X:Float, Y:Float, width:Int, buttonText:String, onChange:TextBoxWidget -> Void) {
        var textBox:TextBoxWidget = new TextBoxWidget(this, X, Y, width, buttonText, onChange);
        textBoxs.push(textBox);
        add(textBox);
        return textBox;
    }

    public function addCheckBox(X:Float, Y:Float, text:String, activated:Bool, onClick:Bool -> Void) {
        var checkBox:CheckBoxWidget = new CheckBoxWidget(this, X, Y, text, activated, onClick);
        add(checkBox);
        return checkBox;
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