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
import flixel.FlxCamera;

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
    private var _isHolding:Bool = false;
    
    private static inline var CURSOR_IMG:String = "assets/images/menus/cursor/mouse.png";
    private static inline var HOVER_IMG:String = "assets/images/menus/cursor/hover.png";

    private var _cursorCamera:FlxCamera;

    public function new(startX:Float = 0, startY:Float = 0)
    {
        super();

        _cursorCamera = new FlxCamera();
        _cursorCamera.bgColor = 0x00000000;
        FlxG.cameras.add(_cursorCamera, false);

        cursorSprite = new FlxSprite(startX, startY);
        cursorSprite.loadGraphic(CURSOR_IMG);
        cursorSprite.antialiasing = true;
        cursorSprite.scrollFactor.set(0, 0); 
        cursorSprite.cameras = [_cursorCamera];
        add(cursorSprite);
        
        _lastTouchPos = FlxPoint.get();
        _startTouchPos = FlxPoint.get();

        #if mobile
        FlxG.mouse.visible = false;
        FlxG.mouse.enabled = false; 
        #end
    }

    override public function update(elapsed:Float):Void
    {
        handleTouchInput();
        
        FlxG.mouse.setGlobalScreenPositionUnsafe(cursorSprite.x, cursorSprite.y);

        if (FlxG.cameras.list.indexOf(_cursorCamera) < FlxG.cameras.list.length - 1)
        {
            FlxG.cameras.remove(_cursorCamera, false);
            FlxG.cameras.add(_cursorCamera, false);
        }

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
            if (activeTouch == null) handleRelease();
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
                    handlePress();
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
                
                _lastTouchPos.set(activeTouch.screenX, activeTouch.screenY);
            }
            
            if (activeTouch.justReleased) 
            {
                handleRelease();
            }
        }
    }

    private function handlePress():Void
    {
        _isHolding = true;
        if (_clickTween != null) _clickTween.cancel();
        cursorSprite.scale.set(0.7, 0.7);
        
        @:privateAccess FlxG.mouse._leftButton.press();
        if (FlxG.stage != null) 
            FlxG.stage.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN, true, false, cursorSprite.x, cursorSprite.y));
        
        checkForInputText();
    }

    private function handleRelease():Void
    {
        _isHolding = false;
        _trackedTouchID = -1;
        
        if (_clickTween != null) _clickTween.cancel();
        _clickTween = FlxTween.tween(cursorSprite.scale, {x: 1, y: 1}, 0.15, {ease: FlxEase.backOut});

        @:privateAccess FlxG.mouse._leftButton.release();
        if (FlxG.stage != null)
            FlxG.stage.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_UP, true, false, cursorSprite.x, cursorSprite.y));
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
        
        #if mobile
        FlxG.mouse.enabled = true; 
        #end
        
        if (_cursorCamera != null)
            FlxG.cameras.remove(_cursorCamera);
            
        super.destroy();
    }
}
