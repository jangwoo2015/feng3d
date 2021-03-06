package me.feng3d.fagal.vertex
{
	import me.feng3d.core.register.Register;
	import me.feng3d.fagal.methods.FagalMethod;

	/**
	 * 视线顶点渲染函数
	 * @author warden_feng 2014-11-7
	 */
	[FagalMethod(methodType = "vertex")]
	public class V_ViewDir extends FagalMethod
	{
		[Register(regName = "globalPosition_vt_4", regType = "in", description = "顶点世界坐标")]
		public var globalPositionReg:Register;

		[Register(regName = "viewDir_v", regType = "out", description = "视线变量寄存器")]
		public var viewDirVaryingReg:Register;

		[Register(regName = "cameraposition_vc_vector", regType = "uniform", description = "照相机世界坐标")]
		public var cameraPositionReg:Register;

		override public function runFunc():void
		{
			comment("计算视线方向");
			sub(viewDirVaryingReg, cameraPositionReg, globalPositionReg);
		}

	}
}
