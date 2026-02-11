package funkin.editors.chart.element;

import funkin.editors.chart.ChartEditorState;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.text.FlxText;

class GuiNote extends GuiElement{
    public var noteData:Int = 0;
    public var susLength:Float = 0;
    public var noteType:String = "";
    
    public var susTail:FlxSprite;
    public var typeTxt:FlxText;

    var playHitsound:Bool = false;

    public function new(pushData:Bool, strumTime:Float, noteData:Int, susLength:Float, noteType:String = '') {
        super(strumTime);

        var parent = ChartEditorState.INSTANCE.renderNotes;

        if (pushData) {
            ChartEditorState.data.push([
                'strumTime' => strumTime,
                'noteData' => noteData,
                'susLength' => susLength,
                'noteType' => noteType,
            ]);

            this.dataID = ChartEditorState.data.length - 1;
        }

        loadGraphic(Paths.image("NOTE_assets", 'preload'));
        frames = Paths.getSparrowAtlas("NOTE_assets", 'preload');
        setGraphicSize(ChartEditorState.GRID_SIZE, ChartEditorState.GRID_SIZE);
        centerOffsets();
        centerOrigin();
        
		susTail = new FlxSprite(0, 0).makeGraphic(8, 1);

        animation.addByPrefix("0", "purple0");
        animation.addByPrefix("1", "blue0");
        animation.addByPrefix("2", "green0");
        animation.addByPrefix("3", "red0");
        animation.addByPrefix("4", "purple0");
        animation.addByPrefix("5", "blue0");
        animation.addByPrefix("6", "green0");
        animation.addByPrefix("7", "red0");

        parent.add(susTail);

        parent.add(this);
        
        typeTxt = new FlxText(0, 0, 60, '', 12);
        typeTxt.setFormat(Paths.font("vcr.ttf"), 16, 0xFFE0E0E0, CENTER, FlxTextBorderStyle.OUTLINE, flixel.util.FlxColor.BLACK);
        parent.add(typeTxt);

        updatePos();
    }

    override function updatePos() {        
        var crochet:Float = (60 / Conductor.getBPMFromSeconds(Conductor.songPosition).bpm) * 1000;

        updateField('noteData');
        updateField('susLength');
        updateField('noteType');

        animation.play(Std.string(noteData));

        switch (noteData) {
            case 0 | 4 :
                susTail.color = 0xdda0dd;
            case 1 | 5 :
                susTail.color = 0x00ffff;
            case 2 | 6 :
                susTail.color = 0x5CE65C;
            case 3 | 7 :
                susTail.color = 0xED2939;
        }

        x =  ChartEditorState.INSTANCE.nextGridBG.x - ChartEditorState.GRID_SIZE * 2.5 + (noteData + 1) * ChartEditorState.GRID_SIZE + 2;
        y = (ChartEditorState.Y_OFFSET - ChartEditorState.GRID_SIZE * 1.5) - ((Conductor.songPosition - ChartEditorState.calcY(strumTime)) / crochet * 4 * ChartEditorState.GRID_SIZE);
        alpha = strumTime < Conductor.songPosition ? 0.6 : 1;

        crochet = (60 / Conductor.getBPMFromSeconds(strumTime).bpm) * 1000;

        susTail.x = x + (ChartEditorState.GRID_SIZE * 2) - 6;
        susTail.y = y + ChartEditorState.GRID_SIZE * 2.25 + (ChartEditorState.GRID_SIZE * (susLength / crochet * 2));
        susTail.visible = susLength > 0;
        susTail.alpha = alpha;
        susTail.setGraphicSize(susTail.width, ChartEditorState.GRID_SIZE * (susLength / crochet * 4 + 0.5)); // TODO: Fix this

        typeTxt.text = noteType;
        typeTxt.x = x + ChartEditorState.GRID_SIZE * 1.5 - 10;
        typeTxt.y = y + ChartEditorState.GRID_SIZE * 1.5 - 5;

        if (Conductor.songPosition <= strumTime) playHitsound = true;
        else if ((ChartEditorState.hitsoundP1 && noteData > 3) || (ChartEditorState.hitsoundP2 && noteData < 4)) {
            if (editor.paused) playHitsound = false;

            if (playHitsound) {
                playHitsound = false;
                FlxG.sound.play(Paths.sound('hitSound'), 0.25);
            }
        }
    }

    override function destroy() {
        super.destroy();
        editor.renderNotes.remove(susTail);
    }
}