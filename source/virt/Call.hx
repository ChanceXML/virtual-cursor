package virt;

import flixel.FlxG;
import flixel.FlxCamera;

class Call {
    public static var mouse:VirtualCursor;
    public static var mouseCam:FlxCamera;

    public static function Mouse():Void {
        if (mouse != null) {
            if (FlxG.plugins.list.contains(mouse)) {
                FlxG.plugins.remove(mouse);
            }
            mouse.destroy();
            mouse = null;
        }

        if (mouseCam != null && FlxG.cameras.list.contains(mouseCam)) {
            FlxG.cameras.remove(mouseCam, false);
            mouseCam = null;
        }

        mouseCam = new FlxCamera();
        mouseCam.bgColor.alpha = 0; 
        FlxG.cameras.add(mouseCam, false); 

        mouse = new VirtualCursor(FlxG.width / 2, FlxG.height / 2);
        mouse.cursorSprite.cameras = [mouseCam];
        
        FlxG.plugins.add(mouse);
    }
    
    public static function kill():Void {
        if (mouse != null) {
            FlxG.plugins.remove(mouse);
            mouse.destroy();
            mouse = null;
        }
    }
}
