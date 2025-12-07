package funkin.editors.chart;

import flixel.text.FlxText;
import funkin.jit.BuiltinJITState;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextAlign;
import flixel.addons.display.FlxGridOverlay;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import Song.SwagSong;
import funkin.component.MusicBeatState;
import funkin.game.component.Note.EventNote;
import funkin.game.data.StageData;
import funkin.game.data.Section.SwagSection;

import openfl.display.BlendMode;

import openfl.utils.Assets as OpenFlAssets;
import flash.media.Sound;

#if sys
import sys.FileSystem;
#end

import Conductor.BPMChangeEvent;

import funkin.editors.chart.element.*;
import funkin.editors.chart.action.*;

class ChartEditorState extends BuiltinJITState {
    public static var GRID_SIZE:Int = 40;
    public static var Y_OFFSET:Int = 360;
    public static var hitboxScale:Float = 40;
    public static var INSTANCE:ChartEditorState;

    public static var lastPos:Float = 0;
    public static var curSec:Int = 0;
    public static var lastUpdateTime:Float;
    public static var nextUpdateTime:Float;
    
    public var paused:Bool = true;
    public static var timeline:Array<EditorAction> = new Array();

    public var beatSnap:Int = 32;

    // data
    public var _song:SwagSong;
    private var sectionBPM:Array<Float> = new Array();

    // audio
    private var vocals:FlxSound = null;

    // graphics
    public var renderNotes:FlxTypedGroup<FlxSprite> = new FlxTypedGroup();
    private var gridGroup:FlxTypedGroup<FlxSprite> = new FlxTypedGroup();
    public var gridBG:FlxSprite;
    public var nextGridBG:FlxSprite;
    private var eventSplitLine:FlxSprite;
    private var sideSplitLine:FlxSprite;
    private var conductorLine:FlxSprite;

    private var textPanel:FlxText;
    public var crosshair:Crosshair;
    
    public static function reset() {
        lastPos = 0;
        lastUpdateTime = 0;
        nextUpdateTime = 0;
        curSec = 0;
        timeline = new Array<EditorAction>();
    }
    
