package funkin.editors.chart.element;

import flixel.FlxSprite;
import funkin.editors.chart.ChartEditorState;

class GuiElement extends FlxSprite {
    public var strumTime:Float = 0;
    public var dataID:Int;
    public var editor:ChartEditorState = ChartEditorState.INSTANCE;

    public function new(strumTime:Float) {
        super(0, 0);
        this.strumTime = strumTime;
    }

    function updateField(name:String) {
        Reflect.setProperty(this, name, ChartEditorState.data[dataID].get(name));
    }

    override function update(elapsed:Float) {
        ChartEditorState.INSTANCE.updateGrid();
        updatePos();
        if (ChartEditorState.data[dataID] != null) {
            var result:Null<Float> = ChartEditorState.data[dataID].get('strumTime');
            if (result != null) strumTime = result;
        }
        super.update(elapsed);
    }

    function updatePos() {}
}

