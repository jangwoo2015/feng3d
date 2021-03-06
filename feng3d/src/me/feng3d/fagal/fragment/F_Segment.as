package me.feng3d.fagal.fragment
{
	import me.feng3d.core.register.Register;
	import me.feng3d.fagal.methods.FagalMethod;

	/**
	 * 线段片段渲染程序
	 * @author warden_feng 2014-10-28
	 */
	[FagalMethod(methodType = "fragment")]
	public class F_Segment extends FagalMethod
	{
		[Register(regName = "color_v", regType = "in", description = "颜色变量寄存器")]
		public var color_v:Register;

		[Register(regName = "oc", regType = "out", description = "颜色输出寄存器")]
		public var out:Register;

		override public function runFunc():void
		{
			comment("传递顶点颜色数据" + color_v + "到片段寄存器" + out);
			mov(out, color_v);
		}
	}
}
