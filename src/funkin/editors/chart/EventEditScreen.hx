package funkin.editors.chart;

import funkin.editors.chart.element.GuiEventNote;
import funkin.component.ui.TextBoxWidget;

class EventEditScreen extends funkin.ui.UISubState {
    public var target:Map<String, Dynamic>;

    var events:Array<Array<String>> = [[]];
    var value1TextBox:TextBoxWidget;
    var value2TextBox:TextBoxWidget;

    public override function new(event:GuiEventNote) {
        target = ChartEditorState.data[event.dataID];
        super('EventEditScreen');
    }

    override function create() {
        super.create();
        setBG(1200, 650);

        events = target.get('events');
        trace(events);
        
        addText(600, 35, '1111');

        value1TextBox = addTextBox(600, 100, 100, 'hi', function (textBox) {});
        value2TextBox = addTextBox(600, 150, 100, 'hi', function (textBox) {});

        for (i in 0...events.length) {
            addButton(40, 35 + i * 25, (i + 1) + ". " + events[i][0], function () {
                trace('hi');
            });
        }
    }
}