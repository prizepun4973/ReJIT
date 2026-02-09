package funkin.editors.chart.action;

import funkin.editors.chart.ChartEditorState;
import funkin.editors.chart.element.*;
import flixel.FlxG;
import flixel.FlxSprite;

class MoveAction extends EditorAction {
    public var datas:Array<Int> = [];
    public var targets:Array<GuiElement> = [];
    public var removed:Array<Int> = [];
    public var deltaTime:Float;
    public var deltaData:Int = 0;

    public function new(targets:Array<GuiElement>) {
        super();

        this.targets = targets;

        for (i in targets)
            datas.push(i.dataID);

        deltaTime = editor.crosshair.dragTarget.strumTime - editor.crosshair.getMousePos();
        if (Std.isOfType(editor.crosshair.dragTarget, GuiNote)) deltaData = Math.floor((FlxG.mouse.x - editor.gridBG.x) / ChartEditorState.GRID_SIZE) - (cast (editor.crosshair.dragTarget, GuiNote)).noteData;
        trace(deltaData);

        redo();
    }

    override function redo() {
        for (i in datas) {
            var data = ChartEditorState.data[i];
            if (data.get('strumTime') + deltaTime > FlxG.sound.music.length || data.get('strumTime') + deltaTime < 0) {
                remove(i);
                continue;
            }

            data.set('strumTime', data.get('strumTime') + deltaTime);

            if (data.get('events') == null) {
                if (data.get('noteData') + deltaData < 0 || data.get('noteData') > 8) { // TODO: multikey mb
                    remove(i);
                    continue;
                }

                data.set('noteData', data.get('noteData') + deltaData);
            }

            // editor.renderNotes.forEachAlive(function (spr:FlxSprite) {
            //     if (Std.isOfType(spr, GuiNote)) (cast (spr, GuiNote)).updateAnim();
            // });
        }
    }

    override function undo() {
        for (i in datas) {
            var data = ChartEditorState.data[i];
            data.set('strumTime', data.get('strumTime') - deltaTime);

            if (data.get('events') == null)
                data.set('noteData', data.get('noteData') - deltaData);

            if (removed.contains(i)) {
                if (data.get('events') == null)
                    editor.addElement(new GuiNote(
                        false,
                        data.get('strumTime'),
                        data.get('noteData'),
                        data.get('susLength'),
                        data.get('noteType')
                    ));
                else
                    editor.addElement(new GuiEventNote(
                        false,
                        data.get('strumTime'),
                        data.get('events')
                    ));
            }
        }
    }

    function remove(data:Int) {
        removed.push(data);
        editor.removeElementByDataID(data);
    }
}