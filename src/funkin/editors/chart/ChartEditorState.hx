package funkin.editors.chart;

import flixel.text.FlxText;
import funkin.jit.InjectedState;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextAlign;
import flixel.addons.display.FlxGridOverlay;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxStringUtil;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import funkin.game.data.Song.SwagSong;
import funkin.component.MusicBeatState;
import funkin.game.component.Note.EventNote;
import funkin.game.data.StageData;
import funkin.game.data.Section;
import funkin.game.data.Section.SwagSection;

import haxe.ui.core.Component;

import haxe.Json;

import openfl.display.BlendMode;

import openfl.utils.Assets as OpenFlAssets;
import flash.media.Sound;

import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;

#if sys
import sys.FileSystem;
#end

import Conductor.BPMChangeEvent;

import funkin.editors.chart.handle.*;
import funkin.editors.chart.element.*;
import funkin.editors.chart.action.*;
import funkin.editors.chart.window.*;
import funkin.ui.widget.*;
import funkin.ui.*;

using StringTools;

class ChartEditorState extends UIState {
    public static var GRID_SIZE:Int = 40;
    public static var Y_OFFSET:Int = 360;
    public static var INSTANCE:ChartEditorState;
    
    public static var undos:Array<EditorAction> = [];
    public static var redos:Array<EditorAction> = [];
    public static var data:Array<Map<String, Dynamic>> = [];

    public static var clipBoard:Array<Int> = [];

    public var paused:Bool = true;
    public static var beatSnap:Int;

    // data
    public static var _song:SwagSong;
    public var sectionBPM:Array<Float> = [];

    var _file:FileReference;

    // audio
    private var vocals:FlxSound = null;

    // graphics
    public static var bottomHeight:Int = 20;

    public static var lastPos:Float;
    public static var curSec:Int;
    public static var lastUpdateTime:Float;
    public static var nextUpdateTime:Float;

    public var renderNotes:FlxTypedGroup<FlxSprite> = new FlxTypedGroup();
    private var gridGroup:FlxTypedGroup<FlxSprite> = new FlxTypedGroup();
    public var selectIndicator:FlxTypedGroup<SelectIndicator> = new FlxTypedGroup();

    public var gridBG:FlxSprite;
    public var nextGridBG:FlxSprite;
    private var eventSplitLine:FlxSprite;
    private var sideSplitLine:FlxSprite;
    private var conductorLine:FlxSprite;
    private var sectionStartLine:FlxSprite;
    private var sectionStopLine:FlxSprite;
    private var beatSplitLine:Array<FlxSprite> = [];
    public var crosshair:Crosshair;

    public var lastTarget:GuiElement = null;

    private var textPanel:FlxText;
    private var textPanel1:FlxText;

    private var songPos(get, never):Float;
    function get_songPos():Float {
        return Conductor.songPosition;
    }
    
    public static function reset() {
        lastPos = 0;
        lastUpdateTime = 0;
        nextUpdateTime = 0;
        curSec = 0;
        undos = [];
        redos = [];
        data = [];
        beatSnap = 16;
    }

    public function canInput() {
        return 
            FlxG.mouse.y > 32 && 
            FlxG.mouse.y < FlxG.height - bottomHeight && 
            !tab.isFocused()
        ;
    }

    public static function calcY(strumTime:Float = 0) {
        var map:BPMChangeEvent = Conductor.getBPMFromSeconds(strumTime);
        var crochet:Float = (60 / map.bpm) * 1000;

        if (Conductor.songPosition < map.songTime)     
            return map.songTime + ((strumTime - map.songTime) / crochet * Conductor.crochet);

        map = Conductor.getBPMFromSeconds(Conductor.songPosition);

        if (strumTime < map.songTime)     
            return map.songTime + ((strumTime - map.songTime) / crochet * Conductor.crochet);

        return strumTime;
    }

    public function removeElement(element:GuiElement) {
        var wasSelected = false;
        selectIndicator.forEachAlive(function (indicator:SelectIndicator) {
            if (indicator.target == element) {
                wasSelected = true;
                ChartEditorState.INSTANCE.selectIndicator.remove(indicator);
            }
        });

        data[element.dataID].set('wasSelected', wasSelected);

        renderNotes.remove(element);
    }

    public function addElement(element:GuiElement, pushData:Bool = false) {
        renderNotes.add(element);
        if (data[element.dataID].exists('wasSelected')) if (data[element.dataID].get('wasSelected')) selectIndicator.add(new SelectIndicator(element));
    }

