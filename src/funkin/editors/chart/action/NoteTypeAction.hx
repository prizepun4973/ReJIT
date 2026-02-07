package funkin.editors.chart.action;

import funkin.editors.chart.ChartEditorState;
import flixel.FlxG;
import flixel.FlxSprite;

class NoteTypeAction extends EditorAction {
    public var datas:Array<Int> = [];
    public var prevType:Array<String> = [];
    public var newType:String;

    public function new(datas:Array<Int>, newType:String) {
        super();

        this.datas = datas;
        this.newType = newType;
        for (i in datas) prevType.push(ChartEditorState.data[i].get('noteType'));

        redo();
    }

    override function redo() {
        for (i in datas) {
            ChartEditorState.data[i].set('noteType', newType);
        }
    }

    override function undo() {
        for (i in 0...datas.length) {
            ChartEditorState.data[datas[i]].set('noteType', prevType[i]);
        }
    }
}