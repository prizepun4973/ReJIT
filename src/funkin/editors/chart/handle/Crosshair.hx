package funkin.editors.chart.handle;

import flixel.FlxG;
import flixel.FlxSprite;
import funkin.editors.chart.ChartEditorState;
import Conductor.BPMChangeEvent;
import funkin.editors.chart.element.GuiElement;

class Crosshair extends FlxSprite {
    public var target:GuiElement;
    public var chained:Bool = true;

    public var dragTarget:GuiElement;
    

    public var offsetX:Float;
    public var offsetY:Float;

    public var onDragFinished:Void -> Void = function () {};

    public function new() {
        super(0, 0);
        makeGraphic(ChartEditorState.GRID_SIZE, ChartEditorState.GRID_SIZE, 0xffAAAAAA);
        alpha = 0.5;
    }

    function updatePos() {
        var editor:ChartEditorState = ChartEditorState.INSTANCE;

        var mouseStrumTime:Float = getMousePos();
        var GRID_SIZE = ChartEditorState.GRID_SIZE;

        x = editor.gridBG.x + CoolUtil.snap((FlxG.mouse.x - editor.gridBG.x), GRID_SIZE);
        y = ChartEditorState.Y_OFFSET - (Conductor.songPosition - ChartEditorState.calcY(getMousePos())) * GRID_SIZE / Conductor.crochet * 4;
        visible = 
            FlxG.mouse.x >= editor.gridBG.x - ChartEditorState.GRID_SIZE && 
            FlxG.mouse.x < editor.gridBG.x + editor.gridBG.width && 
            mouseStrumTime >= 0 && 
            mouseStrumTime <= FlxG.sound.music.length && 
            ChartEditorState.INSTANCE.canInput();
    }

    function updateTarget() {
        var editor:ChartEditorState = ChartEditorState.INSTANCE;
        var mouseStrumTime:Float = getMousePos();
        var GRID_SIZE = ChartEditorState.GRID_SIZE;

        var anyHovered = false;
        editor.renderNotes.forEachAlive(function (sprite:FlxSprite) {
            if (Std.isOfType(sprite, GuiElement)) {
                var hitboxScale = 16 / ChartEditorState.beatSnap * ChartEditorState.GRID_SIZE;
                var element:GuiElement = cast (sprite, GuiElement);
                var x1:Float = element.x + GRID_SIZE * 1.5 - 2;
                var y1:Float = element.y + GRID_SIZE * 1.5;
                var x2:Float = x1 + GRID_SIZE;
                var y2:Float = y1 + hitboxScale;

                if (FlxG.mouse.x >= x1 && FlxG.mouse.x <= x2 && FlxG.mouse.y >= y1 && FlxG.mouse.y <= y2 && !anyHovered) {
                    target = element;
                    anyHovered = true;
                }
                else if (!anyHovered) target = null;
            }
            else if (!anyHovered) target = null;
        });
    }

    function updateDragTarget() {
        var editor:ChartEditorState = ChartEditorState.INSTANCE;

        if (FlxG.mouse.justPressed && !FlxG.keys.pressed.CONTROL)
            dragTarget = target;
        
        if (FlxG.mouse.justReleased || FlxG.keys.justReleased.SHIFT) {
            onDragFinished();
            dragTarget = null;

            offsetX = 0;
            offsetY = 0;
        }

        if (dragTarget != null && visible && x > editor.gridBG.x - ChartEditorState.GRID_SIZE && FlxG.keys.pressed.SHIFT) {
            offsetX = dragTarget.x - x + ChartEditorState.GRID_SIZE * 1.5 - 2;
            offsetY = dragTarget.y - y + ChartEditorState.GRID_SIZE * 1.5;
        }
    }

    override function update(elapsed:Float) {
        super.update(elapsed);
        updatePos();
        updateTarget();
        updateDragTarget();
    }

    public function getRawMousePos() {
        var strumTime:Float = Conductor.songPosition + (FlxG.mouse.y - ChartEditorState.Y_OFFSET) / (ChartEditorState.GRID_SIZE / Conductor.crochet * 4);
        var map:BPMChangeEvent;
        var crochet:Float;
        if (Conductor.songPosition <= strumTime) {
            map = Conductor.getBPMFromSeconds(strumTime);
            crochet = (60 / map.bpm) * 1000;
        }
        else {
            map = Conductor.getBPMFromSeconds(Conductor.songPosition);
            crochet = (60 / Conductor.getBPMFromSeconds(strumTime).bpm) * 1000;
        }
        
        return map.songTime + ((strumTime - map.songTime) * crochet / Conductor.crochet);
    }

    public function getMousePos() {
        return chained?
            Conductor.getBPMFromSeconds(getRawMousePos()).songTime + CoolUtil.snap(getRawMousePos() - Conductor.getBPMFromSeconds(getRawMousePos()).songTime, Conductor.getCrochetAtTime(getRawMousePos()) * 4 / ChartEditorState.beatSnap)
            :
            getRawMousePos()
        ;
    }
}