    public function addAction(action:EditorAction) {
        undos.push(action);
        if (redos.length > 0) redos = new Array<EditorAction>();
    }

    function pause() {
        if (paused && Conductor.songPosition < FlxG.sound.music.length) { // resume
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
    
    public function updateGrid() {
        var songPos:Float = Conductor.songPosition;

        if (curSec < 0 || Conductor.songPosition < 0) {
            curSec = 0;
            Conductor.changeBPM(sectionBPM[0]);
            lastUpdateTime = 0;
            nextUpdateTime = _song.notes[curSec].sectionBeats * Conductor.crochet;

            conductorLine.color = sectionBPM[curSec] == sectionBPM[curSec + 1] ? FlxColor.WHITE : FlxColor.YELLOW;

            songPos = 0;
            Conductor.songPosition = 0;
            if (!paused) pause();
        }

        if (songPos > nextUpdateTime) {
            curSec++;

            if (curSec >= _song.notes.length) {
                curSec--;

                var sec:SwagSection = {
                    sectionBeats: _song.notes[curSec].sectionBeats,
                    bpm: sectionBPM[curSec],
                    changeBPM: false,
                    mustHitSection: _song.notes[curSec].mustHitSection,
                    gfSection: _song.notes[curSec].gfSection,
                    sectionNotes: [],
                    typeOfSection: 0,
                    altAnim: _song.notes[curSec].altAnim
                };
                _song.notes.push(sec);

                sectionBPM.push(sectionBPM[curSec]);

                curSec++;
            }

            Conductor.changeBPM(sectionBPM[curSec]);
            
            lastUpdateTime = nextUpdateTime;
            nextUpdateTime += _song.notes[curSec].sectionBeats * Conductor.crochet;

        }
        if (songPos < lastUpdateTime && songPos >= 0) {
            curSec--;

            if (curSec < 0) curSec = 0;

            Conductor.changeBPM(sectionBPM[curSec]);

            nextUpdateTime = lastUpdateTime;
            lastUpdateTime -= _song.notes[curSec].sectionBeats * Conductor.crochet;
        }

        gridBG.scale.y = _song.notes[curSec].sectionBeats / 4;
    }

    function saveChanges() {
        _song.events = new Array();

        for (section in _song.notes) section.sectionNotes = new Array<Dynamic>();

        renderNotes.forEachAlive(function (i:FlxSprite) {
            if (Std.isOfType(i, GuiNote)) {
                var note:GuiNote = (cast (i, GuiNote));

                var targetSection:Int = 0;
                var endTime:Float = 0;
                while (endTime < note.strumTime) {
                    endTime += _song.notes[targetSection].sectionBeats * (60 / sectionBPM[curSec]) * 1000;
                    targetSection++;
                }

                if (targetSection >= _song.notes.length) targetSection--;

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
    
    function onSaveComplete(_) {
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved LEVEL DATA.");
	}

    /**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void {
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onSaveError(_):Void {
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving Level data");
	}

    public function updateBPM() {
        sectionBPM = [];

        var lastBPM:Float = _song.bpm;
        for (section in _song.notes) {
            if (!Std.isOfType(section.sectionBeats, Float) || section.sectionBeats < 1) section.sectionBeats = 4;
            if (!Std.isOfType(section.bpm, Float) || section.bpm < 0) section.bpm = _song.bpm;
            if (!Std.isOfType(section.gfSection, Bool)) section.gfSection = false;
            if (!Std.isOfType(section.changeBPM, Bool)) section.changeBPM = false;
            if (!Std.isOfType(section.altAnim, Bool)) section.altAnim = false;

            if (section.changeBPM) lastBPM = section.bpm;
            sectionBPM.push(lastBPM);
        }

        Conductor.mapBPMChanges(ChartEditorState._song);
        Conductor.changeBPM(sectionBPM[curSec]);
    }

    public function new() {
        super("ChartEditorState");
        INSTANCE = this;
    }
    
    override function destroy() {
        super.destroy();
        lastPos = Conductor.songPosition;
    }

    function handleKeybinds() {
        if (FlxG.keys.justPressed.ENTER) {
            if (!paused) pause();
            saveChanges();
            FlxG.mouse.visible = false;
            StageData.loadDirectory(_song);
            LoadingState.loadAndSwitchState(new PlayState());
        }
        if (((FlxG.mouse.wheel > 0 && Conductor.songPosition > 0) || (FlxG.mouse.wheel < 0 && Conductor.songPosition < FlxG.sound.music.length)) && paused)
            Conductor.songPosition -= Conductor.crochet * FlxG.mouse.wheel;
        if (FlxG.keys.justPressed.SPACE) pause();

        // selection
        if (FlxG.mouse.justPressed && crosshair.target != null) {
            if (FlxG.keys.pressed.CONTROL) {
                var isSelected:Bool = false;
                selectIndicator.forEachAlive(function (indicator:SelectIndicator) {
                    if (indicator.target == crosshair.target) isSelected = true;
                });

                if (!isSelected) selectIndicator.add(new SelectIndicator(crosshair.target));
                else selectIndicator.forEachAlive(function (indicator:SelectIndicator) {
                    if (indicator.target == crosshair.target) selectIndicator.remove(indicator);
                });
            }
        }

        // undo / redo
        if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Z && undos.length > 0) {
            undos[undos.length - 1].undo();
            redos.push(undos[undos.length - 1]);
            undos.pop();
        }
        if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Y && redos.length > 0) {
            redos[redos.length - 1].redo();
            undos.push(redos[redos.length - 1]);
            redos.remove(redos[redos.length - 1]);
        }

        if (FlxG.keys.pressed.CONTROL && FlxG.keys.pressed.ALT && FlxG.keys.justPressed.S) {
            if(_song.events != null && _song.events.length > 1) _song.events.sort(CoolUtil.sortByTime);
            var json = {
                "song": _song
            };

            var data:String = Json.stringify(json, "\t");

            if ((data != null) && (data.length > 0)) {
                _file = new FileReference();
                _file.addEventListener(Event.COMPLETE, onSaveComplete);
                _file.addEventListener(Event.CANCEL, onSaveCancel);
                _file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
                _file.save(data.trim(), Paths.formatToSongPath(_song.song) + ".json");
            }
        }

        if (FlxG.keys.justPressed.E) {
            var dataIDs:Array<Int> = [];
            selectIndicator.forEachAlive(function (indicator:SelectIndicator) {
                if (Std.isOfType(indicator.target, GuiNote)) dataIDs.push((cast (indicator.target, GuiNote)).dataID);
            });
            addAction(new LengthChangeAction(dataIDs, 1));
        }

        if (FlxG.keys.justPressed.Q) {
            var dataIDs:Array<Int> = [];
            selectIndicator.forEachAlive(function (indicator:SelectIndicator) {
                if (Std.isOfType(indicator.target, GuiNote)) dataIDs.push((cast (indicator.target, GuiNote)).dataID);
            });
            addAction(new LengthChangeAction(dataIDs, -1));
        }

        // wip
        if (FlxG.keys.anyJustPressed(ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1')))) {
            funkin.component.MusicBeatState.switchState(new funkin.editors.ChartingState());
        }
    }

    function handleGraphic() {
        nextGridBG.y = Y_OFFSET - (songPos - lastUpdateTime + Conductor.crochet * 2) * GRID_SIZE / Conductor.crochet * 4 - GRID_SIZE * 5;
        gridBG.y = Y_OFFSET - (songPos - lastUpdateTime) * GRID_SIZE / Conductor.crochet * 4 - GRID_SIZE * (4 - _song.notes[curSec].sectionBeats) * 2;
        sectionStartLine.y = Y_OFFSET - (songPos - lastUpdateTime) * GRID_SIZE / Conductor.crochet * 4 - sectionStopLine.height / 2;
        sectionStopLine.y = Y_OFFSET - (songPos - nextUpdateTime) * GRID_SIZE / Conductor.crochet * 4 - sectionStopLine.height / 2;

        var anchor:Float = CoolUtil.mod(Conductor.songPosition - lastUpdateTime, Conductor.getCrochetAtTime(Conductor.songPosition));
        anchor = Y_OFFSET - anchor * GRID_SIZE / Conductor.crochet * 4 - sectionStartLine.height / 2;

        for (i in 0...beatSplitLine.length) {
            beatSplitLine[i].y = anchor - GRID_SIZE * 8 + GRID_SIZE * 4 * i;
        }

        textPanel.text = FlxStringUtil.formatTime(Conductor.songPosition / 1000, true) + " / " + FlxStringUtil.formatTime(FlxG.sound.music.length / 1000, true);
        textPanel1.text = "                       Section: " + curSec + " (Beats: " + _song.notes[curSec].sectionBeats + ", BPM: " + sectionBPM[curSec] + ")" + 
		    " Beat: " + curBeat + " | Step: " + curStep + 
            " (" + Std.string(FlxMath.roundDecimal(Conductor.songPosition / 1000, 2)) + ")";
    }
    
    override function update(elapsed:Float) {
        super.update(elapsed);
        call("onUpdate", [elapsed]);

        if (Conductor.songPosition < 0) Conductor.songPosition = 0;
        if (Conductor.songPosition >= FlxG.sound.music.length) Conductor.songPosition = FlxG.sound.music.length;
        if (!paused) Conductor.songPosition = FlxG.sound.music.time;
        if (renderNotes.members.length <= 0) updateGrid();
        
        handleGraphic();
        if (canInput()) {
            handleKeybinds();
            actionListener();
        }
    }

    function actionListener() {
        if (crosshair.visible) {
            if (FlxG.mouse.justPressed && !FlxG.keys.pressed.CONTROL && !FlxG.keys.pressed.SHIFT && crosshair.target == null) {
                if (FlxG.mouse.x > gridBG.x) {
                    var note:GuiNote = new GuiNote(
                            true, 
                            crosshair.getMousePos(), 
                            Math.floor((FlxG.mouse.x - gridBG.x) / GRID_SIZE),
                            0
                    );
                    addAction(new ElementAddAction([note]));
                    crosshair.dragTarget = note;
                }
                else addAction(new ElementAddAction([new GuiEventNote(
                        true, 
                        crosshair.getMousePos(), 
                        [['Add Camera Zoom', '', '']])])
                    );  
            }

            if (Std.isOfType(crosshair.dragTarget, GuiNote) && crosshair.dragTarget != null) {
                var note:GuiNote = cast (lastTarget, GuiNote);
                if (FlxG.mouse.pressed)
                    data[note.dataID].set('susLength', Math.max(0, crosshair.getMousePos() - note.strumTime));
            }


            if (FlxG.keys.justPressed.DELETE) {
                var toDelete:Array<GuiElement> = new Array();

                selectIndicator.forEachAlive(function (indicator:SelectIndicator) {
                    toDelete.push(indicator.target); 
                });

                if (toDelete.length > 0) addAction(new ElementRemoveAction(toDelete));
            }

            if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.X) {
                var toDelete:Array<GuiElement> = new Array();
                
                clipBoard = [];

                selectIndicator.forEachAlive(function (indicator:SelectIndicator) {
                    toDelete.push(indicator.target);
                    clipBoard.push(indicator.target.dataID);
                });

                if (toDelete.length > 0) addAction(new ElementRemoveAction(toDelete));
            }

            if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.C) {
                
                clipBoard = [];

                selectIndicator.forEachAlive(function (indicator:SelectIndicator) {
                    clipBoard.push(indicator.target.dataID);
                });
            }

            if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.V) {
                var toAdd:Array<GuiElement> = new Array();
                
                var firstStrumTime:Float = data[0].get('strumTime');
                for (i in clipBoard) {
                    if (firstStrumTime > data[i].get('strumTime')) firstStrumTime = data[i].get('strumTime');
                }

                var change:Float = crosshair.getMousePos() - firstStrumTime;

                for (i in clipBoard) {
                    var elementData = data[i];

                    var anchor:Float = elementData.get('strumTime') + change;
                    if (anchor >= 0) {
                        if (elementData.get('events') == null) {
                            toAdd.push(new GuiNote(
                                true,
                                anchor,
                                elementData.get('noteData'),
                                elementData.get('susLength'),
                                elementData.get('noteType')
                            ));
                        } else {
                            toAdd.push(new GuiEventNote(
                                true,
                                anchor,
                                elementData.get('events')
                            ));
                        }
                    }
                }
                
                addAction(new ElementAddAction(toAdd));
            }

            if (FlxG.mouse.pressedRight && !FlxG.keys.pressed.CONTROL && crosshair.target != null && !FlxG.keys.pressed.SHIFT) addAction(new ElementRemoveAction([crosshair.target]));
        }
    }

    function tabAction(column:String, line:String) {
        switch (column) {
            case "File":
                switch (line) {
                    case "Save As":
                        saveChanges();
                        if(_song.events != null && _song.events.length > 1) _song.events.sort(CoolUtil.sortByTime);

                        var data:String = Json.stringify({"song": _song}, "\t");
                        _file = new FileReference();
                        _file.addEventListener(Event.COMPLETE, onSaveComplete);
                        _file.addEventListener(Event.CANCEL, onSaveCancel);
                        _file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
                        _file.save(data, '${Paths.formatToSongPath(_song.song)}.json');
                    case "Save Event As":
                        saveChanges();
                        if(_song.events != null && _song.events.length > 1) _song.events.sort(CoolUtil.sortByTime);

                            var data:String = Json.stringify({"song": { events: _song.events }}, "\t");

                            if ((data != null) && (data.length > 0)) {
                                _file = new FileReference();
                                _file.addEventListener(Event.COMPLETE, onSaveComplete);
                                _file.addEventListener(Event.CANCEL, onSaveCancel);
                                _file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
                                _file.save(data.trim(), "events.json");
                            }
                        }
            case "Edit":
                switch (line) {
                    case "Edit Current Section":
                        var section:SwagSection = _song.notes[curSec];
                        var window:UISubState = new UISubState('SectionWindow');

                        openSubState(window);
                        
                        window.setBG(800, 400);

                        window.addText(250, 170, 'Beats:');
                        var beatTextBox = window.addTextBox(320, 168, 50, Std.string(section.sectionBeats), function (textBox) {
                            if (textBox.getInt() == null) textBox.setText('4');
                        });

                        var mustHitCheckBox = window.addCheckBox(250, 200, 'BF/MustHit Section: ', section.mustHitSection, function (value) {});
                        var gfCheckBox = window.addCheckBox(250, 230, 'GF Section: ', section.gfSection, function (value) {});

                        window.addText(250, 260, 'BPM: ');
                        var bpmTextBox = window.addTextBox(320, 258, 50, Std.string(section.bpm), function (textBox) {
                            if (textBox.getInt() == null) textBox.setText(Std.string(section.bpm));
                        });

                        var bpmCheckBox = window.addCheckBox(250, 292, 'Change BPM: ', section.changeBPM, function (value) {});
                        var altCheckBox = window.addCheckBox(250, 322, 'Alt Anim: ', section.altAnim, function (value) {});

                        window.onClose = function () {
                            if (beatTextBox.getText() == Std.string(section.sectionBeats) &&
                                mustHitCheckBox.activated == section.mustHitSection &&
                                gfCheckBox.activated == section.gfSection &&
                                bpmTextBox.getText() == Std.string(section.bpm) &&
                                bpmCheckBox.activated == section.changeBPM &&
                                altCheckBox.activated == section.altAnim
                            ) return;

                            addAction(new SectionAction({
                                sectionNotes: [],
                                sectionBeats: beatTextBox.getFloat(),
                                typeOfSection: section.typeOfSection,
                                mustHitSection: mustHitCheckBox.activated,
                                gfSection: gfCheckBox.activated,
                                bpm: bpmTextBox.getFloat(),
                                changeBPM: bpmCheckBox.activated,
                                altAnim: altCheckBox.activated
                            }, curSec));
                        }

                    case "Edit Selected Notes":
                        var shouldQuit:Bool = true;
                        var prevType:String = null;
                        var isCommon:Bool = true;
                        selectIndicator.forEachAlive(function (indicator:SelectIndicator) {
                            if (Std.isOfType(indicator.target, GuiNote)) {
                                shouldQuit = false;
                                var note:GuiNote = cast (indicator.target, GuiNote);
                                trace(note.noteType);
                                if (prevType != note.noteType) {
                                    if (prevType == null) {
                                        prevType = note.noteType;
                                        trace(prevType);
                                    }
                                    else isCommon = false;
                                }
                            }
                        });

                        if (shouldQuit) return;

                        var window:UISubState = new UISubState('NoteWindow');
                        openSubState(window);
                        window.setBG(800, 400);
                        window.addText(250, 170, 'Type:');

                        if (!isCommon) prevType = '';

                        var datas:Array<Int> = [];
                        var typeTextBox = window.addTextList(320, 168, 200, prevType, ['a', 'b', 'c'], function (textBox) {});

                        selectIndicator.forEachAlive(function (indicator:SelectIndicator) {
                            if (Std.isOfType(indicator.target, GuiNote)) datas.push((cast (indicator.target, GuiNote)).dataID);
                        });

                        window.onClose = function () {
                            addAction(new NoteTypeAction(datas, typeTextBox.getText()));
                        }
                }
        }
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

        updateBPM();

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
        var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF222222;
		add(bg);

        add(gridGroup);

        nextGridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 8, GRID_SIZE * 50);
        nextGridBG.alpha = 0.8;
        nextGridBG.screenCenter(X);
        nextGridBG.y = Y_OFFSET;
        gridGroup.add(nextGridBG);

        gridBG = new FlxSprite().makeGraphic(GRID_SIZE * 8, GRID_SIZE * 16, FlxColor.WHITE);
        gridBG.screenCenter(X);
        gridBG.alpha = 0.3;
        gridGroup.add(gridBG);

        gridGroup.add(new FlxSprite(nextGridBG.x + GRID_SIZE * 4 - 1, 0).makeGraphic(2, Std.int(nextGridBG.height), FlxColor.BLACK));

        add(selectIndicator);
        add(renderNotes);

        for (section in _song.notes) {
            for (note in section.sectionNotes) {
                var guiNote:GuiNote = new GuiNote(true, note[0], Std.int(section.mustHitSection ? (note[1] < 4 ? note[1] + 4 : note[1] - 4) : note[1]), note[2]);
                if (note.length > 3) if (Std.isOfType(note[3], String)) guiNote.noteType = note[3];
            }
        }

        add(hudGroup);

        for (event in _song.events) {
            var guiEventNote:GuiEventNote = new GuiEventNote(true, event[0], event[1]);
            renderNotes.add(guiEventNote);
        }

        if (curSec == 0) {
            lastUpdateTime = 0;
            nextUpdateTime = _song.notes[curSec].sectionBeats * Conductor.crochet;
        }

        for (i in 0...6) {
            var splitLine:FlxSprite = new FlxSprite(0, Y_OFFSET).makeGraphic(GRID_SIZE * 8, 2, FlxColor.RED);
            splitLine.screenCenter(X);
            hudGroup.add(splitLine);
            beatSplitLine.push(splitLine);
        }

        sectionStartLine = new FlxSprite(0, Y_OFFSET).makeGraphic(GRID_SIZE * 8, 2, FlxColor.GREEN);
        sectionStartLine.screenCenter(X);
        hudGroup.add(sectionStartLine);

        sectionStopLine = new FlxSprite(0, Y_OFFSET).makeGraphic(GRID_SIZE * 8, 2, FlxColor.GREEN);
        sectionStopLine.screenCenter(X);
        hudGroup.add(sectionStopLine);

        conductorLine = new FlxSprite(0, Y_OFFSET).makeGraphic(GRID_SIZE * 10, 4, FlxColor.WHITE);
        conductorLine.screenCenter(X);
        hudGroup.add(conductorLine);

        crosshair = new Crosshair();
        hudGroup.add(crosshair);
        
        var bottomHeight:Int = 20;
        hudGroup.add(new FlxSprite(0, FlxG.height - bottomHeight).makeGraphic(FlxG.width, bottomHeight, 0xFF3D3F41));
        
        textPanel = new FlxText(2, FlxG.height - bottomHeight + 1, 0, "hi", 12);
        textPanel.setFormat(Paths.font("vcr.ttf", false), 16, FlxColor.WHITE, LEFT);
        textPanel.wordWrap = false;
        textPanel.autoSize = true;
        hudGroup.add(textPanel);

        textPanel1 = new FlxText(180, FlxG.height - bottomHeight + 1, 0, "hi", 12);
        textPanel1.setFormat(Paths.font("vcr.ttf", false), 16, FlxColor.WHITE, LEFT);
        textPanel1.wordWrap = false;
        textPanel1.autoSize = true;
        hudGroup.add(textPanel1);

        tab = new UIState.Tabs(this,
            ['File', 'Edit', 'Help'], [

            ['Edit Chart Data', 'Save', 'Save Event', 'Save As', 'Save Event As', 'Reload Audio', 'Reload Chart', 'Load Events', 'Exit'], 
            ['Edit Current Section', 'Edit Selected Notes', 'Go To'],
            ['Instructions']
        ]);

        tab.onClick = function (column:String, line:String) {
            tabAction(column, line);
        };

        updateGrid();

        call('postCreate', []);
    }
}