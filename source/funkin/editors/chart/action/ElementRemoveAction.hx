package funkin.editors.chart.action;

import funkin.editors.chart.ChartEditorState;
import funkin.editors.chart.ChartEditorState.GuiElement;
import funkin.editors.chart.ChartEditorState.EditorAction;
import funkin.editors.chart.ChartEditorState.SelectIndicator;
import funkin.editors.chart.action.NoteAddAction;
import funkin.editors.chart.element.*;
import funkin.game.component.Note.EventNote;
import flixel.FlxG;

typedef ElementRemoveData = {
    var events:Array<EventNote>;
    var strumTime:Float;
    var noteData:Int;
    var susLength:Float;
    var noteType:String;
    var relatedAction:EditorAction;
    var wasSelected:Bool;
}

class ElementRemoveAction extends ChartEditorState.EditorAction {
    public var elements:Array<GuiElement> = new Array();
    public var datas:Array<ElementRemoveData> = new Array();
    public var relatedActions:Array<EditorAction> = new Array();

    public function new(elements:Array<GuiElement>) {
        super();

        for (element in elements) {
            var selected:Bool = false;
            editor.selectIndicator.forEachAlive(function (indicator:SelectIndicator) {
                if (indicator.target == element) selected = true;
            });

            var data:ElementRemoveData = {
                events: [],
                strumTime: 0,
                noteData: 0,
                susLength: 0,
                noteType: "",
                relatedAction: null,
                wasSelected: false
            };
            if (Std.isOfType(element, GuiNote)) {
                var note:GuiNote = cast (element, GuiNote);

                data = {
                    events: null,
                    strumTime: note.strumTime,
                    noteData: note.noteData,
                    susLength: note.susLength,
                    noteType: note.noteType,
                    relatedAction: note.relatedAction,
                    wasSelected: selected
                };

            }
            if (Std.isOfType(element, GuiEventNote)) {
                var event = cast (element, GuiEventNote);

                data = {
                    events: event.events,
                    strumTime: event.strumTime,
                    noteData: 0,
                    susLength: 0,
                    noteType: "",
                    relatedAction: null,
                    wasSelected: selected
                };
            }

            datas.push(data);
            this.elements.push(element);
        }

        redo();
    }

    override function redo() {
        for (element in elements) {
            element.relatedRemove = this;
            relatedActions.push(element.relatedAction);

            editor.selectIndicator.forEachAlive(function (indicator:SelectIndicator) {
                if (indicator.target == element) editor.selectIndicator.remove(indicator);
            });

            if (Std.isOfType(element, GuiNote)) editor.renderNotes.remove((cast (element, GuiNote)).susTail);
            editor.renderNotes.remove(element);
            // note = null;
        }
    }

    override function undo() {
        for (data in datas) {
            // trace(datas);

            if (data.events == null) {
                var note:GuiNote = new GuiNote(data.strumTime, data.noteData, data.susLength, data.relatedAction);
                note.noteType = data.noteType;
                note.relatedRemove = this;
                
                elements.push(note);
                // trace(note);

                if (data.wasSelected) editor.selectIndicator.add(new SelectIndicator(note));
            }
            else {
                var event:GuiEventNote = new GuiEventNote(data.strumTime, data.events);
                event.relatedRemove = this;
                
                elements.push(event);
                // trace(event);

                editor.renderNotes.add(event);
                if (data.wasSelected) editor.selectIndicator.add(new SelectIndicator(event));
            }
        }
    }
}