    public static function getMousePos() {
        var strumTime:Float = Conductor.songPosition + (FlxG.mouse.y - Y_OFFSET) / (GRID_SIZE / Conductor.crochet * 4);
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

    public static function calcY(strumTime:Float = 0) {
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
        
        return map.songTime + ((strumTime - map.songTime) / crochet * Conductor.crochet);
    }

    function pause() {
        if (paused) { // resume
            FlxG.sound.music.time = Conductor.songPosition;
            if (vocals != null) {
                vocals.time = FlxG.sound.music.time;
                vocals.resume();
            }
            FlxG.sound.music.resume();
        }
        else { // pause
            FlxG.sound.music.pause();
            if (vocals != null) vocals.pause();
        }
        paused = !paused;
    }
    
    public function updateCurSec() {
        var songPos:Float = Conductor.songPosition;

        if (curSec < 0 || Conductor.songPosition < 0) {
            curSec = 0;
            Conductor.changeBPM(sectionBPM[0]);
            lastUpdateTime = 0;
            nextUpdateTime = _song.notes[curSec].sectionBeats * Conductor.crochet;

            gridBG.setGraphicSize(gridBG.width, GRID_SIZE * _song.notes[curSec].sectionBeats * 4);
            conductorLine.color = sectionBPM[curSec] == sectionBPM[curSec + 1] ? FlxColor.WHITE : FlxColor.YELLOW;

            songPos = 0;
            if (!paused) pause();
        }
        if (songPos > nextUpdateTime) {
            curSec++;
            Conductor.changeBPM(sectionBPM[curSec]);
            
            lastUpdateTime = nextUpdateTime;
            nextUpdateTime += _song.notes[curSec].sectionBeats * Conductor.crochet;

            gridBG.setGraphicSize(gridBG.width, GRID_SIZE * _song.notes[curSec].sectionBeats * 4);
        }
        if (songPos < lastUpdateTime) {
            curSec--;
            Conductor.changeBPM(sectionBPM[curSec]);

            nextUpdateTime = lastUpdateTime;
            lastUpdateTime -= _song.notes[curSec].sectionBeats * Conductor.crochet;

            gridBG.setGraphicSize(gridBG.width, GRID_SIZE * _song.notes[curSec].sectionBeats * 4);
        }
    }

    function saveChanges() {
        _song.events = new Array();

        for (section in _song.notes) {
            section.sectionNotes = new Array<Dynamic>();
        }

        renderNotes.forEachAlive(function (i:FlxSprite) {
            if (Std.isOfType(i, GuiNote)) {
                var note:GuiNote = (cast (i, GuiNote));

                var targetSection:Int = 0;
                var endTime:Float = 0;
                while (endTime < note.strumTime) {
                    targetSection++;
                    endTime += _song.notes[targetSection].sectionBeats * (60 / sectionBPM[curSec]) * 1000;
                }

                var noteArray:Array<Dynamic> = new Array();
                noteArray.push(note.strumTime);
                noteArray.push(Std.int(_song.notes[targetSection].mustHitSection ? (note.noteData < 4 ? note.noteData + 4 : note.noteData - 4) : note.noteData));
                noteArray.push(note.susLength);
                if (note.noteType != '') noteArray.push(note.noteType);

                _song.notes[targetSection].sectionNotes.push(noteArray);
            }

            if (Std.isOfType(i, GuiEventNote)) {
                var event:GuiEventNote = (cast (i, GuiEventNote));

                var eventArray:Array<Dynamic> = new Array();
                eventArray.push(event.strumTime);
                eventArray.push(event.events);

                _song.events.push(eventArray);
            }
        });

        PlayState.SONG = _song;
    }

    public function new() {
        super("ChartEditorState");
        INSTANCE = this;
    }
    
    override function destroy() {
        super.destroy();
        lastPos = Conductor.songPosition;
    }

    override function create() {
        super.create();

        FlxG.mouse.visible = true;
        Conductor.songPosition = lastPos;

        /*
            load
        */
        if (PlayState.SONG != null) _song = PlayState.SONG;
		else {
			CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
			_song = {
				song: 'Test',
				notes: [],
				events: [],
				bpm: 150.0,
				needsVoices: true,
				arrowSkin: '',
				splashSkin: 'noteSplashes',
				player1: 'bf',
				player2: 'dad',
				gfVersion: 'gf',
				speed: 1,
				stage: 'stage',
				validScore: false
			};
			PlayState.SONG = _song;
		}
        Conductor.mapBPMChanges(_song);
		Conductor.changeBPM(_song.bpm);

        var lastBPM:Float = _song.bpm;
        for (section in _song.notes) {
            if (!Std.isOfType(section.sectionBeats, Float) || section.sectionBeats < 1) section.sectionBeats = 4;

            if (section.changeBPM) lastBPM = section.bpm;
            sectionBPM.push(lastBPM);
        }


        /*
            audio
        */
        FlxG.sound.playMusic(Paths.inst(_song.song));
        FlxG.sound.music.pause();

        vocals = new FlxSound();
		if (FileSystem.exists('assets/songs/${Paths.formatToSongPath(_song.song)}/Voices.ogg') || FileSystem.exists('${Paths.modFolders("songs/")}${Paths.formatToSongPath(_song.song)}/Voices.ogg')){
			var file:Dynamic = Paths.voices(_song.song);
			if (Std.isOfType(file, Sound) || OpenFlAssets.exists(file)) {
				vocals.loadEmbedded(file);
				FlxG.sound.list.add(vocals);
			}
		}
        vocals.play();
        vocals.pause();

        FlxG.sound.music.onComplete = function () {
			if(vocals != null) {
                vocals.play();
                vocals.pause();
			}
            curSec = -1;
		};


        /*
            graphics
        */
        add(gridGroup);

        nextGridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 9, GRID_SIZE * 50);
        nextGridBG.alpha = 0.8;
        nextGridBG.screenCenter(X);
        nextGridBG.x -= GRID_SIZE / 2;
        nextGridBG.y = Y_OFFSET;
        gridGroup.add(nextGridBG);

        gridBG = new FlxSprite().makeGraphic(GRID_SIZE * 9, GRID_SIZE * 16, FlxColor.WHITE);
        gridBG.screenCenter(X);
        gridBG.alpha = 0.2;
        gridBG.x -= GRID_SIZE / 2;
        gridGroup.add(gridBG);

        sideSplitLine = new FlxSprite(nextGridBG.x + GRID_SIZE * 5, 0).makeGraphic(2, Std.int(nextGridBG.height), FlxColor.BLACK);
        gridGroup.add(sideSplitLine);
        eventSplitLine = new FlxSprite(nextGridBG.x + GRID_SIZE, 0).makeGraphic(2, Std.int(nextGridBG.height), FlxColor.BLACK);
        gridGroup.add(eventSplitLine);

        add(renderNotes);

        for (section in _song.notes) {
            for (note in section.sectionNotes) {
                var guiNote:GuiNote = new GuiNote(note[0], Std.int(section.mustHitSection ? (note[1] < 4 ? note[1] + 4 : note[1] - 4) : note[1]), note[2]);
                if (note.length > 3) if (Std.isOfType(note[3], String)) guiNote.noteType = note[3];
            }
        }

        for (event in _song.events) {
            var guiEventNote:GuiEventNote = new GuiEventNote(event[0], event[1]);
            renderNotes.add(guiEventNote);
        }

        if (curSec == 0) {
            lastUpdateTime = 0;
            nextUpdateTime = _song.notes[curSec].sectionBeats * Conductor.crochet;
        }

        textPanel = new FlxText(2, FlxG.height - 48, 400, "hi", 12);
        textPanel.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, FlxTextAlign.LEFT);
        add(textPanel);

