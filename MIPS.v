//MIPS processor module
module mips(input         clk, reset, 
				output [31:0] rd2D, aluoutM, //writedata, dataadr 
				output        memwriteD, //memwriteD = memwrite
				input  [ 4:0] dispSel,
				output [31:0] dispDat, pcF, instrF);//instrF = instr, //pcF = pc

	wire 		memtoregD, alusrcD, regdstD, regwriteD;
	wire		wlhD, memloD, memhiD, jalD;
	wire		memtoregE, memwriteE, alusrcE, regdstE, regwriteE,  wlhE, memloE, memhiE,  jalE;
	wire		regwriteM, memtoregM, memwriteM, wlhM, memloM, memhiM,  jalM;
	wire		regwriteW, memtoregW, memloW, memhiW, jalW;
	wire[2:0] 	alucontrolD, alucontrolE;
	wire[4:0]	resultAddW, rsE, rtE,rdE, writeregE, writeregM, writeregW;
	wire[31:0] 	resultW, pcplus4F, pcplus4D, instrD, rd1D, pcnextD;
	wire[31:0]	rd1E, rd2E,pcplus4E, signimmD, signimmE, aluoutE, loE, hiE;
	wire[31:0]	rd2M, loM, hiM, pcplus4M,readataM, loMout, hiMout;
	wire[31:0]	aluoutW, readataW, loW, hiW, pcplus4W;
	
	//Fetch state
	flopr #(32) pcreg(clk, reset, pcnextD,
					  pcF);
	fetch fetch (pcF, 
				 pcplus4F, instrF);
	
	//decode state
	flopr #(64) Dreg (clk, reset, {pcplus4F, instrF},
					  {pcplus4D, instrD});
	decode decode (clk, pcplus4F, pcplus4D, instrD, resultW,//32
				   resultAddW, //5
				   regwriteW, //1 - input
				   memtoregD, memwriteD, alusrcD, regdstD, regwriteD, wlhD, memloD, memhiD, jalD, //1
				   alucontrolD, //3
				   rd1D, rd2D, signimmD, pcnextD,//32
				   dispSel, dispDat); //testing
	
	//Excute state
	flopr #(155) Ereg (clk, reset, {memtoregD, memwriteD, alusrcD, regdstD, regwriteD,  wlhD, memloD, memhiD,  jalD, //1 => 9
								   alucontrolD,  //3
								   instrD[25:21], instrD[20:16], instrD[15:11],//5 bit - rsD, rtD,rdD, => 5*3 = 15
								   rd1D, rd2D, signimmD, pcplus4D}, //32 => 32*4 = 128 => 128+9+3+15=155
					  {memtoregE, memwriteE, alusrcE, regdstE, regwriteE,  wlhE, memloE, memhiE,  jalE, //1
						alucontrolE,  //3
						rsE, rtE,rdE, //5
						rd1E, rd2E, signimmE, pcplus4E}); //32
	excute	excute	(regdstE, alusrcE, //1
					 alucontrolE, //3
					 rtE, rdE, //5
					 rd1E, rd2E, signimmE, //32 - input
					 writeregE, //5
					 aluoutE, loE, hiE); //32 - output
	
	//Memory state
	flopr #(172) Mreg (clk, reset, {regwriteE, memtoregE, memwriteE, wlhE, memloE, memhiE,  jalE, //1 => 7
								 writeregE, //5
								 aluoutE, rd2E, loE, hiE, pcplus4E}, //32 => 32*5=160 => 160+7+5=172
								{regwriteM, memtoregM, memwriteM, wlhM, memloM, memhiM,  jalM, //1 => 7
								 writeregM, //5
								 aluoutM, rd2M, loM, hiM, pcplus4M});//32
	memory	memory	(clk, memwriteM, wlhM, //1
					 aluoutM, rd2M, loM, hiM, //32 - input
					 readataM, loMout, hiMout);//32 - output
	
	//Write back state
	flopr #(170)	Wreg (clk, reset, {regwriteM, memtoregM, memloM, memhiM, jalM, //1 => 5
									writeregM, //5
									aluoutM, readataM, loMout, hiMout, pcplus4M}, //32 => 32*5=160 => 160+5+5 = 170
								   {regwriteW, memtoregW, memloW, memhiW, jalW, //1 => 5
									writeregW, //5
									aluoutW, readataW, loW, hiW, pcplus4W});//32
	writeback writeback (memtoregW, memloW, memhiW, jalW, //1
						 writeregW, //5
						 aluoutW, readataW, loW, hiW, pcplus4W, //32 - input
						 resultAddW, //5
						 resultW);//32 - output

