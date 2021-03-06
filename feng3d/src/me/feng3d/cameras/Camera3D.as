package me.feng3d.cameras
{
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	import me.feng3d.cameras.lenses.LensBase;
	import me.feng3d.cameras.lenses.PerspectiveLens;
	import me.feng3d.core.math.Matrix3DUtils;
	import me.feng3d.entities.Entity;
	import me.feng3d.events.CameraEvent;
	import me.feng3d.events.LensEvent;
	import me.feng3d.library.assets.AssetType;

	/**
	 * 照相机
	 * @author warden_feng 2014-3-17
	 */
	public class Camera3D extends Entity
	{
		private var _viewProjection:Matrix3D = new Matrix3D();
		private var _viewProjectionDirty:Boolean = true;
		private var _lens:LensBase;

		/**
		 * 创建一个照相机
		 * @param lens 照相机镜头
		 */		
		public function Camera3D(lens:LensBase = null)
		{
			_lens = lens || new PerspectiveLens();
			_lens.addEventListener(LensEvent.MATRIX_CHANGED, onLensMatrixChanged);
		}

		public override function get assetType():String
		{
			return AssetType.CAMERA;
		}

		/**
		 * 处理镜头变化事件
		 */		
		private function onLensMatrixChanged(event:LensEvent):void
		{
			_viewProjectionDirty = true;

			dispatchEvent(event);
		}

		override protected function invalidateSceneTransform():void
		{
			super.invalidateSceneTransform();

			_viewProjectionDirty = true;
		}

		/**
		 * 镜头
		 */
		public function get lens():LensBase
		{
			return _lens;
		}

		public function set lens(value:LensBase):void
		{
			if (_lens == value)
				return;

			if (!value)
				throw new Error("Lens cannot be null!");

			_lens.removeEventListener(LensEvent.MATRIX_CHANGED, onLensMatrixChanged);

			_lens = value;

			_lens.addEventListener(LensEvent.MATRIX_CHANGED, onLensMatrixChanged);

			dispatchEvent(new CameraEvent(CameraEvent.LENS_CHANGED, this));
		}

		/**
		 * 照相机的投影矩阵
		 */
		public function get viewProjection():Matrix3D
		{
			if (_viewProjectionDirty)
			{
				_viewProjection.copyFrom(inverseSceneTransform);
				_viewProjection.append(_lens.matrix);
				_viewProjectionDirty = false;
			}

			return _viewProjection;
		}

		/**
		 * 屏幕坐标投影到场景坐标
		 * @param nX 屏幕坐标X -1（左） -> 1（右）
		 * @param nY 屏幕坐标Y -1（上） -> 1（下）
		 * @param sZ 到屏幕的距离
		 * @param v 场景坐标（输出）
		 * @return 场景坐标
		 */
		public function unproject(nX:Number, nY:Number, sZ:Number, v:Vector3D = null):Vector3D
		{
			return Matrix3DUtils.transformVector(sceneTransform, lens.unproject(nX, nY, sZ, v), v)
		}

		/**
		 * 场景坐标投影到屏幕坐标
		 * @param point3d 场景坐标
		 * @param v 屏幕坐标（输出）
		 * @return 屏幕坐标
		 */
		public function project(point3d:Vector3D, v:Vector3D = null):Vector3D
		{
			return lens.project(Matrix3DUtils.transformVector(inverseSceneTransform, point3d, v), v);
		}
	}
}