        conductorLine = new FlxSprite(0, Y_OFFSET).makeGraphic(GRID_SIZE * 13, 4, FlxColor.WHITE);
        conductorLine.screenCenter(X);
        conductorLine.x -= GRID_SIZE / 2;
        add(conductorLine);

        crosshair = new Crosshair();
        add(crosshair);

        updateCurSec();
    }

    override function update(elapsed:Float) {
        super.update(elapsed);
        call("onUpdate", [elapsed]);
        var songPos:Float = Conductor.songPosition;

        /*
            System
        */
        if (Conductor.songPosition < 0) Conductor.songPosition = 0;
        if (Conductor.songPosition > FlxG.sound.music.length) Conductor.songPosition = FlxG.sound.music.length;
        if (!paused) Conductor.songPosition = FlxG.sound.music.time;

        if (renderNotes.members.length <= 0) updateCurSec();


        /*
            handle graphic
        */
        nextGridBG.y = Y_OFFSET - (songPos - lastUpdateTime + Conductor.crochet * 2) * GRID_SIZE / Conductor.crochet * 4 - GRID_SIZE * 5;
        gridBG.y = Y_OFFSET - (songPos - lastUpdateTime) * GRID_SIZE / Conductor.crochet * 4;

        textPanel.text = 
            Std.string(FlxMath.roundDecimal(Conductor.songPosition / 1000, 2)) + " / " + Std.string(FlxMath.roundDecimal(FlxG.sound.music.length / 1000, 2)) +
		    "\nSection: " + curSec + " (Beats: " + _song.notes[curSec].sectionBeats + ", BPM: " + sectionBPM[curSec] + ")" + 
            "\nchart editor is wip, plz press debugkey1";


        /*
            handle inputs
        */
        if (FlxG.keys.justPressed.ENTER) {
            if (!paused) pause();
            saveChanges();
            FlxG.mouse.visible = false;
            StageData.loadDirectory(_song);
            LoadingState.loadAndSwitchState(new PlayState());
        }
        if (((FlxG.mouse.wheel > 0 && Conductor.songPosition > 0) || (FlxG.mouse.wheel < 0 && Conductor.songPosition < FlxG.sound.music.length)) && paused)
            Conductor.songPosition -= Conductor.crochet / 4 * FlxG.mouse.wheel;

        if (FlxG.keys.justPressed.SPACE) pause();

        if (FlxG.mouse.justPressed) {
            trace(getMousePos() + " " + crosshair.target);

            if (Std.isOfType(crosshair.target, GuiNote)) {
                timeline.push(new NoteRemoveAction(cast (crosshair.target, GuiNote)));
            }

            if (crosshair.target == null
            && FlxG.mouse.x >= gridBG.x + GRID_SIZE && FlxG.mouse.x < gridBG.x + gridBG.width
            && ChartEditorState.getMousePos() >= 0 && ChartEditorState.getMousePos() <= FlxG.sound.music.length) {
                timeline.push(new NoteAddAction(crosshair.chained? crosshair.chainedMousePos : ChartEditorState.getMousePos(), Math.floor((FlxG.mouse.x - gridBG.x - GRID_SIZE) / GRID_SIZE)));
            }
        }

        if (FlxG.keys.anyJustPressed(ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1')))) {
            funkin.component.MusicBeatState.switchState(new funkin.editors.ChartingState());
        }
    }
}

