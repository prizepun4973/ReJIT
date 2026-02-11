package funkin.editors.chart.element;

import funkin.editors.chart.ChartEditorState;
import funkin.game.component.Note.EventNote;
import flixel.text.FlxText;

class GuiEventNote extends GuiElement {
    public var events:Array<Array<String>>;
    public var displayText:FlxText;

    public function new(dataID:Int = null, strumTime:Float, events:Array<Array<String>>) {
        super(strumTime);

        var parent = ChartEditorState.INSTANCE.renderNotes;

        if (dataID == null) {
            ChartEditorState.data.push([
                'strumTime' => strumTime,
                'events' => events,
            ]);

            this.dataID = ChartEditorState.data.length - 1;
        }
        else this.dataID = dataID;

        this.events = events;
        
        // loadGraphic(Paths.image("eventArrow"));
        // setGraphicSize(ChartEditorState.GRID_SIZE, ChartEditorState.GRID_SIZE);
        // centerOffsets();
        // centerOrigin();

        // offset.x -= ChartEditorState.GRID_SIZE / 2 - 5;
        // offset.y -= ChartEditorState.GRID_SIZE / 2 - 5;

        displayText = new FlxText(0, 0, 400, '', 12);
        displayText.wordWrap = false;
        displayText.autoSize = true;
        displayText.setFormat(Paths.font("vcr.ttf"), 12, 0xFFE0E0E0, LEFT);
        parent.add(displayText);

        makeGraphic(ChartEditorState.GRID_SIZE, 4);
        offset.x -= ChartEditorState.GRID_SIZE * 1.5 - 2;
        offset.y -= ChartEditorState.GRID_SIZE * 1.5;

        updatePos();
    }

    override function updatePos() {
        updateField('events');

        x = ChartEditorState.INSTANCE.nextGridBG.x - ChartEditorState.GRID_SIZE * 2.5 + 2;
        y = (ChartEditorState.Y_OFFSET - ChartEditorState.GRID_SIZE * 1.5) - ((Conductor.songPosition - ChartEditorState.calcY(strumTime)) * ChartEditorState.GRID_SIZE / Conductor.crochet * 4);

        var result = '';
        for (i in 0...events.length) {
            result += events[i][0] + (i >= events.length - 1? "" : ", ");
        }

        displayText.text = result;
        displayText.x = x - displayText.width - 10 + ChartEditorState.GRID_SIZE * 1.5;
        displayText.y = y - 5 + ChartEditorState.GRID_SIZE * 1.5;

        alpha = strumTime < Conductor.songPosition ? 0.6 : 1;
    }

    override function destroy() {
        super.destroy();
        editor.renderNotes.remove(displayText);
    }
}