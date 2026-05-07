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
import openfl.Lib;
import flixel.text.FlxInputText; 

@:keep
class VirtualCursor extends FlxGroup
{
    public var cursorSprite:FlxSprite;
    public var sensitivity:Float = 1.5;
    
    public var tapThreshold:Float = 15.0; 
    
    private var isHovering:Bool = false;
    private var _currentlyHovering:Bool = false;
    private var _clickTween:FlxTween;
    
    private var _lastTouchPos:FlxPoint; 
    private var _startTouchPos:FlxPoint;
    private var _trackedTouchID:Int = -1; 
    private var _movedSignificantly:Bool = false;
    
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
        
        _lastTouchPos = new FlxPoint();
        _startTouchPos = new FlxPoint();

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
                    _lastTouchPos.set(touch.screenX, touch.screenY);
                    _startTouchPos.set(touch.screenX, touch.screenY);
                    _movedSignificantly = false;
                    break;
                }
            }
        }
        
        if (activeTouch != null) 
        {
            if (activeTouch.pressed) 
            {
                var dx:Float = activeTouch.screenX - _lastTouchPos.x;
                var dy:Float = activeTouch.screenY - _lastTouchPos.y;
                
                cursorSprite.x = FlxMath.bound(cursorSprite.x + dx * sensitivity, 0, FlxG.width);
                cursorSprite.y = FlxMath.bound(cursorSprite.y + dy * sensitivity, 0, FlxG.height);
                
                var distFromStart = FlxMath.distanceBetween(new FlxPoint(activeTouch.screenX, activeTouch.screenY), _startTouchPos);
                if (distFromStart > tapThreshold) {
                    _movedSignificantly = true;
                }

                _lastTouchPos.set(activeTouch.screenX, activeTouch.screenY);
            }
            
            if (activeTouch.justReleased) 
            {
                if (!_movedSignificantly) 
                {
                    performClick();
                }
                _trackedTouchID = -1;
            }
        }
    }

    private function performClick():Void 
    {
        if (_clickTween != null) _clickTween.cancel();
        cursorSprite.scale.set(0.7, 0.7);
        _clickTween = FlxTween.tween(cursorSprite.scale, {x: 1, y: 1}, 0.15, {ease: FlxEase.backOut});
        
        if (FlxG.stage != null) 
        {
            FlxG.stage.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN, true, false, cursorSprite.x, cursorSprite.y));
            
            haxe.Timer.delay(function() {
                FlxG.stage.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_UP, true, false, cursorSprite.x, cursorSprite.y));
                checkForInputText();
            }, 20);
        }
    }

    private function updateHoverLogic():Void
    {
        _currentlyHovering = false;

        if (FlxG.state != null)
        {
            FlxG.state.forEachOfType(FlxSprite, checkHoverOverlap);
            if (FlxG.state.subState != null)
                FlxG.state.subState.forEachOfType(FlxSprite, checkHoverOverlap);
        }

        if (_currentlyHovering != isHovering)
        {
            isHovering = _currentlyHovering;
            cursorSprite.loadGraphic(isHovering ? HOVER_IMG : CURSOR_IMG);
        }
    }

    private function checkHoverOverlap(spr:FlxSprite):Void
    {
        if (_currentlyHovering || spr == null || !spr.visible || !spr.exists || spr == cursorSprite)
            return;
        
        if (FlxG.mouse.overlaps(spr, spr.camera))
        {
            _currentlyHovering = true;
        }
    }
    
    private function checkForInputText():Void 
    {
        var check = function(obj:FlxBasic) {
            if (obj != null && obj.visible && obj.exists && Std.isOfType(obj, FlxInputText)) {
                var input:FlxInputText = cast obj;
                if (FlxG.mouse.overlaps(input, input.camera)) {
                    @:privateAccess input.hasFocus = true;
                    Lib.application.window.textInputEnabled = true;
                }
            }
        };

        FlxG.state.forEach(check, true);
        if (FlxG.state.subState != null) FlxG.state.subState.forEach(check, true);
    }
    
    override public function destroy():Void 
    {
        _lastTouchPos = FlxDestroyUtil.put(_lastTouchPos);
        _startTouchPos = FlxDestroyUtil.put(_startTouchPos);
        if (_clickTween != null) _clickTween.cancel();
        super.destroy();
    }
}
