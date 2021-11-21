module CSS #(
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
   output logic [IO_DATA_WIDTH-1:0] out_1_2,
   output logic [IO_DATA_WIDTH-1:0] out_1_3,
   output logic [IO_DATA_WIDTH-1:0] out_1_4,
   output logic [IO_DATA_WIDTH-1:0] out_2_2,
   output logic [IO_DATA_WIDTH-1:0] out_2_3,
   output logic [IO_DATA_WIDTH-1:0] out_2_4,
   output logic [IO_DATA_WIDTH-1:0] out_3_2,
   output logic [IO_DATA_WIDTH-1:0] out_3_3,
   output logic [IO_DATA_WIDTH-1:0] out_3_4,

   //output
   input logic LE,     //Load enable of input registers
   input logic shift  //Load enable of output registers
  );

  `REG(IO_DATA_WIDTH, i_1_1);
  `REG(IO_DATA_WIDTH, o_1_2);
  `REG(IO_DATA_WIDTH, o_1_3);
  `REG(IO_DATA_WIDTH, o_1_4);
  `REG(IO_DATA_WIDTH, i_2_1);
  `REG(IO_DATA_WIDTH, o_2_2);
  `REG(IO_DATA_WIDTH, o_2_3);
  `REG(IO_DATA_WIDTH, o_2_4);
  `REG(IO_DATA_WIDTH, i_3_1);
  `REG(IO_DATA_WIDTH, o_3_2);
  `REG(IO_DATA_WIDTH, o_3_3);
  `REG(IO_DATA_WIDTH, o_3_4);

  assign i_1_1_we = LE;
  assign i_2_1_we = LE;
  assign i_3_1_we = LE;

  assign o_1_2_we = shift;
  assign o_1_3_we = shift;
  assign o_1_4_we = shift;
  assign o_2_2_we = shift;
  assign o_2_3_we = shift;
  assign o_2_4_we = shift;
  assign o_3_2_we = shift;
  assign o_3_3_we = shift;
  assign o_3_4_we = shift;

  assign i_1_1_next = row_1;
  assign i_2_1_next = row_2;
  assign i_3_1_next = row_3;

  assign o_1_2_next = i_1_1;
  assign o_1_3_next = o_1_2;
  assign o_1_4_next = o_1_3;
  assign o_2_2_next = i_2_1;
  assign o_2_3_next = o_2_2;
  assign o_2_4_next = o_2_3;
  assign o_3_2_next = i_3_1;
  assign o_3_3_next = o_3_2;
  assign o_3_4_next = o_3_3;

  assign out_1_2 = o_1_2;
  assign out_1_3 = o_1_3;
  assign out_1_4 = o_1_4;
  assign out_2_2 = o_2_2;
  assign out_2_3 = o_2_3;
  assign out_2_4 = o_2_4;
  assign out_3_2 = o_3_2;
  assign out_3_3 = o_3_3;
  assign out_3_4 = o_3_4;

endmodule
