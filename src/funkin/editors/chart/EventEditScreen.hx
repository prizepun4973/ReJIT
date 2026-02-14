package funkin.editors.chart;

import funkin.editors.chart.element.GuiEventNote;
import funkin.component.ui.*;

class EventEditScreen extends funkin.ui.UISubState {
    public var target:Map<String, Dynamic>;

    var events:Array<Array<String>> = [];

    var buttons:Array<ButtonWidget> = [];
    var titleTextBox:TextBoxWidget;
    var value1TextBox:TextBoxWidget;
    var value2TextBox:TextBoxWidget;
    var curPage:Int = 0;

    public override function new(dataID:Int) {
        target = ChartEditorState.data[dataID];
        super('EventEditScreen');
    }

    override function create() {
        super.create();
        setBG(1200, 650);

        var casted:Array<Array<String>> = target.get('events');
        for (i in casted)
            events.push(i);

        titleTextBox = addTextList(640, 100, 100, events[curPage][0], [], function (textBox) {
            if (events.length > 0) events[curPage][0] = textBox.getText();
            if (buttons.length > 0) buttons[curPage].setText(textBox.getText());
        });

        value1TextBox = addTextBox(640, 150, 100, events[curPage][1], function (textBox) {
            if (events.length > 0) events[curPage][1] = textBox.getText();
        });

        value2TextBox = addTextBox(640, 200, 100, events[curPage][2], function (textBox) {
            if (events.length > 0) events[curPage][2] = textBox.getText();
        });

        for (i in 0...events.length) {
            buttons.push(addButton(45, 35 + i * 27, events[i][0], function () {
                titleTextBox.setText(events[i][0]);
                value1TextBox.setText(events[i][1]);
                value2TextBox.setText(events[i][2]);
                curPage = i;
            }));
        }
    }

    override function destroy() {
        target.set('events', events);
        super.destroy();
    }
}