package funkin.editors.chart.handle;

import flixel.FlxSprite;
import funkin.editors.chart.element.*;
import funkin.editors.chart.ChartEditorState;

class SelectIndicator extends FlxSprite {
    public var target:GuiElement;

    public function new(target:GuiElement) {
        super(0, 0);

        this.target = target;

        makeGraphic(ChartEditorState.GRID_SIZE, ChartEditorState.GRID_SIZE, 0xff00FFFF);

        updatePos();
    }

    override function update(elapsed:Float) {
        super.update(elapsed);
        updatePos();
    }

    function updatePos() {
        x = target.x + ChartEditorState.GRID_SIZE * 1.5 - 2;
        y = target.y + ChartEditorState.GRID_SIZE * 1.5;
    }
}