package funkin.game.jit;

class Cancellable {
    public var cancelled:Bool = false;
    public var ignoreStops:Bool = false;

    public function cancel() { cancelled = true; }
}