package virt;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import openfl.events.MouseEvent;
import flixel.input.touch.FlxTouch;

class VirtualCursor extends FlxGroup
{
    public var cursorSprite:FlxSprite;
    
    private var isHovering:Bool = false;
    private var _clickTween:FlxTween;
    private var sensitivity:Float = 1.5;

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
        handleTouchInput();

        FlxG.mouse.setGlobalScreenPositionUnsafe(cursorSprite.x, cursorSprite.y);
        
        updateHoverLogic();

        super.update(elapsed);
    }

    private function handleTouchInput():Void 
    {
        var touch:FlxTouch = FlxG.touches.getFirst();
        
        if (touch != null) {
            if (touch.pressed) {
                cursorSprite.x += touch.deltaX * sensitivity;
                cursorSprite.y += touch.deltaY * sensitivity;
            }
            
            if (touch.justReleased && touch.timeInSeconds < 0.2) {
                clickDown();
                clickUp();
            }
        }
        
        if (cursorSprite.x < 0) cursorSprite.x = 0;
        if (cursorSprite.x > FlxG.width) cursorSprite.x = FlxG.width;
        if (cursorSprite.y < 0) cursorSprite.y = 0;
        if (cursorSprite.y > FlxG.height) cursorSprite.y = FlxG.height;
    }

    private function updateHoverLogic():Void
    {
        var currentlyHovering:Bool = false;
        
        FlxG.state.forEachOfType(FlxSprite, function(spr:FlxSprite) {
            if (spr != null && spr.visible && spr.exists && spr != cursorSprite) {
                
                if (spr.getScreenBounds(null, spr.cameras[0]).contains(cursorSprite.x, cursorSprite.y)) {
                    currentlyHovering = true;
                }
            }
        });

        if (currentlyHovering != isHovering) {
            isHovering = currentlyHovering;
            cursorSprite.loadGraphic(isHovering ? HOVER_IMG : CURSOR_IMG);
            
            cursorSprite.scale.set(1, 1); 
        }
    }

    public function clickDown():Void {
        if (_clickTween != null) _clickTween.cancel();
        cursorSprite.scale.set(0.8, 0.8);
        _clickTween = FlxTween.tween(cursorSprite.scale, {x: 1, y: 1}, 0.1, {ease: FlxEase.backOut});
        
        FlxG.stage.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN, true, false, cursorSprite.x, cursorSprite.y));
    }

    public function clickUp():Void {
        FlxG.stage.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_UP, true, false, cursorSprite.x, cursorSprite.y));
    }
}
