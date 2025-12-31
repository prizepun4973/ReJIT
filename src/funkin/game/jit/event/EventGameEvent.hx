package funkin.game.jit.event;

class EventGameEvent extends Cancellable {
    public var name:String;
    public var value1:String;
    public var value2:String;

    public function new(name:String, value1:String, value2:String) {
        super();
        this.name = name;
        this.value1 = value1;
        this.value2 = value2;
    }
}