endmodule

//module MIPS/writeback
module writeback (input 	  memtoregW, memloW, memhiW, jalW, //1
				  input[4:0]  writeregW, //5
				  input[31:0] aluoutW, readataW, loW, hiW, pcplus4W, //32 - input
				  output[4:0] resultAddW, //5
				  output[31:0]resultW);//32 - output
				  
	wire[31:0]	result1W, result2W, result3W;
				  
	mux2 #(5)	wrmux1(writeregW, 5'b11111, jalW, resultAddW);
	mux2 #(32)	resmux(aluoutW, readataW, memtoregW, result1W);	
	mux2 #(32)	resmux1(result1W, loW, memloW, result2W);
	mux2 #(32)	resmux2(result2W, hiW, memhiW, result3W);
	mux2 #(32)	resmux3(result3W, pcplus4W, jalW, resultW);	
	
endmodule	
					 
//module MIPS/memory
module	memory	(input 		 clk, memwriteM, wlhM, //1
				 input[31:0] aluoutM, rd2M, loM, hiM, //32 - input
				 output[31:0]readdataM, loMout, hiMout);//32 - output
	
	dmem dmem(clk, memwriteM, aluoutM, rd2M, readdataM);
	dreg loreg(clk,loM,wlhM,loMout);
	dreg hireg(clk,hiM,wlhM,hiMout);
	 
endmodule

//module MIPS/memory/dreg
module dreg (input				clk,
				 input[31:0]		in,
				 input 				we,
				 output reg[31:0]	out);
				 
	always @(posedge clk)
	begin
		if (we) out <= in;
		else       out <= out;
	end
	
endmodule

//module MIPS/memory/dmem
module dmem (input		 clk,
			 input		 we,
			 input[31:0] addr,
			 input[31:0] dIn,
			 output[31:0]dOut );
	
	reg		[31:0]	ram[63:0];
	integer			n;
	
	//initialize ram to all FFs
	initial 
		for (n=0; n<64; n=n+1)
			ram[n] = 8'hFF;
		
	assign dOut = ram[addr[31:2]];
				
	always @(posedge clk)
		if (we) 
			ram[addr[31:2]] = dIn; 
endmodule

//module MIPS/excute
module excute	(input 		 regdstE, alusrcE, //1
				 input[2:0]	 alucontrolE, //3
				 input[4:0]	 rtE, rdE, //5
				 input[31:0] rd1E, rd2E, signimmE, //32 - input
				 output[4:0] writeregE, //5
				 output[31:0]aluoutE, loE, hiE); //32 - output
	
	wire zero; //ignored because we have equal module for branch
	wire[31:0]	srcbE;
	
	mux2 #(32)	srcbmux(rd2E, signimmE, alusrcE, srcbE);
	alu			alu(rd1E, srcbE, alucontrolE, aluoutE, zero);
	mul			mul(rd1E, rd2E, loE, hiE);			 
	mux2 #(5)	wrmux(rtE, rdE, regdstE, writeregE);
	
endmodule

//module MIPS/excute/mux2
module mux2 #(parameter WIDTH = 8)
	(input	[WIDTH-1:0]	d0, d1, 
	 input				s, 
	 output	[WIDTH-1:0]	y );

	assign y = s ? d1 : d0; 
endmodule

