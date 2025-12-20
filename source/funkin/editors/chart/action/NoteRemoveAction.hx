package funkin.editors.chart.action;

import funkin.editors.chart.ChartEditorState;
import funkin.editors.chart.ChartEditorState.SelectIndicator;
import funkin.editors.chart.action.NoteAddAction;
import funkin.editors.chart.element.GuiNote;
import flixel.FlxG;

typedef NoteRemoveData = {
    var strumTime:Float;
    var noteData:Int;
    var susLength:Float;
    var noteType:String;
    var relatedAction:NoteAddAction;
}

class NoteRemoveAction extends ChartEditorState.EditorAction {
    private var notes:Array<GuiNote> = new Array();
    public var removedNote:Array<NoteRemoveData> = new Array();
    public var relatedActions:Array<NoteAddAction> = new Array();

    public function new(notes:Array<GuiNote>) {
        super();

        for (note in notes) {
            var data:NoteRemoveData = {
                strumTime: note.strumTime,
                noteData: note.noteData,
                susLength: note.susLength,
                noteType: note.noteType,
                relatedAction: note.relatedAction
            };
            removedNote.push(data);

            this.notes.push(note);
        }

        redo();
    }

    override function redo() {
        for (note in notes) {
            relatedActions.push(note.relatedAction);

            ChartEditorState.INSTANCE.selectIndicator.forEachAlive(function (indicator:SelectIndicator) {
                if (indicator.target == note) ChartEditorState.INSTANCE.selectIndicator.remove(indicator);
            });

            ChartEditorState.INSTANCE.renderNotes.remove(note.susTail);
            ChartEditorState.INSTANCE.renderNotes.remove(note);
            // note = null;
        }
    }

    override function undo() {
        for (removed in removedNote) {
            var note:GuiNote = new GuiNote(removed.strumTime, removed.noteData, removed.susLength, removed.relatedAction);
            note.noteType = removed.noteType;
            
            notes.push(note);
            trace(note);

            ChartEditorState.INSTANCE.renderNotes.add(note);
            // ChartEditorState.INSTANCE.selectIndicator.add(new SelectIndicator(note));
        }
    }
}