package funkin.editors.chart.action;

import funkin.editors.chart.ChartEditorState;

abstract class EditorAction {
    public var editor:ChartEditorState = ChartEditorState.INSTANCE;
    public var dataID:Int;
    public function new() {}
    public function redo() {}
    public function undo() {}
}