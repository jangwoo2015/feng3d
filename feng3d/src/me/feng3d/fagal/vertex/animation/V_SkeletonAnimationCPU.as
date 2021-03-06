package me.feng3d.fagal.vertex.animation
{
	import me.feng3d.core.register.Register;
	import me.feng3d.fagal.methods.FagalMethod;
	
	/**
	 * 骨骼动画渲染程序(CPU)
	 * @author warden_feng 2014-11-3
	 */
	[FagalMethod(methodType="vertex")]
	public class V_SkeletonAnimationCPU extends FagalMethod
	{
		[Register(regName = "animated_va_3", regType = "in", description = "骨骼动画计算完成后的顶点坐标数据")]
		public var animatedReg:Register;
		
		[Register(regName = "animatedPosition_vt_4", regType = "out", description = "动画后的顶点坐标数据")]
		public var animatedPosition:Register;
		
		override public function runFunc():void
		{
			mov(animatedPosition, animatedReg);
		}
	}
}