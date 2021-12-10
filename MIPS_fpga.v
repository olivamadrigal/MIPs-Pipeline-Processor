`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// CMPE 140, CMPE Department, san Jose State University 
// Authors: Donald Hung and Hoan Nguyen
// 
// Create Date:    08:36:48 02/25/2010 
// Design Name: 
// Module Name:    mips_top 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
// MIPS Top-level Module (including the memories, clock,
// and the display module for prototyping)

module mips_fpga(input			clk, reset, 
				 output			memwrite,
				 output[ 3:0]	top_an, 
				 output[ 7:0]	top_sseg,
				 input[ 7:0]	switches,
				 output			sinkBit );

	wire[31:0] 	pc, instr, dataadr, writedata, dispDat;
	wire 		clksec;
	reg[ 7:0] 	reg_hex1, reg_hex0;

	// Clock (1 second) to slow down the running of the instructions
	clk_gen top_clk(.clk50MHz(clk), .reset(reset), .clksec(clksec));
      
	// Instantiate processor and memories
	mips mips(clksec, reset,writedata, dataadr, 
			     memwrite, switches[4:0], dispDat, pc, instr);	

	// Instantiate 7-seg LED display module
	disp_hex_mux disp_unit (.clk(clk), .reset(1'b0), 
		.hex3(reg_hex1[7:4]), .hex2(reg_hex1[3:0]), 
		.hex1(reg_hex0[7:4]), .hex0(reg_hex0[3:0]),  
		.dp_in(4'b1111), .an(top_an), .sseg(top_sseg));

	// contents displayed on the 7 segment LEDs depending on DIP switches 7:5
	//   	7:5 = 000: display PC & LSB of register selected by DIP switches 4:0
	//   	7:5 = 001: display PC & LSB of instr
	//   	7:5 = 010: display PC & LSB of dataadr
	//   	7:5 = 011: display PC & LSB of writedata
	// 	7:5 = 100: display PC & instr byte 0
	// 	7:5 = 101: display PC & instr byte 1
	// 	7:5 = 110: display PC & instr byte 2
	//  	7:5 = 111: display PC & instr byte 3
	always @ (posedge clk) begin
		reg_hex1 = pc[7:0];
		case ({switches[7],switches[6], switches[5]})
			3'b000:	begin
					reg_hex0 = dispDat[ 7:0];
					end
			3'b001:	begin
					reg_hex0 = instr[ 7:0];
					end
			3'b010:	begin
					reg_hex0 = dataadr[ 7:0];
					end
			3'b011:	begin
					reg_hex0 = writedata[ 7:0];
					end
			3'b100:	begin
					reg_hex0 = instr[ 7:0];
					end
			3'b101:	begin
					reg_hex0 = instr[ 15:8];
					end
			3'b110:	begin
					reg_hex0 = instr[ 23:16];
					end
			3'b111:	begin
					reg_hex0 = instr[ 31:24];
					end
			endcase
	end		

	//sink unused bit(s) to knock down the number of warning messages
	assign sinkBit = (pc > 0) ^ (instr > 0) ^ (dataadr > 0) ^ (writedata > 0) ^ 
					 (dispDat > 0);
endmodule

//mips_fpga/clk_gen module
//-----------------------------------------------------------------
// Module Name   : clk_gen
// Description   : Generate 4 second and 5KHz clock cycle from
//                 the 50MHz clock on the Nexsys2 board
//------------------------------------------------------------------
module clk_gen(
	input			clk50MHz, reset, 
	output reg		clksec );

	reg 			clk_5KHz;
	integer 		count, count1;
	
	always@(posedge clk50MHz) begin
		if(reset) begin
			count = 0;
			count1 = 0;
			clksec = 0;
			clk_5KHz =0;
		end else begin
			if (count == 50000000) begin
				// Just toggle after certain number of seconds
				clksec = ~clksec;
				count = 0;
			end
			if (count1 == 20000) begin
				clk_5KHz = ~clk_5KHz;
				count1 = 0;
			end
			count = count + 1;
			count1 = count1 + 1;
		end
	end
endmodule

//mips_fpga/disp_hex_mux module
//-----------------------------------------------------------------
// Module Name   : disp_hex_mux
// Description   : Display the four Hex inputs on Nexys2's 7-seg LEDs
// Authors       : D. Herda, D. Hung, G. Gergen                    
//------------------------------------------------------------------
module disp_hex_mux
   (
    input wire clk, reset,
    input wire [3:0] hex3, hex2, hex1, hex0,  // hex digits
    input wire [3:0] dp_in,             // 4 decimal points
    output reg [3:0] an,  // enable 1-out-of-4 asserted low
    output reg [7:0] sseg // led segments
   );

   // constant declaration
   // refreshing rate around 800 Hz (50 MHz/2^16)
   localparam N = 18;

   // internal signal declaration
   reg [N-1:0] q_reg;
   wire [N-1:0] q_next;
   reg [3:0] hex_in;
   reg dp;

   // N-bit counter register
   always @(posedge clk, posedge reset)
      if (reset)
         q_reg <= 0;
      else
         q_reg <= q_next;

   // next-state logic
   assign q_next = q_reg + 1;

   // 2 MSBs of counter to control 4-to-1 multiplexing
   // and to generate active-low enable signal.  This
   // will put the input on the vaious LEDs

   always @*
      case (q_reg[N-1:N-2])
         2'b00:
            begin
               an =  4'b1110;
               hex_in = hex0;
               dp = dp_in[0];
            end
         2'b01:
            begin
               an =  4'b1101;
               hex_in = hex1;
               dp = dp_in[1];
            end
         2'b10:
            begin
               an =  4'b1011;
               hex_in = hex2;
               dp = dp_in[2];
            end
         default:
            begin
               an =  4'b0111;
               hex_in = hex3;
               dp = dp_in[3];
            end
       endcase

   // hex to seven-segment led display
   always @*
   begin
      case(hex_in)
         4'h0: sseg[6:0] = 7'b0000001;
         4'h1: sseg[6:0] = 7'b1001111;
         4'h2: sseg[6:0] = 7'b0010010;
         4'h3: sseg[6:0] = 7'b0000110;
         4'h4: sseg[6:0] = 7'b1001100;
         4'h5: sseg[6:0] = 7'b0100100;
         4'h6: sseg[6:0] = 7'b0100000;
         4'h7: sseg[6:0] = 7'b0001111;
         4'h8: sseg[6:0] = 7'b0000000;
         4'h9: sseg[6:0] = 7'b0000100;
         4'ha: sseg[6:0] = 7'b0001000;
         4'hb: sseg[6:0] = 7'b1100000;
         4'hc: sseg[6:0] = 7'b0110001;
         4'hd: sseg[6:0] = 7'b1000010;
         4'he: sseg[6:0] = 7'b0110000;
         default: sseg[6:0] = 7'b0111000;  //4'hf
     endcase
     sseg[7] = dp;
   end

endmodule