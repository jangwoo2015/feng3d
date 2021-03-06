package me.feng3d.bounds
{
	import flash.geom.Vector3D;

	import me.feng3d.core.base.Geometry;
	import me.feng3d.core.base.ISubGeometry;
	import me.feng3d.core.math.Ray3D;
	import me.feng3d.errors.AbstractMethodError;
	import me.feng3d.primitives.WireframePrimitiveBase;

	/**
	 * 边界数据
	 * @author warden_feng 2014-4-27
	 */
	public class BoundingVolumeBase
	{
		/** 最小坐标 */
		protected var _min:Vector3D;
		/** 最大坐标 */
		protected var _max:Vector3D;

		protected var _boundingRenderable:WireframePrimitiveBase;

		public function BoundingVolumeBase()
		{
			_min = new Vector3D();
			_max = new Vector3D();
		}

		/**
		 * 渲染实体
		 */
		public function get boundingRenderable():WireframePrimitiveBase
		{
			if (!_boundingRenderable)
			{
				_boundingRenderable = createBoundingRenderable();
				updateBoundingRenderable();
			}

			return _boundingRenderable;
		}

		/**
		 * 注销渲染实体
		 */
		public function disposeRenderable():void
		{
			_boundingRenderable = null;
		}

		/**
		 * 更新边界渲染实体
		 */
		protected function updateBoundingRenderable():void
		{
			throw new AbstractMethodError();
		}

		/**
		 * 创建渲染边界
		 */
		protected function createBoundingRenderable():WireframePrimitiveBase
		{
			throw new AbstractMethodError();
		}

		/**
		 * 根据几何结构更新边界
		 */
		public function fromGeometry(geometry:Geometry):void
		{
			var subGeoms:Vector.<ISubGeometry> = geometry.subGeometries;
			var numSubGeoms:uint = subGeoms.length;
			var minX:Number, minY:Number, minZ:Number;
			var maxX:Number, maxY:Number, maxZ:Number;

			if (numSubGeoms > 0)
			{
				var subGeom:ISubGeometry = subGeoms[0];
				var vertices:Vector.<Number> = subGeom.vertexData;
				var i:uint = subGeom.vertexOffset;
				minX = maxX = vertices[i];
				minY = maxY = vertices[i + 1];
				minZ = maxZ = vertices[i + 2];

				var j:uint = 0;
				while (j < numSubGeoms)
				{
					subGeom = subGeoms[j++];
					vertices = subGeom.vertexData;
					var vertexDataLen:uint = vertices.length;
					i = subGeom.vertexOffset;
					var stride:uint = subGeom.vertexStride;

					while (i < vertexDataLen)
					{
						var v:Number = vertices[i];
						if (v < minX)
							minX = v;
						else if (v > maxX)
							maxX = v;
						v = vertices[i + 1];
						if (v < minY)
							minY = v;
						else if (v > maxY)
							maxY = v;
						v = vertices[i + 2];
						if (v < minZ)
							minZ = v;
						else if (v > maxZ)
							maxZ = v;
						i += stride;
					}
				}

				fromExtremes(minX, minY, minZ, maxX, maxY, maxZ);
			}
			else
				fromExtremes(0, 0, 0, 0, 0, 0);
		}

		/**
		 * 根据所给极值设置边界
		 * @param minX 边界最小X坐标
		 * @param minY 边界最小Y坐标
		 * @param minZ 边界最小Z坐标
		 * @param maxX 边界最大X坐标
		 * @param maxY 边界最大Y坐标
		 * @param maxZ 边界最大Z坐标
		 */
		public function fromExtremes(minX:Number, minY:Number, minZ:Number, maxX:Number, maxY:Number, maxZ:Number):void
		{
			_min.x = minX;
			_min.y = minY;
			_min.z = minZ;
			_max.x = maxX;
			_max.y = maxY;
			_max.z = maxZ;
			if (_boundingRenderable)
				updateBoundingRenderable();
		}

		/**
		 * 检测射线是否与边界碰撞
		 * @param ray3D
		 * @param targetNormal
		 * @return
		 */
		public function rayIntersection(ray3D:Ray3D, targetNormal:Vector3D):Number
		{
			return -1;
		}

		/**
		 * 是否包含点
		 * @param position 某点
		 * @return
		 */
		public function containsPoint(position:Vector3D):Boolean
		{
			return false;
		}
	}
}
