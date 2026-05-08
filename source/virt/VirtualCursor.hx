package virt;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxBasic;
import flixel.group.FlxGroup;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
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
    public var tapThreshold:Float = 20.0;
    public var holdDelay:Float = 0.2;
    
    private var isHovering:Bool = false;
    private var _currentlyHovering:Bool = false;
    private var _clickTween:FlxTween;
    
    private var _lastTouchPos:FlxPoint; 
    private var _startTouchPos:FlxPoint;
    private var _trackedTouchID:Int = -1; 
    
    private var _touchState:Int = 0;
    private var _touchTimer:Float = 0;
    private var _clickTimer:Float = 0;
    
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
        handleTouchInput(elapsed);
        
        FlxG.mouse.setGlobalScreenPositionUnsafe(cursorSprite.x, cursorSprite.y);

        if (_clickTimer > 0)
        {
            _clickTimer -= elapsed;
            if (_clickTimer <= 0)
            {
                handleRelease();
            }
        }

        if (FlxG.cameras.list.indexOf(_cursorCamera) < FlxG.cameras.list.length - 1)
        {
            FlxG.cameras.remove(_cursorCamera, false);
            FlxG.cameras.add(_cursorCamera, false);
        }

        updateHoverLogic();
        super.update(elapsed);
    }

    private function handleTouchInput(elapsed:Float):Void 
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
            
            if (activeTouch == null) 
            {
                if (_touchState == 3) handleRelease();
                _touchState = 0;
                _trackedTouchID = -1;
            }
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
                    _touchState = 1;
                    _touchTimer = 0;
                    break;
                }
            }
        }
        
        if (activeTouch != null) 
        {
            if (activeTouch.pressed || activeTouch.justReleased) 
            {
                var dx:Float = activeTouch.screenX - _lastTouchPos.x;
                var dy:Float = activeTouch.screenY - _lastTouchPos.y;
                
                cursorSprite.x = FlxMath.bound(cursorSprite.x + dx * sensitivity, 0, FlxG.width);
                cursorSprite.y = FlxMath.bound(cursorSprite.y + dy * sensitivity, 0, FlxG.height);
                
                _lastTouchPos.set(activeTouch.screenX, activeTouch.screenY);
            }

            if (activeTouch.pressed && _touchState == 1)
            {
                _touchTimer += elapsed;
                var distX = activeTouch.screenX - _startTouchPos.x;
                var distY = activeTouch.screenY - _startTouchPos.y;
                var distFromStart = Math.sqrt(distX * distX + distY * distY);

                if (distFromStart > tapThreshold)
                {
                    _touchState = 2;
                }
                else if (_touchTimer >= holdDelay)
                {
                    _touchState = 3;
                    handlePress();
                }
            }
            
            if (activeTouch.justReleased) 
            {
                if (_touchState == 1)
                {
                    performQuickClick();
                }
                else if (_touchState == 3)
                {
                    handleRelease();
                }
                
                _touchState = 0;
                _trackedTouchID = -1;
            }
        }
    }

    private function performQuickClick():Void
    {
        handlePress();
        _clickTimer = 0.05;
    }

    private function handlePress():Void
    {
        if (_clickTween != null) _clickTween.cancel();
        cursorSprite.scale.set(0.7, 0.7);
        
        @:privateAccess FlxG.mouse._leftButton.press();
        checkForInputText();
    }

    private function handleRelease():Void
    {
        if (_clickTween != null) _clickTween.cancel();
        _clickTween = FlxTween.tween(cursorSprite.scale, {x: 1, y: 1}, 0.15, {ease: FlxEase.backOut});

        @:privateAccess FlxG.mouse._leftButton.release();
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
