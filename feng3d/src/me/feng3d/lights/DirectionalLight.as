package me.feng3d.lights
{
	import flash.geom.Vector3D;

	/**
	 *
	 * @author warden_feng 2014-9-11
	 */
	public class DirectionalLight extends LightBase
	{
		private var _direction:Vector3D;
		private var _tmpLookAt:Vector3D;
		private var _sceneDirection:Vector3D;

		public function DirectionalLight()
		{
			super();

			_sceneDirection = new Vector3D();
		}

		/**
		 * 灯光方向
		 */
		public function get direction():Vector3D
		{
			return _direction;
		}

		public function set direction(value:Vector3D):void
		{
			_direction = value;
			//lookAt(new Vector3D(x + _direction.x, y + _direction.y, z + _direction.z));
			if (!_tmpLookAt)
				_tmpLookAt = new Vector3D();
			_tmpLookAt.x = x + _direction.x;
			_tmpLookAt.y = y + _direction.y;
			_tmpLookAt.z = z + _direction.z;

			lookAt(_tmpLookAt);
		}

		/**
		 * 灯光场景方向
		 */
		public function get sceneDirection():Vector3D
		{
			if (_sceneTransformDirty)
				updateSceneTransform();
			return _sceneDirection;
		}

		override protected function updateSceneTransform():void
		{
			super.updateSceneTransform();
			sceneTransform.copyColumnTo(2, _sceneDirection);
			_sceneDirection.normalize();
		}
	}
}
