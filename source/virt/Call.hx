package virt;

import flixel.FlxG;
import flixel.FlxCamera;

class Call {
    public static var mouse:VirtualCursor;
    public static var mouseCam:FlxCamera;
    /**
    usage: Call.Mouse();
    **/
    public static function Mouse():Void {
        mouseCam = new FlxCamera();
        mouseCam.bgColor.alpha = 0;
        FlxG.cameras.add(mouseCam, false);

        mouse = new VirtualCursor(FlxG.width / 2, FlxG.height / 2);
        
        mouse.cursorSprite.cameras = [mouseCam];
        
        FlxG.state.add(mouse);
    }
}
