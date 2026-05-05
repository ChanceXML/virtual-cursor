package virt;

import flixel.FlxG;

class Call {
    public static var mouse:VirtualCursor;

    /**
     * Usage: Call.Mouse();
     */
    public static function Mouse():Void {
        mouse = new VirtualCursor(FlxG.width / 2, FlxG.height / 2);
        FlxG.state.add(mouse);
    }
}
