package funkin.editors.ui;

import flixel.FlxBasic;
import flixel.group.FlxGroup.FlxTypedGroup;
import funkin.jit.InjectedSubState;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.FlxSprite;
import funkin.component.ui.*;

import lime.ui.*;

class EditorSubState extends funkin.jit.InjectedSubState {
    var textBoxs:Array<TextBoxWidget> = [];

    var defaultGroup:FlxTypedGroup<FlxBasic> = new FlxTypedGroup<FlxBasic>();

    override public function new(script:String) {
        super(script);
        flixel.FlxG.stage.window.onKeyDown.add(onKeyDown);
        add(defaultGroup);
    }

    public function setBG(w:Int, h:Int) {
        var bg:FlxSprite = new FlxSprite(0, 0).makeGraphic(w, h, 0x64191919);
        bg.centerOffsets();
        bg.screenCenter();
        defaultGroup.add(bg);
        return bg;
    }

    public function addButton(X:Float, Y:Float, text:String, onClick:Void -> Void) {
        var button:ButtonWidget = new ButtonWidget(this, X, Y, text, onClick);
        defaultGroup.add(button);
        return button;
    }

    public function addText(X, Y, _text:String) {
        var text = new FlxText(X + 2, Y + 2, 114, _text, 18);
        text.wordWrap = false;
        text.autoSize = true;
        text.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        defaultGroup.add(text);
        return text;
    }

    public function addTextList(X:Float, Y:Float, width:Int, buttonText:String, suggestions:Array<String>, onChange:TextBoxWidget -> Void) {
        var textBox:TextBoxWidget = new TextListWidget(defaultGroup, this, X, Y, width, buttonText, suggestions, onChange);
        textBoxs.push(textBox);
        defaultGroup.add(textBox);
        return textBox;
    }

    public function addTextBox(X:Float, Y:Float, width:Int, buttonText:String, onChange:TextBoxWidget -> Void) {
        var textBox:TextBoxWidget = new TextBoxWidget(defaultGroup, X, Y, width, buttonText, onChange);
        textBoxs.push(textBox);
        defaultGroup.add(textBox);
        return textBox;
    }

    public function addCheckBox(X:Float, Y:Float, text:String, activated:Bool, onClick:Bool -> Void) {
        var checkBox:CheckBoxWidget = new CheckBoxWidget(defaultGroup, X, Y, text, activated, onClick);
        defaultGroup.add(checkBox);
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