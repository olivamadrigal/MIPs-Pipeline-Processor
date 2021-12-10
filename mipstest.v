//------------------------------------------------
// mipstest.v
// David_Harris@hmc.edu 23 October 2005
// Testbench for MIPS processor
//------------------------------------------------

module testbench();

	reg     clk;
	reg     reset;
	reg[4:0]dispSel;		  
	reg[31:0] IC;
	wire[31:0] writedata, dataadr,dispDat, pc, instr;
	wire	   memwrite;

	// instantiate device to be tested
	mips dut(clk, reset, writedata, dataadr, memwrite, dispSel, dispDat, pc, instr);
  
	// initialize test
	initial
	begin
		dispSel <= 5'd4; IC <= 1;
		reset <= 1; # 22; reset <= 0;
   end

	
	// generate clock to sequence tests
	always
	begin
		clk <= 1; # 5; clk <= 0; # 5;
   end

	always@(negedge clk)
    begin
		if(reset != 1)
			IC = IC +1;
			
		if(IC == 32'h90)
			$stop;
			
		// Check the result 4! = 24
      if(pc[7:0]== 8'h5C)
		begin
		dispSel = 5'd16; #15; //check value of $s0
        if(dispSel == 5'd16 && dispDat == 32'd24) //check $s0 == 24 or not
		  begin
			$display("addi, add, sw, lw, beg, jal, jr, j, multu, mflo funtion correctly.");
        end
		  else
		  begin
			$display("Simulation failed - 1st test");
			$stop;
        end
      end
		
		// Check the result = 0x3520F3A3
		if(pc[7:0]== 8'h80)
		begin
		dispSel = 5'd8; #15; //check value of $s0
        if(dispSel == 5'd8 && dispDat == 32'h3520F3A3) //check $t0 = 0x3520F3A3 or not
		  begin
			$display("multu, mflo, mfhi, and, or function correctly.");
			$display("Simulation succeeded.");
			$stop;
        end
		  else
		  begin
			$display("Simulation failed - 2nd test");
			$stop;
        end
      end
		
    end
endmodule



