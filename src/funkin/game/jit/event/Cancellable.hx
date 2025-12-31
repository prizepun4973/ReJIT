package funkin.game.jit.event;

class Cancellable {
    public var cancelled:Bool = false;
    public var ignoreStops:Bool = false;

    public function cancel() { cancelled = true; }

    public function new() {}
}