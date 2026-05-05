package virt;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import openfl.events.MouseEvent;

class VirtualCursor extends FlxGroup
{
    public var cursorSprite:FlxSprite;
    public var speed:Float = 15.0; 
    
    private var isHovering:Bool = false;
    private var _clickTween:FlxTween;

    private static inline var CURSOR_IMG:String = "assets/images/menus/cursor/cursor.png";
    private static inline var HOVER_IMG:String = "assets/images/menus/cursor/hover.png";

    public function new(startX:Float = 0, startY:Float = 0)
    {
        super();
        
        cursorSprite = new FlxSprite(startX, startY);
        cursorSprite.loadGraphic(CURSOR_IMG);
        add(cursorSprite);

        #if mobile
        FlxG.mouse.visible = false;
        #end
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
        
        FlxG.mouse.setGlobalScreenPositionUnsafe(cursorSprite.x, cursorSprite.y);
        
        updateHoverLogic();
    }

    private function updateHoverLogic():Void
    {
        var currentlyHovering:Bool = false;

        FlxG.state.forEachOfType(FlxSprite, function(spr:FlxSprite) {
            if (spr != null && spr.visible && spr.exists) {
                if (spr.overlapsPoint(FlxG.mouse.getScreenPosition())) {
                    currentlyHovering = true;
                }
            }
        });

        if (currentlyHovering != isHovering) {
            isHovering = currentlyHovering;
            cursorSprite.loadGraphic(isHovering ? HOVER_IMG : CURSOR_IMG);
        }
    }

    public function move(dx:Float, dy:Float):Void
    {
        cursorSprite.x += dx * speed;
        cursorSprite.y += dy * speed;
        
        cursorSprite.x = Math.max(0, Math.min(FlxG.width - cursorSprite.width, cursorSprite.x));
        cursorSprite.y = Math.max(0, Math.min(FlxG.height - cursorSprite.height, cursorSprite.y));
    }

    public function clickDown():Void
    {
        if (_clickTween != null) _clickTween.cancel();
        cursorSprite.scale.set(0.8, 0.8);
        _clickTween = FlxTween.tween(cursorSprite.scale, {x: 1, y: 1}, 0.1, {ease: FlxEase.backOut});

        FlxG.stage.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN, true, false, cursorSprite.x, cursorSprite.y));
    }

    public function clickUp():Void
    {
        FlxG.stage.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_UP, true, false, cursorSprite.x, cursorSprite.y));
    }
}
