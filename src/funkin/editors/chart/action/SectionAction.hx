package funkin.editors.chart.action;

import funkin.editors.chart.ChartEditorState;
import funkin.game.data.Section.SwagSection;

class SectionAction extends ChartEditorState.EditorAction {
    var data:SwagSection;
    var dataPre:SwagSection;
    var index:Int;

    public function new(data:SwagSection, index:Int) {
        super();

        dataPre = ChartEditorState._song.notes[index];
        this.data = data;
        this.index = index;

        redo();
    }

    override function redo() {
        ChartEditorState._song.notes[index] = data;
        ChartEditorState.nextUpdateTime = ChartEditorState.lastUpdateTime + Conductor.getCrochetAtTime(Conductor.songPosition) * data.sectionBeats;
    }

    override function undo() {
        ChartEditorState._song.notes[index] = dataPre;
        ChartEditorState.nextUpdateTime = ChartEditorState.lastUpdateTime + Conductor.getCrochetAtTime(Conductor.songPosition) * dataPre.sectionBeats;
    }
}