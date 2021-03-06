package me.feng3d.fagal.fragment
{
	import me.feng3d.core.register.Register;
	import me.feng3d.fagal.methods.FagalMethod;

	/**
	 * 法线取样函数
	 * @author warden_feng 2014-10-23
	 */
	[FagalMethod(methodType = "fragment")]
	public class F_NormalSample extends FagalMethod
	{
		[Register(regName = "normalTexture_fs", regType = "in", description = "法线纹理寄存器")]
		public var normalTexture:Register;

		[Register(regName = "uv_v", regType = "in", description = "uv变量数据")]
		public var uv:Register;

		[Register(regName = "normalTexData_ft_4", regType = "out", description = "法线纹理数据片段临时寄存器")]
		public var normalTexData:Register;

		[Register(regName = "commonsData_fc_vector", regType = "uniform", description = "公用数据片段常量数据")]
		public var commonsData:Register;

		override public function runFunc():void
		{
			//获取纹理数据
			tex(normalTexData, uv, normalTexture);
			//使法线纹理数据 【0,1】->【-0.5,0.5】
			sub(normalTexData.xyz, normalTexData.xyz, commonsData.xxx);

			//标准化法线纹理数据
			nrm(normalTexData.xyz, normalTexData.xyz);
		}
	}
}
