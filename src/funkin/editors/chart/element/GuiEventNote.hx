package funkin.editors.chart.element;

import funkin.editors.chart.ChartEditorState;
import funkin.editors.chart.ChartEditorState.GuiElement;
import funkin.editors.chart.action.EventAddAction;
import funkin.game.component.Note.EventNote;

class GuiEventNote extends GuiElement {
    public var events:Array<EventNote>;

    public function new(strumTime:Float, events:Array<EventNote>, relatedAction = null) {
        super(0, 0);

        this.strumTime = strumTime;
        this.events = events;
        this.relatedAction = relatedAction;

        loadGraphic(Paths.image("eventArrow"));
        setGraphicSize(ChartEditorState.GRID_SIZE, ChartEditorState.GRID_SIZE);
        centerOffsets();
        centerOrigin();

        offset.x -= ChartEditorState.GRID_SIZE / 2 - 5;
        offset.y -= ChartEditorState.GRID_SIZE / 2 - 5;

        updatePos();
    }

    override function updatePos() {
        x = ChartEditorState.INSTANCE.nextGridBG.x - ChartEditorState.GRID_SIZE * 1.5 + 2;
        y = (ChartEditorState.Y_OFFSET - ChartEditorState.GRID_SIZE * 1.5 + 2) - ((Conductor.songPosition - ChartEditorState.calcY(strumTime)) * ChartEditorState.GRID_SIZE / Conductor.crochet * 4);
        alpha = strumTime < Conductor.songPosition ? 0.6 : 1;
    }
}