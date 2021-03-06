package me.feng3d.core.base
{
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	import me.feng.events.FEvent;
	import me.feng3d.arcane;
	import me.feng3d.containers.ObjectContainer3D;
	import me.feng3d.containers.Scene3D;
	import me.feng3d.core.base.data.Transform3D;
	import me.feng3d.core.math.Matrix3DUtils;
	import me.feng3d.events.MouseEvent3D;
	import me.feng3d.events.Object3DEvent;

	use namespace arcane;

	/**
	 * 3D对象<br/><br/>
	 * 主要功能:
	 * <ul>
	 *     <li>能够被addChild添加到3d场景中</li>
	 *     <li>维护场景变换矩阵sceneTransform、inverseSceneTransform</li>
	 *     <li>维护父对象parent</li>
	 * </ul>
	 *
	 * @author warden_feng
	 */
	public class Object3D extends Transform3D
	{
		protected var _parent:ObjectContainer3D;

		protected var _sceneTransform:Matrix3D = new Matrix3D();
		protected var _sceneTransformDirty:Boolean = true;

		private var _inverseSceneTransform:Matrix3D = new Matrix3D();
		private var _inverseSceneTransformDirty:Boolean = true;

		private var _scenePosition:Vector3D = new Vector3D();
		private var _scenePositionDirty:Boolean = true;

		private var _visible:Boolean = true;

		private var _sceneTransformChanged:Object3DEvent;

		private var _listenToSceneTransformChanged:Boolean;

		arcane var _scene3D:Scene3D;

		/**
		 * 创建3D对象
		 */
		public function Object3D()
		{
			super();
		}

		/**
		 * 显示对象的场景
		 */
		public function get scene3D():Scene3D
		{
			return _scene3D;
		}

		/**
		 * 设置对象所在场景
		 */
		arcane function setScene3D(scene:Scene3D):void
		{
			if (_scene3D != scene)
			{
				if (_scene3D)
					_scene3D.removedObject3d(this);
				_scene3D = scene;
				if (_scene3D)
					_scene3D.addedObject3d(this);
			}
		}

		public function clone():Object3D
		{
			var clone:Object3D = new Object3D();
			clone.pivotPoint = pivotPoint;
			clone.transform = transform;
			// todo: implement for all subtypes
			return clone;
		}

		/**
		 * 从世界转换到模型空间的逆矩阵
		 */
		public function get inverseSceneTransform():Matrix3D
		{
			if (_inverseSceneTransformDirty)
			{
				_inverseSceneTransform.copyFrom(sceneTransform);
				_inverseSceneTransform.invert();
				_inverseSceneTransformDirty = false;
			}

			return _inverseSceneTransform;
		}

		/**
		 * 对象场景转换矩阵
		 */
		public function get sceneTransform():Matrix3D
		{
			if (_sceneTransformDirty)
				updateSceneTransform();
			return _sceneTransform;
		}

		/**
		 * 更新场景转换矩阵
		 * Updates the scene transformation matrix.
		 */
		protected function updateSceneTransform():void
		{
			if (_parent && !_parent._isRoot)
			{
				_sceneTransform.copyFrom(_parent.sceneTransform);
				_sceneTransform.prepend(transform);
			}
			else
				_sceneTransform.copyFrom(transform);

			_sceneTransformDirty = false;
		}

		/**
		 * 当状态变换矩阵无效时 把场景变换矩阵标记为脏数据
		 */
		override public function invalidateTransform():void
		{
			super.invalidateTransform();

			notifySceneTransformChange();
		}

		/**
		 * 场景变化失效
		 */		
		protected function invalidateSceneTransform():void
		{
			_sceneTransformDirty = true;
			_inverseSceneTransformDirty = true;
			_scenePositionDirty = true;
		}

		/**
		 * 通知场景变换改变
		 */		
		protected function notifySceneTransformChange():void
		{
			if (_sceneTransformDirty)
				return;

			//处理场景变换事件
			if (_listenToSceneTransformChanged)
			{
				if (!_sceneTransformChanged)
					_sceneTransformChanged = new Object3DEvent(Object3DEvent.SCENETRANSFORM_CHANGED, this);
				dispatchEvent(_sceneTransformChanged);
			}

			invalidateSceneTransform();
		}

		/**
		 * 父容器
		 */
		public function get parent():ObjectContainer3D
		{
			return _parent;
		}

		public function set parent(value:ObjectContainer3D):void
		{
			if (_parent != null)
				_parent.removeChild(this);

			_parent = value;

			invalidateTransform();
		}

		/**
		 * 获取场景坐标
		 */
		public function get scenePosition():Vector3D
		{
			if (_scenePositionDirty)
			{
				sceneTransform.copyColumnTo(3, _scenePosition);
				_scenePositionDirty = false;
			}

			return _scenePosition;
		}

		/**
		 * 本地坐标转换为世界坐标
		 * @param localVector3D 本地坐标
		 * @return
		 */
		public function positionLocalToGlobal(localPosition:Vector3D):Vector3D
		{
			var globalPosition:Vector3D = sceneTransform.transformVector(localPosition);
			return globalPosition;
		}

		/**
		 * 世界坐标转换为本地坐标
		 * @param globalPosition 世界坐标
		 * @return
		 */
		public function positionGlobalToLocal(globalPosition:Vector3D):Vector3D
		{
			var localPosition:Vector3D = inverseSceneTransform.transformVector(globalPosition);
			return localPosition;
		}

		/**
		 * 本地方向转换为世界方向
		 * @param localDirection 本地方向
		 * @return
		 */
		public function directionLocalToGlobal(localDirection:Vector3D):Vector3D
		{
			var globalDirection:Vector3D = sceneTransform.deltaTransformVector(localDirection);
			Matrix3DUtils.deltaTransformVector(sceneTransform, localDirection, globalDirection);
			return globalDirection;
		}

		/**
		 * 世界方向转换为本地方向
		 * @param globalDirection 世界方向
		 * @return
		 */
		public function directionGlobalToLocal(globalDirection:Vector3D):Vector3D
		{
			var localDirection:Vector3D = inverseSceneTransform.deltaTransformVector(globalDirection);
			Matrix3DUtils.deltaTransformVector(inverseSceneTransform, globalDirection, localDirection);
			return localDirection;
		}

		override public function dispatchEvent(event:FEvent):Boolean
		{
			if (event is MouseEvent3D && parent && !parent.ancestorsAllowMouseEnabled)
			{
				if (parentDispatcher)
				{
					return parentDispatcher.dispatchEvent(event);
				}
				return false;
			}
			return super.dispatchEvent(event);
		}

		/**
		 * 是否隐藏
		 */
		public function get visible():Boolean
		{
			return _visible;
		}

		public function set visible(value:Boolean):void
		{
			_visible = value;
		}

		/**
		 * 是否在场景上可见
		 */
		public function get sceneVisible():Boolean
		{
			//从这里开始一直找父容器到场景了，且visible全为true则为场景上可见
			return visible && ((parent is Scene3D) ? true : (parent ? parent.sceneVisible : false));
		}

		override public function addEventListener(type:String, listener:Function):void
		{
			super.addEventListener(type, listener);

			switch (type)
			{
				case Object3DEvent.SCENETRANSFORM_CHANGED:
					_listenToSceneTransformChanged = true;
					break;
//				case Object3DEvent.SCENE_CHANGED:
//					_listenToSceneChanged = true;
//					break;
			}
		}

		override public function removeEventListener(type:String, listener:Function):void
		{
			super.removeEventListener(type, listener);

			if (hasEventListener(type))
				return;

			switch (type)
			{
				case Object3DEvent.SCENETRANSFORM_CHANGED:
					_listenToSceneTransformChanged = false;
					break;
//				case Object3DEvent.SCENE_CHANGED:
//					_listenToSceneChanged = false;
//					break;
			}
		}

	}
}
