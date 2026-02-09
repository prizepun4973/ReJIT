package funkin.editors.chart.action;

import funkin.editors.chart.ChartEditorState;
import funkin.editors.chart.element.GuiElement;
import funkin.editors.chart.handle.SelectIndicator;
import funkin.editors.chart.element.*;
import funkin.game.component.Note.EventNote;
import flixel.FlxG;
import flixel.FlxSprite;

class ElementAddAction extends EditorAction {
    public var datas:Array<Int> = [];
    public var elements:Array<GuiElement> = [];

    public function new(elements:Array<GuiElement>) {
        super();

        this.elements = elements;

        redo();
    }

    override function redo() {
        var nextTarget:GuiElement = null;

        if (datas.length > 0) {
            for (i in datas) {
                var data = ChartEditorState.data[i];
                // trace(data);
                if (ChartEditorState.data[i].exists('noteData')) {
                    var note:GuiNote = new GuiNote(false, data.get('strumTime'), data.get('noteData'), data.get('susLength'));
                    note.noteType = data.get('noteType');
                    note.dataID = i;
                    editor.addElement(note);
                    if (nextTarget == null) nextTarget = note;
                } else {
                    var event:GuiEventNote = new GuiEventNote(false, data.get('strumTime'), []);
                    event.events = data.get('events');
                    event.dataID = i;
                    editor.addElement(event);
                    if (nextTarget == null) nextTarget = event;
                }
            }
        }
        else {
            for (i in elements) {
                datas.push(i.dataID);
                if (nextTarget == null) {
                    nextTarget = i;
                    ChartEditorState.data[i.dataID].set('wasSelected', true);
                }
                editor.addElement(i);
            }
        }

        editor.selectIndicator.forEachAlive(function (indicator:SelectIndicator) {
            if (indicator.target == editor.crosshair.lastTarget) {
                editor.selectIndicator.remove(indicator);
                ChartEditorState.data[indicator.target.dataID].set('wasSelected', false);
            }
        });

        editor.crosshair.lastTarget = nextTarget;
    }

    override function undo() {
        // trace(datas);
        // trace(ChartEditorState.data);
        for (i in datas) {
            editor.renderNotes.forEach(function (spr:FlxSprite) {
                if (Std.isOfType(spr, GuiElement)) {
                    var element:GuiElement = cast (spr, GuiElement);
                    if (element.dataID == i) {
                        if (Std.isOfType(spr, GuiNote)) {
                            var note:GuiNote = (cast (spr, GuiNote));
                            editor.renderNotes.remove(note.susTail);
                        } 
                        editor.removeElement(element);
                    }
                }
            });
        }
    }
}