package me.feng3d.entities
{
	import me.feng3d.arcane;
	import me.feng3d.animators.Animator;
	import me.feng3d.animators.VertexAnimator;
	import me.feng3d.cameras.Camera3D;
	import me.feng3d.core.base.Geometry;
	import me.feng3d.core.base.IMaterialOwner;
	import me.feng3d.core.base.ISubGeometry;
	import me.feng3d.core.base.subgeometry.SubGeometry;
	import me.feng3d.core.base.subgeometry.VertexSubGeometry;
	import me.feng3d.core.base.submesh.SubMesh;
	import me.feng3d.core.proxy.Stage3DProxy;
	import me.feng3d.events.GeometryEvent;
	import me.feng3d.library.assets.AssetType;
	import me.feng3d.materials.MaterialBase;
	import me.feng3d.utils.DefaultMaterialManager;
	import me.feng3d.utils.GeomUtil;

	use namespace arcane;

	/**
	 * 网格
	 * @author warden_feng 2014-4-9
	 */
	public class Mesh extends Entity implements IMaterialOwner
	{
		protected var _subMeshes:Vector.<SubMesh>;

		protected var _geometry:Geometry;

		protected var _material:MaterialBase;

		protected var _animator:Animator;

		/**
		 * 新建网格
		 * @param geometry 几何体
		 * @param material 材质
		 */
		public function Mesh(geometry:Geometry = null, material:MaterialBase = null)
		{
			super();
			_subMeshes = new Vector.<SubMesh>();

			this.geometry = geometry || new Geometry();

			this.material = material || DefaultMaterialManager.getDefaultMaterial();
		}

		public function set geometry(value:Geometry):void
		{
			var i:uint;

			if (_geometry)
			{
				_geometry.removeEventListener(GeometryEvent.BOUNDS_INVALID, onGeometryBoundsInvalid);
				_geometry.removeEventListener(GeometryEvent.SUB_GEOMETRY_ADDED, onSubGeometryAdded);
				_geometry.removeEventListener(GeometryEvent.SUB_GEOMETRY_REMOVED, onSubGeometryRemoved);

				for (i = 0; i < _subMeshes.length; ++i)
					_subMeshes[i].dispose();
				_subMeshes.length = 0;
			}

			_geometry = value;

			if (_geometry)
			{
				_geometry.addEventListener(GeometryEvent.BOUNDS_INVALID, onGeometryBoundsInvalid);
				_geometry.addEventListener(GeometryEvent.SUB_GEOMETRY_ADDED, onSubGeometryAdded);
				_geometry.addEventListener(GeometryEvent.SUB_GEOMETRY_REMOVED, onSubGeometryRemoved);

				var subGeoms:Vector.<ISubGeometry> = _geometry.subGeometries;

				for (i = 0; i < subGeoms.length; ++i)
					addSubMesh(subGeoms[i]);
			}

			invalidateBounds();
		}

		/** 几何形状 */
		public function get geometry():Geometry
		{
			return _geometry;
		}

		/** 材质 */
		public function get material():MaterialBase
		{
			return _material;
		}

		public function set material(value:MaterialBase):void
		{
			_material = value;
			var len:int = _subMeshes.length;
			for (var i:int = 0; i < len; ++i)
			{
				var subMesh:SubMesh = _subMeshes[i];
				subMesh.parentMaterial = material;
			}
		}

		public function get sourceEntity():Entity
		{
			return this;
		}

		override protected function updateBounds():void
		{
			_bounds.fromGeometry(geometry);
			_boundsInvalid = false;
		}

		override arcane function collidesBefore(shortestCollisionDistance:Number, findClosest:Boolean):Boolean
		{
			_pickingCollider.setLocalRay(_pickingCollisionVO.localRay);
			_pickingCollisionVO.renderable = null;

			var len:int = _subMeshes.length;
			for (var i:int = 0; i < len; ++i)
			{
				var subMesh:SubMesh = _subMeshes[i];
				//var ignoreFacesLookingAway:Boolean = _material ? !_material.bothSides : true;
				if (_pickingCollider.testSubMeshCollision(subMesh, _pickingCollisionVO, shortestCollisionDistance))
				{
					shortestCollisionDistance = _pickingCollisionVO.rayEntryDistance;
					_pickingCollisionVO.renderable = subMesh;
					if (!findClosest)
						return true;
				}
			}

			return _pickingCollisionVO.renderable != null;
		}

		public function get animator():Animator
		{
			return _animator;
		}

		public function set animator(value:Animator):void
		{
			_animator = value;
			
			var i:int;
			if (value is VertexAnimator)
			{
				var oldGeometry:Geometry = geometry;

				var oldSubGeometry:SubGeometry;
				var newSubGeometry:VertexSubGeometry;
				geometry = new Geometry();
				for (i = 0; i < oldGeometry.subGeometries.length; i++)
				{
					oldSubGeometry = oldGeometry.subGeometries[i] as SubGeometry;
					newSubGeometry = new VertexSubGeometry();
					GeomUtil.copyDataSubGeom(oldSubGeometry, newSubGeometry);
					newSubGeometry.updateVertexData0(oldSubGeometry.vertexData.concat());
					newSubGeometry.updateVertexData1(oldSubGeometry.vertexData.concat());
					geometry.addSubGeometry(newSubGeometry);
				}
			}
			
			for (i = 0; i < subMeshes.length; i++)
			{
				var subMesh:SubMesh = subMeshes[i];
				subMesh.animator = _animator;
			}
		}

		public function get subMeshes():Vector.<SubMesh>
		{
			return _subMeshes;
		}

		protected function addSubMesh(subGeometry:ISubGeometry):void
		{
			var subMesh:SubMesh = new SubMesh(subGeometry, this, null);
			var len:uint = _subMeshes.length;
			subMesh._index = len;
			_subMeshes[len] = subMesh;
			invalidateBounds();
		}
		
		private function onGeometryBoundsInvalid(event:GeometryEvent):void
		{
			invalidateBounds();
		}

		private function onSubGeometryAdded(event:GeometryEvent):void
		{
			addSubMesh(event.subGeometry);
		}

		private function onSubGeometryRemoved(event:GeometryEvent):void
		{
			var subMesh:SubMesh;
			var subGeom:ISubGeometry = event.subGeometry;
			var len:int = _subMeshes.length;
			var i:uint;

			// Important! This has to be done here, and not delayed until the
			// next render loop, since this may be caused by the geometry being
			// rebuilt IN THE RENDER LOOP. Invalidating and waiting will delay
			// it until the NEXT RENDER FRAME which is probably not desirable.

			for (i = 0; i < len; ++i)
			{
				subMesh = _subMeshes[i];
				if (subMesh.subGeometry == subGeom)
				{
					subMesh.dispose();
					_subMeshes.splice(i, 1);
					break;
				}
			}

			--len;
			for (; i < len; ++i)
				_subMeshes[i]._index = i;
		}

		public override function get assetType():String
		{
			return AssetType.MESH;
		}

		override public function render(stage3DProxy:Stage3DProxy, camera:Camera3D):void
		{
			if (subMeshes == null)
				return;
			for (var i:int = 0; i < subMeshes.length; i++)
			{
				var subMesh:SubMesh = subMeshes[i];

				subMesh.render(stage3DProxy, camera);
			}
		}
	}
}
