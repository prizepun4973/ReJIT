package funkin.editors.chart.action;

import funkin.editors.chart.ChartEditorState;
import funkin.editors.chart.ChartEditorState.GuiElement;
import funkin.editors.chart.ChartEditorState.EditorAction;
import funkin.editors.chart.ChartEditorState.SelectIndicator;
import funkin.editors.chart.element.*;
import funkin.game.component.Note.EventNote;
import flixel.FlxG;
import flixel.FlxSprite;

class ElementAddAction extends ChartEditorState.EditorAction {
    public var datas:Array<Int> = [];
    public var elements:Array<GuiElement> = [];

    public function new(elements:Array<GuiElement>) {
        super();

        this.elements = elements;

        redo();
    }

    override function redo() {
        if (datas.length > 0) {
            for (i in datas) {
                var data = ChartEditorState.data[i];
                // trace(data);
                if (ChartEditorState.data[i].exists('noteData')) {
                    var note:GuiNote = new GuiNote(false, data.get('strumTime'), data.get('noteData'), data.get('susLength'));
                    note.noteType = data.get('noteType');
                    note.dataID = i;
                    editor.addElement(note);
                } else {
                    var event:GuiEventNote = new GuiEventNote(false, data.get('strumTime'), data.get('events'));
                    event.events = data.get('events');
                    event.dataID = i;
                    editor.addElement(event);
                }
            }
        }
        else {
            for (i in elements) {
                datas.push(i.dataID);
                editor.addElement(i);
            }
        }
    }

    override function undo() {
        // trace(datas);
        // trace(ChartEditorState.data);
        for (i in datas) {
            editor.renderNotes.forEach(function (spr:FlxSprite) {
                if (Std.isOfType(spr, GuiElement)) {
                    var element:GuiElement = cast (spr, GuiElement);
                    if (element.dataID == i) editor.removeElement(element);
                }
            });
        }
    }
}