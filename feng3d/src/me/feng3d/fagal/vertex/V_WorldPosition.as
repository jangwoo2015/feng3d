package me.feng3d.fagal.vertex
{
	import me.feng3d.core.register.Register;
	import me.feng3d.core.register.RegisterMatrix;
	import me.feng3d.fagal.methods.FagalMethod;

	/**
	 * 顶点世界坐标渲染函数
	 * @author warden_feng 2014-11-7
	 */
	[FagalMethod(methodType = "vertex")]
	public class V_WorldPosition extends FagalMethod
	{
		[Register(regName = "position_va_3", regType = "in", description = "顶点坐标数据")]
		public var localPositionReg:Register;

		[Register(regName = "globalPosition_vt_4", regType = "out", description = "顶点世界坐标")]
		public var positionSceneReg:Register;

		[Register(regName = "globaltransform_vc_matrix", regType = "uniform", description = "全局转换矩阵(物体坐标转世界坐标)")]
		public var positionMatrixReg:RegisterMatrix;

		override public function runFunc():void
		{
			comment("世界坐标转换");
			m44(positionSceneReg, localPositionReg, positionMatrixReg);
		}
	}
}
