package funkin.editors.chart.action;

import funkin.editors.chart.ChartEditorState;
import funkin.editors.chart.element.GuiElement;
import funkin.editors.chart.handle.SelectIndicator;
import funkin.editors.chart.element.*;
import funkin.game.component.Note.EventNote;
import flixel.FlxG;
import flixel.FlxSprite;

class LengthChangeAction extends EditorAction {
    public var datas:Array<Int> = [];
    public var snap:Int;
    public var prevLength:Array<Float> = [];

    var dir:Int;

    public function new(datas:Array<Int>, dir:Int) {
        super();

        this.datas = datas;
        snap = ChartEditorState.beatSnap;

        for (i in datas) prevLength.push(ChartEditorState.data[i].get('susLength'));

        this.dir = dir;

        redo();
    }

    override function redo() {
        for (i in datas) {
            var data = ChartEditorState.data[i];
            data.set('susLength', Math.max(0, data.get('susLength') + Conductor.getCrochetAtTime(data.get('strumTime')) * 4 / snap * dir));
        }
    }

    override function undo() {
        for (i in 0...datas.length) {
            var data = ChartEditorState.data[datas[i]];
            data.set('susLength', prevLength[i]);
        }
    }
}