package virt;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxMath;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.input.touch.FlxTouch;
import openfl.Lib;

/**
 * Virtual Cursor
 * Added as a Plugin to override all states/substates.
 * Use VirtualCursor.init() to start and VirtualCursor.killCursor() to stop.
 */
@:keep
class VirtualCursor extends FlxBasic
{
    public static var instance:VirtualCursor;

    public var cursorSprite:FlxSprite;
    public var sensitivity:Float = 1.5;
    public var tapThreshold:Float = 15.0;
    
    private var _lastTouchPos:FlxPoint;
    private var _trackedTouchID:Int = -1;
    private var _cursorCamera:FlxCamera;
    private var _clickTween:FlxTween;

    public static function init():Void {
        if (instance == null) {
            instance = new VirtualCursor();
            FlxG.plugins.add(instance);
        }
    }
    
    public static function Kill():Void {
        if (instance != null) {
            FlxG.plugins.remove(instance);
            instance.destroy();
            instance = null;
        }
    }

    public function new()
    {
        super();
        
        _cursorCamera = new FlxCamera(0, 0, FlxG.width, FlxG.height);
        _cursorCamera.bgColor = FlxColor.TRANSPARENT;
        FlxG.cameras.add(_cursorCamera, false);

        cursorSprite = new FlxSprite(FlxG.width / 2, FlxG.height / 2);
        cursorSprite.loadGraphic("assets/images/menus/cursor/mouse.png");
        cursorSprite.antialiasing = true;
        cursorSprite.cameras = [_cursorCamera];
        
        _lastTouchPos = FlxPoint.get();

        #if mobile
        FlxG.mouse.visible = false;
        #end
    }

    override public function update(elapsed:Float):Void
    {
        if (FlxG.cameras.list.indexOf(_cursorCamera) < FlxG.cameras.list.length - 1) {
            FlxG.cameras.remove(_cursorCamera, false);
            FlxG.cameras.add(_cursorCamera, false);
        }

        handleTouchInput();
        
        FlxG.mouse.setGlobalScreenPositionUnsafe(cursorSprite.x, cursorSprite.y);

        super.update(elapsed);
    }

    private function handleTouchInput():Void 
    {
        var activeTouch:FlxTouch = null;

        if (_trackedTouchID != -1) {
            for (touch in FlxG.touches.list) {
                if (touch.touchPointID == _trackedTouchID) {
                    activeTouch = touch;
                    break;
                }
            }
        } else {
            for (touch in FlxG.touches.list) {
                if (touch.justPressed) {
                    activeTouch = touch;
                    _trackedTouchID = touch.touchPointID;
                    _lastTouchPos.set(touch.screenX, touch.screenY);
                    break;
                }
            }
        }

        if (activeTouch != null) {
            var dx:Float = activeTouch.screenX - _lastTouchPos.x;
            var dy:Float = activeTouch.screenY - _lastTouchPos.y;
            
            cursorSprite.x = FlxMath.bound(cursorSprite.x + dx * sensitivity, 0, FlxG.width);
            cursorSprite.y = FlxMath.bound(cursorSprite.y + dy * sensitivity, 0, FlxG.height);
            
            _lastTouchPos.set(activeTouch.screenX, activeTouch.screenY);

            if (activeTouch.justPressed) {
                handlePress();
            }
            if (activeTouch.justReleased) {
                handleRelease();
                _trackedTouchID = -1;
            }
        }
    }

    private function handlePress():Void
    {
        if (_clickTween != null) _clickTween.cancel();
        cursorSprite.scale.set(0.8, 0.8);
        @:privateAccess FlxG.mouse._leftButton.press();
    }

    private function handleRelease():Void
    {
        if (_clickTween != null) _clickTween.cancel();
        _clickTween = FlxTween.tween(cursorSprite.scale, {x: 1, y: 1}, 0.1, {ease: FlxEase.quartOut});
        @:privateAccess FlxG.mouse._leftButton.release();
    }

    override public function draw():Void {
        cursorSprite.draw();
        super.draw();
    }

    override public function destroy():Void 
    {
        FlxG.cameras.remove(_cursorCamera);
        _lastTouchPos = FlxDestroyUtil.put(_lastTouchPos);
        if (_clickTween != null) _clickTween.cancel();
        cursorSprite.destroy();
        super.destroy();
    }
}
