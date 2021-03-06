package me.feng3d.fagal.vertex.animation
{
	import me.feng3d.core.register.Register;
	import me.feng3d.fagal.methods.FagalMethod;

	/**
	 * 顶点动画渲染程序(GPU)
	 * @author warden_feng 2014-11-3
	 */
	[FagalMethod(methodType = "vertex")]
	public class V_VertexAnimationGPU extends FagalMethod
	{
		[Register(regName = "position0_va_3", regType = "in", description = "顶点动画第0个坐标数据")]
		public var p0:Register;

		[Register(regName = "position1_va_3", regType = "in", description = "顶点动画第1个坐标数据")]
		public var p1:Register;

		[Register(regName = "weights_vc_vector", regType = "uniform", description = "顶点程序权重向量静态数据")]
		public var weight:Register;

		[Register(regName = "animatedPosition_vt_4", regType = "out", description = "动画后的顶点坐标数据")]
		public var animatedPosition:Register;

		override public function runFunc():void
		{
			var tempVts0:Register = getFreeTemp();
			var tempVts1:Register = getFreeTemp();

//			comment("计算第0个顶点混合值");
			mul(tempVts0, p0, weight.x);
//			comment("计算第1个顶点混合值");
			mul(tempVts1, p1, weight.y);
//			comment("混合两个顶点");
			add(animatedPosition, tempVts0, tempVts1);
			
			removeTemp(tempVts0);
			removeTemp(tempVts1);
		}
	}
}
