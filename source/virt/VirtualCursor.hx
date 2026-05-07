package virt;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxBasic;
import flixel.group.FlxGroup;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import openfl.events.MouseEvent;
import flixel.input.touch.FlxTouch;
import flixel.math.FlxPoint;
import flixel.math.FlxMath;
import flixel.util.FlxDestroyUtil;
import haxe.Timer;
import openfl.Lib;
import flixel.text.FlxInputText; 

@:keep
class VirtualCursor extends FlxGroup
{
    public var cursorSprite:FlxSprite;
    public var sensitivity:Float = 1.5;
    public var disableGhostTouch:Bool = true;
    public var holdTimeThreshold:Float = 0.15; 
    
    private var _holdTriggered:Bool = false;
    private var isHovering:Bool = false;
    private var _currentlyHovering:Bool = false;
    private var _clickTween:FlxTween;
    private var _lastTouchPosition:FlxPoint; 
    private var _dragDistance:Float = 0.0;
    private var _pressStartTime:Float = 0.0;
    
    private var _trackedTouchID:Int = -1; 
    
    private static inline var CURSOR_IMG:String = "assets/images/menus/cursor/mouse.png";
    private static inline var HOVER_IMG:String = "assets/images/menus/cursor/hover.png";

    public function new(startX:Float = 0, startY:Float = 0)
    {
        super();

        cursorSprite = new FlxSprite(startX, startY);
        cursorSprite.loadGraphic(CURSOR_IMG);
        cursorSprite.antialiasing = true;
        cursorSprite.scrollFactor.set(0, 0); 
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
        var activeTouch:FlxTouch = null;

        if (_trackedTouchID != -1) 
        {
            for (touch in FlxG.touches.list) 
            {
                if (touch.touchPointID == _trackedTouchID) 
                {
                    activeTouch = touch;
                    break;
                }
            }
            if (activeTouch == null) _trackedTouchID = -1;
        }

        if (activeTouch == null) 
        {
            for (touch in FlxG.touches.list) 
            {
                if (touch.justPressed) 
                {
                    activeTouch = touch;
                    _trackedTouchID = touch.touchPointID;
                    
                    _lastTouchPosition.set(touch.screenX, touch.screenY);
                    _dragDistance = 0;
                    _pressStartTime = Timer.stamp();
                    _holdTriggered = false;
                    break;
                }
            }
        }
        
        if (activeTouch != null) 
        {
            if (activeTouch.pressed && !activeTouch.justPressed) 
            {
                var dx:Float = activeTouch.screenX - _lastTouchPosition.x;
                var dy:Float = activeTouch.screenY - _lastTouchPosition.y;
                
                cursorSprite.x = FlxMath.bound(cursorSprite.x + dx * sensitivity, 0, FlxG.width);
                cursorSprite.y = FlxMath.bound(cursorSprite.y + dy * sensitivity, 0, FlxG.height);
                
                _dragDistance += Math.abs(dx) + Math.abs(dy);
                _lastTouchPosition.set(activeTouch.screenX, activeTouch.screenY);

                if (!_holdTriggered && (Timer.stamp() - _pressStartTime) >= holdTimeThreshold) 
                {
                    _holdTriggered = true;
                    clickDown();
                }
            }
            
            if (activeTouch.justReleased) 
            {
                if (!_holdTriggered) 
                {
                    clickDown();
                    clickUp();
                } 
                else 
                {
                    clickUp();
                }
                _trackedTouchID = -1;
            }
            if (!disableGhostTouch) 
            {
                @:privateAccess 
                {
                    activeTouch._globalScreenX = -10000;
                    activeTouch._globalScreenY = -10000;
                }
            }
        }
    }

    private function updateHoverLogic():Void
    {
        _currentlyHovering = false;

        FlxG.state.forEachOfType(FlxSprite, checkHoverOverlap);
        if (FlxG.state.subState != null) 
        {
             FlxG.state.subState.forEachOfType(FlxSprite, checkHoverOverlap);
        }

        if (_currentlyHovering != isHovering) 
        {
            isHovering = _currentlyHovering;
            cursorSprite.loadGraphic(isHovering ? HOVER_IMG : CURSOR_IMG);
            cursorSprite.scale.set(1, 1); 
        }
    }

    private function checkHoverOverlap(spr:FlxSprite):Void 
    {
        if (_currentlyHovering || spr == null || !spr.visible || !spr.exists || spr == cursorSprite) return;
        
        if (FlxG.mouse.overlaps(spr, spr.camera)) 
        {
            _currentlyHovering = true;
        }
    }

    public function clickDown():Void 
    {
        if (_clickTween != null) _clickTween.cancel();
        cursorSprite.scale.set(0.8, 0.8);
        _clickTween = FlxTween.tween(cursorSprite.scale, {x: 1, y: 1}, 0.1, {ease: FlxEase.backOut});
        
        if (FlxG.stage != null) 
        {
            Timer.delay(function() {
                FlxG.stage.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN, true, false, cursorSprite.x, cursorSprite.y));
            }, 1);
        }
    }

    public function clickUp():Void 
    {
        if (FlxG.stage != null) 
        {
            Timer.delay(function() {
                FlxG.stage.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_UP, true, false, cursorSprite.x, cursorSprite.y));
                checkForInputText();
            }, 1);
        }
    }
    
    private function checkForInputText():Void 
    {
        FlxG.state.forEach(checkInputTextOverlap, true);
        if (FlxG.state.subState != null) 
        {
            FlxG.state.subState.forEach(checkInputTextOverlap, true);
        }
    }

    private function checkInputTextOverlap(obj:FlxBasic):Void 
    {
        if (obj != null && obj.visible && obj.exists && Std.isOfType(obj, FlxInputText)) 
        {
            var input:FlxInputText = cast obj;
            if (FlxG.mouse.overlaps(input, input.camera)) 
            {
                @:privateAccess input.hasFocus = true;
                Lib.application.window.textInputEnabled = true;
            }
        }
    }
    
    override public function destroy():Void 
    {
        super.destroy();
        if (_clickTween != null) 
        {
            _clickTween.cancel();
            _clickTween = null;
        }
        _lastTouchPosition = FlxDestroyUtil.put(_lastTouchPosition);
        cursorSprite = null; 
    }
}
