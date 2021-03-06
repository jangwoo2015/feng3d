package me.feng3d.passes
{

	import flash.geom.Matrix3D;
	
	import me.feng3d.arcane;
	import me.feng3d.cameras.Camera3D;
	import me.feng3d.core.base.IRenderable;
	import me.feng3d.core.buffer.Context3DBufferTypeID;
	import me.feng3d.core.buffer.context3d.FCVectorBuffer;
	import me.feng3d.core.buffer.context3d.VCMatrixBuffer;
	import me.feng3d.core.buffer.context3d.VCVectorBuffer;
	import me.feng3d.core.proxy.Context3DCache;
	import me.feng3d.core.proxy.Stage3DProxy;
	import me.feng3d.events.ShadingMethodEvent;
	import me.feng3d.fagal.ShaderParams;
	import me.feng3d.materials.MaterialBase;
	import me.feng3d.materials.methods.BasicAmbientMethod;
	import me.feng3d.materials.methods.BasicDiffuseMethod;
	import me.feng3d.materials.methods.BasicSpecularMethod;
	import me.feng3d.materials.methods.ShaderMethodSetup;
	import me.feng3d.textures.Texture2DBase;

	use namespace arcane;

	/**
	 * 编译通道<br/>
	 * 用于处理复杂的渲染通道
	 * @author warden_feng 2014-6-5
	 */
	public class CompiledPass extends MaterialPassBase
	{
		protected var _preserveAlpha:Boolean = true;

		protected var modelViewProjection:Matrix3D = new Matrix3D();
		protected var projectionBuffer:VCMatrixBuffer;

		protected var sceneNormalMatrix:Matrix3D = new Matrix3D();
		protected var sceneNormalMatrixBuffer:VCMatrixBuffer;

		protected var globalTransformMatrix:Matrix3D = new Matrix3D();
		protected var globalTransformMatrixBuffer:VCMatrixBuffer;

		protected var cameraProjectionMatrix:Matrix3D = new Matrix3D();
		protected var cameraProjectionMatrixBuffer:VCMatrixBuffer;

		protected var _ambientLightR:Number;
		protected var _ambientLightG:Number;
		protected var _ambientLightB:Number;

		protected var commonsData:Vector.<Number> = new Vector.<Number>(4);
		protected var commonsDataBuffer:FCVectorBuffer;

		/** 照相机位置 */
		protected var cameraPosition:Vector.<Number> = new Vector.<Number>(4);
		protected var cameraPositionBuffer:VCVectorBuffer;

		protected var _enableLightFallOff:Boolean = true;

		public function CompiledPass(material:MaterialBase)
		{
			_material = material;
			init();
		}

		private function init():void
		{
			_methodSetup = new ShaderMethodSetup(this);
			_methodSetup.addEventListener(ShadingMethodEvent.SHADER_INVALIDATED, onShaderInvalidated);
		}

		override protected function initBuffers():void
		{
			super.initBuffers();

			commonsDataBuffer = new FCVectorBuffer(Context3DBufferTypeID.COMMONSDATA_FC_VECTOR, updateCommonsDataBuffer);
			cameraPositionBuffer = new VCVectorBuffer(Context3DBufferTypeID.CAMERAPOSITION_VC_VECTOR, updateCameraPositionBuffer);
			projectionBuffer = new VCMatrixBuffer(Context3DBufferTypeID.PROJECTION_VC_MATRIX, updateProjectionBuffer);
			sceneNormalMatrixBuffer = new VCMatrixBuffer(Context3DBufferTypeID.NORMALGLOBALTRANSFORM_VC_MATRIX, updateSceneNormalMatrixBuffer);
			globalTransformMatrixBuffer = new VCMatrixBuffer(Context3DBufferTypeID.GLOBALTRANSFORM_VC_MATRIX, updateGlobalTransformMatrixBuffer);
			cameraProjectionMatrixBuffer = new VCMatrixBuffer(Context3DBufferTypeID.CAMERAPROJECTION_VC_MATRIX, updateCameraProjectionMatrixBuffer);

		}

		override public function collectCache(context3dCache:Context3DCache):void
		{
			super.collectCache(context3dCache);
			context3dCache.addDataBuffer(projectionBuffer);
			context3dCache.addDataBuffer(commonsDataBuffer);
			context3dCache.addDataBuffer(cameraPositionBuffer);
			context3dCache.addDataBuffer(sceneNormalMatrixBuffer);
			context3dCache.addDataBuffer(globalTransformMatrixBuffer);
			context3dCache.addDataBuffer(cameraProjectionMatrixBuffer);

			_methodSetup.collectCache(context3dCache);
		}

		override public function releaseCache(context3dCache:Context3DCache):void
		{
			super.releaseCache(context3dCache);

			context3dCache.removeDataBuffer(projectionBuffer);
			context3dCache.removeDataBuffer(commonsDataBuffer);
			context3dCache.removeDataBuffer(cameraPositionBuffer);
			context3dCache.removeDataBuffer(sceneNormalMatrixBuffer);
			context3dCache.removeDataBuffer(globalTransformMatrixBuffer);
			context3dCache.removeDataBuffer(cameraProjectionMatrixBuffer);

			_methodSetup.releaseCache(context3dCache);
		}

		override arcane function activate(shaderParams:ShaderParams, stage3DProxy:Stage3DProxy, camera:Camera3D):void
		{
			super.activate(shaderParams, stage3DProxy, camera);
			
			shaderParams.useLightFallOff = _enableLightFallOff;

			if (_methodSetup._normalMethod)
				_methodSetup._normalMethod.activate(shaderParams, stage3DProxy);
			_methodSetup._ambientMethod.activate(shaderParams, stage3DProxy);
			_methodSetup._diffuseMethod.activate(shaderParams, stage3DProxy);
			if (_methodSetup._specularMethod)
				_methodSetup._specularMethod.activate(shaderParams, stage3DProxy);
			
			
			_ambientLightR = _ambientLightG = _ambientLightB = 0;
			if (usesLights())
				updateLightConstants();
			
			var ambientMethod:BasicAmbientMethod = _methodSetup._ambientMethod;
			ambientMethod._lightAmbientR = _ambientLightR;
			ambientMethod._lightAmbientG = _ambientLightG;
			ambientMethod._lightAmbientB = _ambientLightB;
		}

		override arcane function render(renderable:IRenderable, stage3DProxy:Stage3DProxy, camera:Camera3D):void
		{
			//全局转换矩阵（物体坐标-->世界坐标）
			var sceneTransform:Matrix3D = renderable.sourceEntity.sceneTransform;
			//投影矩阵（世界坐标-->照相机坐标）
			var projectionmatrix:Matrix3D = camera.viewProjection;

			//物体投影转换矩阵（物体坐标系-->照相机坐标）
			modelViewProjection.identity();
			modelViewProjection.append(sceneTransform);
			modelViewProjection.append(projectionmatrix);
			projectionBuffer.invalid();

			//全局转换矩阵（物体坐标-->世界坐标）
			globalTransformMatrix.copyFrom(sceneTransform);
			globalTransformMatrixBuffer.invalid();

			//投影矩阵（世界坐标-->照相机坐标）
			cameraProjectionMatrix.copyFrom(projectionmatrix);
			cameraProjectionMatrixBuffer.invalid();

			//法线全局转换矩阵（物体坐标-->世界坐标）
			sceneNormalMatrix.copyFrom(sceneTransform);
			sceneNormalMatrixBuffer.invalid();

			//照相机世界坐标
			cameraPosition[0] = camera.scenePosition.x;
			cameraPosition[1] = camera.scenePosition.y;
			cameraPosition[2] = camera.scenePosition.z;
			cameraPosition[3] = 1;
			cameraPositionBuffer.invalid();

			_methodSetup.setRenderState(renderable, stage3DProxy, camera);
		}

		protected function updateCameraPositionBuffer():void
		{
			cameraPositionBuffer.update(cameraPosition);
		}

		protected function updateCommonsDataBuffer():void
		{
			commonsDataBuffer.update(commonsData);
		}

		/**
		 * 更新投影矩阵
		 */
		protected function updateProjectionBuffer():void
		{
			projectionBuffer.update(modelViewProjection, true);
		}

		protected function updateCameraProjectionMatrixBuffer():void
		{
			cameraProjectionMatrixBuffer.update(cameraProjectionMatrix, true);
		}

		protected function updateGlobalTransformMatrixBuffer():void
		{
			globalTransformMatrixBuffer.update(globalTransformMatrix, true);
		}

		protected function updateSceneNormalMatrixBuffer():void
		{
			sceneNormalMatrixBuffer.update(sceneNormalMatrix, true);
		}

		override arcane function updateProgramBuffer():void
		{
			reset();
			super.updateProgramBuffer();
		}

		private function reset():void
		{
			initConstantData();
		}

		private function initConstantData():void
		{
			initCommonsData();
		}

		protected function initCommonsData():void
		{
			commonsData[0] = .5;
			commonsData[1] = 0;
			commonsData[2] = 1 / 255;
			commonsData[3] = 1;
			commonsDataBuffer.invalid();
		}

		/**
		 * The method that provides the diffuse lighting contribution. Defaults to BasicDiffuseMethod.
		 */
		public function get diffuseMethod():BasicDiffuseMethod
		{
			return _methodSetup.diffuseMethod;
		}

		public function set diffuseMethod(value:BasicDiffuseMethod):void
		{
			_methodSetup.diffuseMethod = value;
		}

		/**
		 * The method that provides the specular lighting contribution. Defaults to BasicSpecularMethod.
		 */
		public function get specularMethod():BasicSpecularMethod
		{
			return _methodSetup.specularMethod;
		}

		public function set specularMethod(value:BasicSpecularMethod):void
		{
			_methodSetup.specularMethod = value;
		}

		/**
		 * The method that provides the ambient lighting contribution. Defaults to BasicAmbientMethod.
		 */
		public function get ambientMethod():BasicAmbientMethod
		{
			return _methodSetup.ambientMethod;
		}

		public function set ambientMethod(value:BasicAmbientMethod):void
		{
			_methodSetup.ambientMethod = value;
		}

		/**
		 * The normal map to modulate the direction of the surface for each texel. The default normal method expects
		 * tangent-space normal maps, but others could expect object-space maps.
		 */
		public function get normalMap():Texture2DBase
		{
			return _methodSetup._normalMethod.normalMap;
		}

		public function set normalMap(value:Texture2DBase):void
		{
			_methodSetup._normalMethod.normalMap = value;
		}

		public function get preserveAlpha():Boolean
		{
			return _preserveAlpha;
		}

		public function set preserveAlpha(value:Boolean):void
		{
			if (_preserveAlpha == value)
				return;
			_preserveAlpha = value;
			invalidateShaderProgram();
		}

		/**
		 * Whether or not to use fallOff and radius properties for lights. This can be used to improve performance and
		 * compatibility for constrained mode.
		 */
		public function get enableLightFallOff():Boolean
		{
			return _enableLightFallOff;
		}

		public function set enableLightFallOff(value:Boolean):void
		{
			if (value != _enableLightFallOff)
				invalidateShaderProgram();
			_enableLightFallOff = value;
		}

		/**
		 * Called when any method's shader code is invalidated.
		 */
		private function onShaderInvalidated(event:ShadingMethodEvent):void
		{
			invalidateShaderProgram();
		}

		/**
		 * Updates constant data render state used by the lights. This method is optional for subclasses to implement.
		 */
		protected function updateLightConstants():void
		{
			// up to subclasses to optionally implement
		}
	}
}
