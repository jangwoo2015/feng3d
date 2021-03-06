package me.feng3d.fagal.vertex.animation
{
	import me.feng3d.core.register.Register;
	import me.feng3d.core.register.RegisterVector;
	import me.feng3d.fagal.methods.FagalMethod;

	/**
	 * 骨骼动画渲染程序(GPU)
	 * @author warden_feng 2014-11-3
	 */
	[FagalMethod(methodType = "vertex")]
	public class V_SkeletonAnimationGPU extends FagalMethod
	{
		[Register(regName = "position_va_3", regType = "in", description = "顶点坐标数据")]
		public var positionReg:Register;

		[Register(regName = "jointindex_va_x", regType = "in", description = "关节索引数据寄存器")]
		public var jointindexReg:Register;

		[Register(regName = "jointweights_va_x", regType = "in", description = "关节权重数据寄存器")]
		public var JointWeightsReg:Register;

		[Register(regName = "globalmatrices_vc_vector", regType = "in", regNum = "globalmatricesLen", description = "骨骼全局变换矩阵静态数据")]
		public var globalmatricesReg:RegisterVector;

		[Register(regName = "animatedPosition_vt_4", regType = "out", description = "动画后的顶点坐标数据")]
		public var animatedPosition:Register;

		/**
		 * 骨骼全局变换矩阵静态数据寄存器长度
		 */
		public function get globalmatricesLen():int
		{
			return shaderParams.numJoints * 3;
		}

		override public function runFunc():void
		{
			var vt1:Register = getFreeTemp();
			var vt2:Register = getFreeTemp();

			comment("计算该顶点坐标通关该关节得到的x值-----------1");
			dp4(vt1.x, positionReg, globalmatricesReg.getReg1(jointindexReg.x));
			comment("计算该顶点坐标通关该关节得到的y值-----------2");
			dp4(vt1.y, positionReg, globalmatricesReg.getReg1(jointindexReg.x, 1));
			comment("计算该顶点坐标通关该关节得到的z值-----------3");
			dp4(vt1.z, positionReg, globalmatricesReg.getReg1(jointindexReg.x, 2));
			comment("w值不变-----------------4");
			mov(vt1.w, positionReg.w);
			comment("通过权重计算该关节对顶点的影响值---------------5");
			mul(vt1, vt1, JointWeightsReg.x);
			comment("vt2保存了计算后的顶点坐标，第一个关节影响值使用mov赋值，后面的关节将会使用add来累加-----------------6(1到6将会对每个与该顶点相关的关节调用，该实例中只有一个关节，所以少了个for循环)");
			mov(vt2, vt1);
			comment("赋值给顶点坐标寄存器，提供给后面投影使用");
			mov(animatedPosition, vt2);
			
			removeTemp(vt1);
			removeTemp(vt2);
		}
	}
}
