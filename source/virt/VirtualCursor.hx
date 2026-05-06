package virt;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.group.FlxGroup;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import openfl.events.MouseEvent;
import flixel.input.touch.FlxTouch;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;
import haxe.Timer;
import openfl.Lib;

import flixel.text.FlxInputText; 

@:keep
class VirtualCursor extends FlxGroup
{
    public var cursorSprite:FlxSprite;
    public var sensitivity:Float = 1.5;
    
    public var disableGhostTouch:Bool = false;

    private var isHovering:Bool = false;
    private var _clickTween:FlxTween;
    private var _lastTouchPosition:FlxPoint; 
    private var _dragDistance:Float = 0.0;
    private var _pressStartTime:Float = 0.0;
    
    private static inline var CURSOR_IMG:String = "assets/images/menus/cursor/mouse.png";
    private static inline var HOVER_IMG:String = "assets/images/menus/cursor/hover.png";

    public function new(startX:Float = 0, startY:Float = 0)
    {
        super();

        cursorSprite = new FlxSprite(startX, startY);
        cursorSprite.loadGraphic(CURSOR_IMG);
        cursorSprite.antialiasing = true;
        add(cursorSprite);
        
        _lastTouchPosition = new FlxPoint();

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
            if (touch.justPressed) {
                _lastTouchPosition.set(touch.screenX, touch.screenY);
                _dragDistance = 0;
                _pressStartTime = Timer.stamp();
            }
            else if (touch.pressed) {
                var dx:Float = touch.screenX - _lastTouchPosition.x;
                var dy:Float = touch.screenY - _lastTouchPosition.y;
                
                cursorSprite.x += dx * sensitivity;
                cursorSprite.y += dy * sensitivity;
                
                if (cursorSprite.x < 0) cursorSprite.x = 0;
                if (cursorSprite.x > FlxG.width) cursorSprite.x = FlxG.width;
                if (cursorSprite.y < 0) cursorSprite.y = 0;
                if (cursorSprite.y > FlxG.height) cursorSprite.y = FlxG.height;
                
                _dragDistance += Math.abs(dx) + Math.abs(dy);
                _lastTouchPosition.set(touch.screenX, touch.screenY);
            }
            
            FlxG.mouse.setGlobalScreenPositionUnsafe(cursorSprite.x, cursorSprite.y);

            if (touch.justReleased) {
                var holdTime:Float = Timer.stamp() - _pressStartTime;
                if (_dragDistance < 10 && holdTime < 0.35) {
                    clickDown();
                    clickUp();
                }
            }

            if (!disableGhostTouch) {
                @:privateAccess {
                    touch._globalScreenX = -10000;
                    touch._globalScreenY = -10000;
                }
            }
        }
    }

    private function updateHoverLogic():Void
    {
        var currentlyHovering:Bool = false;

        var checkOverlap = function(obj:Dynamic) {
            if (obj != null && obj.visible && obj.exists && obj != cursorSprite) {
                if (Std.isOfType(obj, FlxSprite)) {
                    var spr:FlxSprite = cast obj;
                    var targetCam = spr.camera; 
                    if (spr.getScreenBounds(null, targetCam).containsXY(cursorSprite.x, cursorSprite.y)) {
                        currentlyHovering = true;
                    }
                }
            }
        };

        FlxG.state.forEachOfType(FlxSprite, function(spr) checkOverlap(spr));
        
        if (FlxG.state.subState != null) {
             FlxG.state.subState.forEachOfType(FlxSprite, function(spr) checkOverlap(spr));
        }

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
        
        if (FlxG.stage != null) {
            FlxG.stage.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN, true, false, cursorSprite.x, cursorSprite.y));
        }
    }

    public function clickUp():Void {
        if (FlxG.stage != null) {
            FlxG.stage.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_UP, true, false, cursorSprite.x, cursorSprite.y));
            
            checkForInputText();
        }
    }
    
    private function checkForInputText():Void {
        var foundInput:Bool = false;
        
        var checkObject = function(obj:Dynamic) {
            if (obj != null && obj.visible && obj.exists) {
                if (Std.isOfType(obj, FlxInputText)) {
                    var input:FlxInputText = cast obj;
                    var targetCam = input.camera;
                    
                    if (input.getScreenBounds(null, targetCam).containsXY(cursorSprite.x, cursorSprite.y)) {
                        @:privateAccess input.hasFocus = true;
                        Lib.application.window.textInputEnabled = true;
                        foundInput = true;
                    }
                }
            }
        };

        FlxG.state.forEach(checkObject, true);
        if (FlxG.state.subState != null) {
            FlxG.state.subState.forEach(checkObject, true);
        }
    }
    
    override public function destroy():Void {
        super.destroy();
        
        if (_clickTween != null) {
            _clickTween.cancel();
            _clickTween = null;
        }
        
        _lastTouchPosition = FlxDestroyUtil.put(_lastTouchPosition);
        
        cursorSprite = null; 
    }
}
