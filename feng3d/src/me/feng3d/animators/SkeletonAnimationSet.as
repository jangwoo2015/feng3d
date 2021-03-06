package me.feng3d.animators
{
	import me.feng3d.arcane;
	import me.feng3d.core.proxy.Stage3DProxy;
	import me.feng3d.fagal.ShaderParams;
	import me.feng3d.fagal.vertex.animation.V_SkeletonAnimationCPU;
	import me.feng3d.fagal.vertex.animation.V_SkeletonAnimationGPU;
	import me.feng3d.passes.MaterialPassBase;

	/**
	 * 骨骼动画集合
	 * @author warden_feng 2014-5-20
	 */
	public class SkeletonAnimationSet extends AnimationSet
	{
		private var _jointsPerVertex:uint;

		private var _numJoints:uint;

		/**
		 * 创建一个骨骼动画集合
		 * @param jointsPerVertex 每个顶点关联关节的数量
		 */
		public function SkeletonAnimationSet(jointsPerVertex:uint = 4)
		{
			_jointsPerVertex = jointsPerVertex;
		}

		/**
		 * 每个顶点关联关节的数量
		 */
		public function get jointsPerVertex():uint
		{
			return _jointsPerVertex;
		}

		arcane override function activate(shaderParams:ShaderParams, stage3DProxy:Stage3DProxy, pass:MaterialPassBase):void
		{
			shaderParams.numJoints = _numJoints;
			shaderParams.jointsPerVertex = _jointsPerVertex;

			if (usesCPU)
				shaderParams.animationFagalMethod = V_SkeletonAnimationCPU;
			else
				shaderParams.animationFagalMethod = V_SkeletonAnimationGPU;
		}

		public function set numJoints(value:uint):void
		{
			_numJoints = value;
		}

	}
}
