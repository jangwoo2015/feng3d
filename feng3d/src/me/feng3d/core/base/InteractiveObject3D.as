package me.feng3d.core.base
{
	import me.feng.events.FEvent;
	import me.feng3d.events.MouseEvent3D;
	
	[Event(name = "click3d", type = "me.feng3d.events.MouseEvent3D")]
	[Event(name = "mouseOver3d", type = "me.feng3d.events.MouseEvent3D")]
	[Event(name = "mouseOut3d", type = "me.feng3d.events.MouseEvent3D")]
	[Event(name = "mouseMove3d", type = "me.feng3d.events.MouseEvent3D")]
	[Event(name = "doubleClick3d", type = "me.feng3d.events.MouseEvent3D")]
	[Event(name = "mouseDown3d", type = "me.feng3d.events.MouseEvent3D")]
	[Event(name = "mouseUp3d", type = "me.feng3d.events.MouseEvent3D")]
	[Event(name = "mouseWheel3d", type = "me.feng3d.events.MouseEvent3D")]
	
	/**
	 * InteractiveObject3D 类是用户可以使用鼠标、键盘或其他用户输入设备与之交互的所有显示对象的抽象基类。
	 * @author warden_feng 2014-5-5
	 */
	public class InteractiveObject3D extends Object3D
	{
		protected var _mouseEnabled:Boolean = false;
		
		public function InteractiveObject3D()
		{
			super();
		}
		
		/**
		 * 是否开启鼠标事件
		 */
		public function get mouseEnabled():Boolean
		{
			return _mouseEnabled;
		}
		
		public function set mouseEnabled(value:Boolean):void
		{
			_mouseEnabled = value;
		}
		
		override public function dispatchEvent(event:FEvent):Boolean
		{
			//处理3D鼠标事件禁用
			if (event is MouseEvent3D && !mouseEnabled)
			{
				if (parentDispatcher)
				{
					return parentDispatcher.dispatchEvent(event);
				}
				return false;
			}
			return super.dispatchEvent(event);
		}
	}
}
