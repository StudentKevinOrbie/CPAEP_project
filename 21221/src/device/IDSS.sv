module IDSS #(
    parameter int IO_DATA_WIDTH = 16,
    parameter int ACCUMULATION_WIDTH = 32,
    parameter int EXT_MEM_HEIGHT = 1<<20,
    parameter int EXT_MEM_WIDTH = ACCUMULATION_WIDTH,
    parameter int FEATURE_MAP_WIDTH = 1024,
    parameter int FEATURE_MAP_HEIGHT = 1024,
    parameter int INPUT_NB_CHANNELS = 64,
    parameter int OUTPUT_NB_CHANNELS = 64,
    parameter int KERNEL_SIZE = 3
  )
  (input logic clk,
   input logic arst_n_in,  //asynchronous reset, active low

   //system inputs and outputs
   input logic [IO_DATA_WIDTH-1:0] row_1,
   input logic [IO_DATA_WIDTH-1:0] row_2,
   input logic [IO_DATA_WIDTH-1:0] row_3,

   //output
   output logic [IO_DATA_WIDTH-1:0] out [35:0],

   // Control
   input logic shift,
   input logic [1:0] LE_select
  );

  logic LE_1;
  logic LE_2;
  logic LE_3;
  logic LE_4;

  CSS css_c1 
  (.clk(clk),
   .arst_n_in(arst_n_in),

   //system inputs and outputs
   .row_1 (row_1),
   .row_2 (row_2),
   .row_3 (row_3),

   //output
   .out_1_2 (out[0]),
   .out_2_2 (out[1]),
   .out_3_2 (out[2]),

   .out_1_3 (out[3]),
   .out_2_3 (out[4]),
   .out_3_3 (out[5]),

   .out_1_4 (out[6]),
   .out_2_4 (out[7]),
   .out_3_4 (out[8]),

   //output
   .LE (LE_1),     //Load enable of input registers
   .shift (shift)
   ); 

  CSS css_c2 
  (.clk(clk),
   .arst_n_in(arst_n_in),

   //system inputs and outputs
   .row_1 (row_1),
   .row_2 (row_2),
   .row_3 (row_3),

   //output
   .out_1_2 (out[9]),
   .out_2_2 (out[10]),
   .out_3_2 (out[11]),

   .out_1_3 (out[12]),
   .out_2_3 (out[13]),
   .out_3_3 (out[14]),

   .out_1_4 (out[15]),
   .out_2_4 (out[16]),
   .out_3_4 (out[17]),

   //output
   .LE (LE_2),     //Load enable of input registers
   .shift (shift)
   );

  CSS css_c3 
  (.clk(clk),
   .arst_n_in(arst_n_in),

   //system inputs and outputs
   .row_1 (row_1),
   .row_2 (row_2),
   .row_3 (row_3),

   //output
   .out_1_2 (out[18]),
   .out_2_2 (out[19]),
   .out_3_2 (out[20]),

   .out_1_3 (out[21]),
   .out_2_3 (out[22]),
   .out_3_3 (out[23]),

   .out_1_4 (out[24]),
   .out_2_4 (out[25]),
   .out_3_4 (out[26]),

   //output
   .LE (LE_3),     //Load enable of input registers
   .shift (shift)
   );

  CSS css_c4 
  (.clk(clk),
   .arst_n_in(arst_n_in),

   //system inputs and outputs
   .row_1 (row_1),
   .row_2 (row_2),
   .row_3 (row_3),

   //output
   .out_1_2 (out[27]),
   .out_2_2 (out[28]),
   .out_3_2 (out[29]),

   .out_1_3 (out[30]),
   .out_2_3 (out[31]),
   .out_3_3 (out[32]),

   .out_1_4 (out[33]),
   .out_2_4 (out[34]),
   .out_3_4 (out[35]),

   //output
   .LE (LE_4),     //Load enable of input registers
   .shift (shift)
   );

always @(clk)
begin
 LE_1 <= 0;
 LE_2 <= 0;
 LE_3 <= 0;
 LE_4 <= 0;

 case (LE_select)
    2'b00: LE_1 <= 1;
    2'b01: LE_2 <= 1;
    2'b10: LE_3 <= 1;
    2'b11: LE_4 <= 1;
    default:
      begin
	      LE_1 <= 0;
        LE_2 <= 0;
        LE_3 <= 0;
        LE_4 <= 0;
      end
  endcase
end


endmodule
