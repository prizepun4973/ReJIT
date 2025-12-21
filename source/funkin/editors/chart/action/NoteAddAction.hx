package funkin.editors.chart.action;

import funkin.editors.chart.ChartEditorState;
import funkin.editors.chart.action.*;
import funkin.editors.chart.element.GuiNote;
import flixel.FlxG;

class NoteAddAction extends ChartEditorState.EditorAction {
    public var _note:GuiNote;

    public var strumTime:Float;
    public var noteData:Int;
    public var wasSelected:Bool = false;

    public var relatedRemove:ElementRemoveAction;

    public function new(strumTime, noteData) {
        super();

        ChartEditorState.INSTANCE.selectIndicator.forEachAlive(function (indicator:SelectIndicator) {
            if (indicator.target == _note) wasSelected = true;
        });

        this.strumTime = strumTime;
        this.noteData = noteData;

        redo();
    }

    override function redo() {
        _note = new GuiNote(strumTime, noteData, 0, this);
        if (relatedRemove != null) relatedRemove.elements.push(_note);
        editor.addElement(_note);
    }

    override function undo() {
        if (_note.relatedRemove != null) relatedRemove = cast (_note.relatedRemove, funkin.editors.chart.action.ElementRemoveAction);
        editor.renderNotes.remove(_note.susTail);
        editor.removeElement(_note);
    }
}