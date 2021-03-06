package me.feng3d.fagal.vertex
{
	import me.feng3d.core.register.Register;
	import me.feng3d.core.register.RegisterMatrix;
	import me.feng3d.fagal.methods.FagalMethod;

	/**
	 * 线段顶点渲染程序
	 * @author warden_feng 2014-10-28
	 */
	[FagalMethod(methodType = "vertex")]
	public class V_Segment extends FagalMethod
	{
		[Register(regName = "segmentStart_va_3", regType = "in", description = "起点坐标寄存器")]
		public var startPositionReg:Register;

		[Register(regName = "segmentEnd_va_3", regType = "in", description = "终点坐标寄存器")]
		public var endPositionReg:Register;

		[Register(regName = "segmentThickness_va_1", regType = "in", description = "线段厚度寄存器")]
		public var thicknessReg:Register;

		[Register(regName = "segmentColor_va_4", regType = "in", description = "顶点颜色寄存器")]
		public var colorReg:Register;

		[Register(regName = "segmentC2pMatrix_vc_matrix", regType = "uniform", description = "照相机坐标系到投影坐标系变换矩阵寄存器")]
		public var c2pMatrixReg:RegisterMatrix;

		[Register(regName = "segmentM2cMatrix_vc_matrix", regType = "uniform", description = "模型坐标系到照相机坐标系变换矩阵寄存器")]
		public var m2cMatrixReg:RegisterMatrix;

		[Register(regName = "segmentOne_vc_vector", regType = "uniform", description = "常数1寄存器")]
		public var oneReg:Register;

		[Register(regName = "segmentFront_vc_vector", regType = "uniform", description = "常数前向量寄存器")]
		public var frontReg:Register;

		[Register(regName = "segmentConstants_vc_vector", regType = "uniform", description = "常数寄存器")]
		public var constantsReg:Register;

		[Register(regName = "color_v", regType = "out", description = "颜色变量寄存器")]
		public var color_v:Register;

		[Register(regName = "op", regType = "out", description = "位置输出寄存器")]
		public var out:Register;

		override public function runFunc():void
		{
			var cStartPosReg:Register = getFreeTemp("照相机空间起点坐标");
			var cEndPosReg:Register = getFreeTemp("照相机空间终点坐标");
			var lenghtReg:Register = getFreeTemp("线段长度");
			var temp3:Register = getFreeTemp("");
			var temp4:Register = getFreeTemp("");
			var temp5:Register = getFreeTemp("");

			comment("计算相机坐标系起点位置、终点位置、线段距离");
			m44(cStartPosReg, startPositionReg, m2cMatrixReg);
			m44(cEndPosReg, endPositionReg, m2cMatrixReg);
			sub(lenghtReg, cEndPosReg, cStartPosReg);

			// test if behind camera near plane
			// if 0 - Q0.z < Camera.near then the point needs to be clipped
			//"neg "+temp5+".x, "+temp0+".z				\n" + // 0 - Q0.z
			slt(temp5.x, cStartPosReg.z, constantsReg.z); // behind = ( 0 - Q0.z < -Camera.near ) ? 1 : 0
			sub(temp5.y, oneReg.x, temp5.x); // !behind = 1 - behind

			// p = point on the plane (0,0,-near)
			// n = plane normal (0,0,-1)
			// D = Q1 - Q0
			// t = ( dot( n, ( p - Q0 ) ) / ( dot( n, d )

			// solve for t where line crosses Camera.near
			add(temp4.x, cStartPosReg.z, constantsReg.z); // Q0.z + ( -Camera.near )
			sub(temp4.y, cStartPosReg.z, cEndPosReg.z); // Q0.z - Q1.z

			// fix divide by zero for horizontal lines
			seq(temp4.z, temp4.y, frontReg.x); // offset = (Q0.z - Q1.z)==0 ? 1 : 0
			add(temp4.y, temp4.y, temp4.z); // ( Q0.z - Q1.z ) + offset

			div(temp4.z, temp4.x, temp4.y); // t = ( Q0.z - near ) / ( Q0.z - Q1.z )

			mul(temp4.xyz, temp4.zzz, lenghtReg.xyz); // t(L)
			add(temp3.xyz, cStartPosReg.xyz, temp4.xyz); // Qclipped = Q0 + t(L)
			mov(temp3.w, oneReg.x); // Qclipped.w = 1

			// If necessary, replace Q0 with new Qclipped
			mul(cStartPosReg, cStartPosReg, temp5.yyyy); // !behind * Q0
			mul(temp3, temp3, temp5.xxxx); // behind * Qclipped
			add(cStartPosReg, cStartPosReg, temp3); // newQ0 = Q0 + Qclipped

			// calculate side vector for line
			sub(lenghtReg, cEndPosReg, cStartPosReg); // L = Q1 - Q0
			nrm(lenghtReg.xyz, lenghtReg.xyz); // normalize( L )
			nrm(temp5.xyz, cStartPosReg.xyz); // D = normalize( Q1 )
			mov(temp5.w, oneReg.x); // D.w = 1
			crs(temp3.xyz, lenghtReg, temp5); // S = L x D
			nrm(temp3.xyz, temp3.xyz); // normalize( S )

			// face the side vector properly for the given point
			mul(temp3.xyz, temp3.xyz, thicknessReg.xxx); // S *= weight
			mov(temp3.w, oneReg.x); // S.w = 1

			// calculate the amount required to move at the point's distance to correspond to the line's pixel width
			// scale the side vector by that amount
			dp3(temp4.x, cStartPosReg, frontReg); // distance = dot( view )
			mul(temp4.x, temp4.x, constantsReg.x); // distance *= vpsod
			mul(temp3.xyz, temp3.xyz, temp4.xxx); // S.xyz *= pixelScaleFactor

			// add scaled side vector to Q0 and transform to clip space
			add(cStartPosReg.xyz, cStartPosReg.xyz, temp3.xyz); // Q0 + S

			m44(out, cStartPosReg, c2pMatrixReg); // transform Q0 to clip space

			// interpolate color
			mov(color_v, colorReg);
		}
	}
}
