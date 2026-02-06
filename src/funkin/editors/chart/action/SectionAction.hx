package funkin.editors.chart.action;

import funkin.editors.chart.ChartEditorState;
import funkin.game.data.Section.SwagSection;

class SectionAction extends EditorAction {
    var data:SwagSection;
    var dataPre:SwagSection;
    var index:Int;

    public function new(data:SwagSection, index:Int) {
        super();

        var section:SwagSection = ChartEditorState._song.notes[index];
        dataPre = {
            sectionNotes: [],
            sectionBeats: section.sectionBeats,
            typeOfSection: section.typeOfSection,
            mustHitSection: section.mustHitSection,
            gfSection: section.gfSection,
            bpm: section.bpm,
            changeBPM: section.changeBPM,
            altAnim: section.altAnim
        };
        this.data = data;
        this.index = index;

        redo();
    }

    override function redo() {
        ChartEditorState._song.notes[index] = data;
        editor.updateBPM();
        ChartEditorState.nextUpdateTime = ChartEditorState.lastUpdateTime + Conductor.getCrochetAtTime(Conductor.songPosition) * data.sectionBeats;
    }

    override function undo() {
        ChartEditorState._song.notes[index] = dataPre;
        editor.updateBPM();
        ChartEditorState.nextUpdateTime = ChartEditorState.lastUpdateTime + Conductor.getCrochetAtTime(Conductor.songPosition) * dataPre.sectionBeats;
    }
}