class Crosshair extends FlxSprite {
    public var target:GuiElement;
    public var chained:Bool = true;
    public var chainedMousePos:Float;

    public function new() {
        super(0, 0);
        makeGraphic(ChartEditorState.GRID_SIZE, ChartEditorState.GRID_SIZE);
        alpha = 0.5;
    }

    override function update(elapsed:Float) {
        super.update(elapsed);
        var editor:ChartEditorState = ChartEditorState.INSTANCE;

        var mouseStrumTime:Float = ChartEditorState.getMousePos();
        var GRID_SIZE = ChartEditorState.GRID_SIZE;

        chainedMousePos = Conductor.getBPMFromSeconds(mouseStrumTime).songTime + Math.floor((mouseStrumTime - Conductor.getBPMFromSeconds(mouseStrumTime).songTime) / Conductor.getCrochetAtTime(mouseStrumTime) / 4 * editor.beatSnap) * Conductor.getCrochetAtTime(mouseStrumTime) * 4 / editor.beatSnap;
        x = editor.gridBG.x + Math.floor((FlxG.mouse.x - editor.gridBG.x) / GRID_SIZE) * GRID_SIZE;
        y = chained? ChartEditorState.Y_OFFSET - (Conductor.songPosition - ChartEditorState.calcY(chainedMousePos)) * GRID_SIZE / Conductor.crochet * 4
         : FlxG.mouse.y - height / 2;
        visible = FlxG.mouse.x >= editor.gridBG.x && FlxG.mouse.x < editor.gridBG.x + editor.gridBG.width
            && mouseStrumTime >= 0 && mouseStrumTime <= FlxG.sound.music.length;

        var anyHovered = false;
        editor.renderNotes.forEachAlive(function (sprite:FlxSprite) {
            if (Std.isOfType(sprite, GuiElement)) {
                var element:GuiElement = cast (sprite, GuiElement);
                var x1:Float = element.x + GRID_SIZE * 1.5 - 2;
                var y1:Float = element.y + sprite.height / 2 - ChartEditorState.hitboxScale / 2;
                var x2:Float = x1 + GRID_SIZE;
                var y2:Float = y1 + ChartEditorState.hitboxScale;

                if (FlxG.mouse.x >= x1 && FlxG.mouse.x <= x2 && FlxG.mouse.y >= y1 && FlxG.mouse.y <= y2 && !anyHovered) {
                    target = element;
                    anyHovered = true;
                }
                else if (!anyHovered) target = null;
            }
            else if (!anyHovered) target = null;
        });
    }
}

class GuiElement extends FlxSprite {
    public var strumTime:Float = 0;
    public var hitboxScale:Float = ChartEditorState.hitboxScale;

    public function new(X:Float = 0, Y:Float = 0) {
        super(X, Y);
    }

    override function update(elapsed:Float) {
        ChartEditorState.INSTANCE.updateCurSec();
        super.update(elapsed);
    }
}

abstract class EditorAction {
    public function new() {}
    public function redo() {}
    public function undo() {}
}