//module MIPS/excute/alu
module alu(input[31:0]		a, b, 
		   input[ 2:0]		alucont, 
		   output reg[31:0]	result,
		   output			zero );

	wire	[31:0]	b2, sum, slt;

	assign b2 = alucont[2] ? ~b:b; 
	assign sum = a + b2 + alucont[2];
	assign slt = sum[31];

	always@(*)
		case(alucont[1:0])
			2'b00: result <= a & b;
			2'b01: result <= a | b;
			2'b10: result <= sum;
			2'b11: result <= slt;
		endcase

	assign zero = (result == 32'b0);
endmodule


//module MIPS/excute/mul
module mul (input[31:0]		srca, srcb, 
				output[31:0]	lo, hi);

assign {hi,lo} = srca * srcb;
endmodule

//module MIPS/flopr
module flopr #(parameter WIDTH = 8) 
	(input					clk, reset,
	 input[WIDTH-1:0]		d, 
	 output reg	[WIDTH-1:0]	q);

	always @(posedge clk, posedge reset)
		if (reset) q <= 0;
		else       q <= d;
endmodule

//module MIPS/fetch
module fetch(input 	[31:0]pc, 
			 output	[31:0]pcplus4F, instr);
	
	imem 	imem(pc[7:2], instr);			 
	adder   pcadd1(pc, 32'b100, pcplus4F);		 
			 
endmodule

//module MIPS/fetch/imem
module imem (input[ 5:0]	a,
			 output[31:0]	dOut );
	
	reg		[31:0]	rom[0:63];
	
	//initialize rom from instruction.dat
	initial 
		$readmemh("instruction.dat", rom);
	
	//simple rom
    assign dOut = rom[a];
endmodule

//module MIPS/fetch/adder
module adder(
	input	[31:0]	a, b,
	output	[31:0]	y );

	assign y = a + b;
endmodule

//module MIPS/decode
module decode (input	clk,
			   input[31:0]	pcplus4F, pcplus4D, instrD, resultW,//32
			   input[4:0]   resultAddW, //5
			   input		regwriteW, //1 - input
			   output		memtoregD, memwriteD, alusrcD, regdstD, regwriteD,
							wlhD, memloD, memhiD, jalD, //1
			   output[2:0]  alucontrolD, //3
			   output[31:0] rd1D, rd2D, signimmD, pcnextD, //32 - output
			   input[4:0] 	dispSel,
			   output[31:0] dispDat);
			   
	wire[31:0] signimmDsh, pcnextbrD, pcjumpD, pcbranchD;
	wire	pcsrcD, jumpD, jraD;
	
	
	controller controller(instrD[31:26], instrD[5:0], zero,
						  memtoregD, memwriteD, pcsrcD,
						  alusrcD, regdstD, regwriteD, jumpD,
						  alucontrolD,wlhD, memloD, memhiD, jraD, jalD);
	equal	equal (rd1D, rd2D, zero);
	regfile	rf	  (clk, regwriteW, instrD[25:21], instrD[20:16], resultAddW, resultW, rd1D, rd2D, dispSel, dispDat);
	signext	se	  (instrD[15:0], signimmD);
	sl2     immsh (signimmD, signimmDsh);
	adder   pcadd2(pcplus4D, signimmDsh, pcbranchD);

	mux2 #(32)  pcbrmux(pcplus4F, pcbranchD, pcsrcD, pcnextbrD);
	mux2 #(32)  pcjmux(pcnextbrD, {pcplus4D[31:28], instrD[25:0], 2'b00}, jumpD, pcjumpD);
	mux2 #(32)	pcmux(pcjumpD, rd1D, jraD, pcnextD);
	
endmodule

//module MIPS/decode/sl2
module sl2(
	input	[31:0]	a,
	output	[31:0]	y );

	// shift left by 2
	assign y = {a[29:0], 2'b00};
endmodule

//module MIPS/decode/signext
module signext(input[15:0]	a,
			   output[31:0]	y );

	assign y = {{16{a[15]}}, a};
endmodule

//module MIPS/decode/regfile
module regfile
	(input			clk, 
	 input			we3, 
	 input[ 4:0]	ra1, ra2, wa3, 
	 input[31:0] 	wd3, 
	 output[31:0] 	rd1, rd2,
	 input[ 4:0] 	ra4,
	 output[31:0] 	rd4);

	reg[31:0]	rf[31:0];
	integer			n;
	
	//initialize registers to all 0s
	initial 
		for (n=0; n<32; n=n+1) 
			rf[n] = 32'h00;
			
	//write first order, include logic to handle special case of $0
    always @(negedge clk)
        if (we3)
			if (~ wa3[4])
				rf[{0,wa3[3:0]}] <= wd3;
			else
				rf[{1,wa3[3:0]}] <= wd3;
		
			// this leads to 72 warnings
			//rf[wa3] <= wd3;
			
			// this leads to 8 warnings
			//if (~ wa3[4])
			//	rf[{0,wa3[3:0]}] <= wd3;
			//else
			//	rf[{1,wa3[3:0]}] <= wd3;
		
	assign rd1 = (ra1 != 0) ? rf[ra1[4:0]] : 0;
	assign rd2 = (ra2 != 0) ? rf[ra2[4:0]] : 0;
	assign rd4 = (ra4 != 0) ? rf[ra4[4:0]] : 0;
endmodule

//module MIPS/decode/equal
module equal (input[31:0] rd1, rd2,
			  output	  zero);

	assign zero = (rd1 == rd2)? 1: 0;
			  
endmodule

//module MIPS/decode/Controller 
module controller(input	[5:0]	op, funct,
				  input			zero,
				  output		memtoreg, memwrite, pcsrc,
								alusrc, regdst, regwrite, jump,
				  output[2:0]	alucontrol,
				  output		wlh, memlo, memhi, jra, jal);

	wire	[1:0]	aluop;
	wire			branch;

	maindec	md(op, memtoreg, memwrite, branch, alusrc, regdst, regwrite, jump, aluop,
					wlh, memlo, memhi, jra, jal, funct);
	aludec	ad(funct, aluop, alucontrol);

	assign pcsrc = branch & zero;
endmodule

//module MIPS/decode/Controller/main-decoder
module maindec(input[ 5:0]	op,
			   output		memtoreg, memwrite, branch, alusrc, regdst, regwrite, jump,
			   output[ 1:0]	aluop,
				output		wlh, memlo, memhi, jra, jal,
				input	[5:0]	funct);

	reg 	[13:0]	controls;

	assign {regwrite, regdst, alusrc, branch, memwrite, memtoreg, jump, aluop,wlh, memlo, memhi, jra,jal} = controls;

	always @(*)
		case(op)
			6'b000000: 
			begin
				case(funct)
					6'b011001: controls <= 14'b00000000010000;//multu
					6'b010000: controls <= 14'b11000000000100;//mfhi
					6'b010010: controls <= 14'b11000000001000;//mflo
					6'b001000: controls <= 14'b00000000000010;//jr
					default: controls <= 14'b11000001000000; //Rtype
				endcase
			end
			6'b100011: controls <= 14'b10100100000000; //LW
			6'b101011: controls <= 14'b00101000000000; //SW
			6'b000100: controls <= 14'b00010000100000; //BEQ
			6'b001000: controls <= 14'b10100000000000; //ADDI
			6'b000010: controls <= 14'b00000010000000; //J
			6'b000011: controls <= 14'b10000010000001; //jal
			default:   controls <= 14'bxxxxxxxxxxxxxx; //???
		endcase
endmodule

//module MIPS/decode/Controller/alu-decoder
module aludec(input	[5:0]	funct,
			  input	[1:0]	aluop,
			  output reg[2:0]alucontrol );

	always @(*)
		case(aluop)
			2'b00: alucontrol <= 3'b010;  // add
			2'b01: alucontrol <= 3'b110;  // sub
			default: case(funct)          // RTYPE
				6'b100000: alucontrol <= 3'b010; // ADD
				6'b100010: alucontrol <= 3'b110; // SUB
				6'b100100: alucontrol <= 3'b000; // AND
				6'b100101: alucontrol <= 3'b001; // OR
				6'b101010: alucontrol <= 3'b111; // SLT
				default:   alucontrol <= 3'bxxx; // ???
			endcase
		endcase
endmodule