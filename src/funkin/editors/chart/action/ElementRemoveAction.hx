package funkin.editors.chart.action;

import funkin.editors.chart.ChartEditorState;
import funkin.editors.chart.element.GuiElement;
import funkin.editors.chart.handle.SelectIndicator;
import funkin.editors.chart.element.*;
import funkin.game.component.Note.EventNote;
import flixel.FlxG;
import flixel.FlxSprite;

class ElementRemoveAction extends EditorAction {
    public var elements:Array<GuiElement> = new Array();
    public var datas:Array<Int> = new Array();

    public function new(elements:Array<GuiElement>) {
        super();

        for (i in elements) datas.push(i.dataID);

        redo();
    }

    override function redo() {
        for (i in datas) {
            editor.renderNotes.forEach(function (spr:FlxSprite) {
                if (Std.isOfType(spr, GuiElement)) {
                    var element:GuiElement = cast (spr, GuiElement);
                    if (datas.contains(element.dataID)) {
                        if (Std.isOfType(spr, GuiNote)) {
                            var note = cast (spr, GuiNote);
                            editor.renderNotes.remove(note.susTail);
                        }
                        editor.removeElement(element);
                    }
                }
            });
        }
    }

    override function undo() {
        for (i in datas) {
            var data = ChartEditorState.data[i];
            if (ChartEditorState.data[i].exists('noteData')) {
                var note:GuiNote = new GuiNote(false, data.get('strumTime'), data.get('noteData'), data.get('susLength'));
                note.noteType = data.get('noteType');
                note.dataID = i;
                editor.addElement(note);
            } else {
                var event:GuiEventNote = new GuiEventNote(false, data.get('strumTime'), []);
                event.events = data.get('events');
                event.dataID = i;
                editor.addElement(event);
            }
        }
    }
}