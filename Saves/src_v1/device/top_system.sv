//wraps both top_chip and an external memory
//bandwidth to be counted is all bandwidth in and out of top_chip
module top_system #(
    parameter int IO_DATA_WIDTH = 16,
    parameter int ACCUMULATION_WIDTH = 32,
    parameter int EXT_MEM_HEIGHT = 1<<20,
    parameter int EXT_MEM_WIDTH = ACCUMULATION_WIDTH,
    parameter int FEATURE_MAP_WIDTH = 1024,
    parameter int FEATURE_MAP_HEIGHT = 1024,
    parameter int INPUT_NB_CHANNELS = 64,
    parameter int OUTPUT_NB_CHANNELS = 64,
    parameter int KERNEL_SIZE = 3
  )(input logic clk,
    input logic arst_n_in,  //asynchronous reset, active low

    //system input/output connections
    inout wire [IO_DATA_WIDTH-1:0] con_1,
    inout wire [IO_DATA_WIDTH-1:0] con_2,
    inout wire [IO_DATA_WIDTH-1:0] con_3,

    input logic con_valid,
    output logic con_ready,

    //Control
    output logic output_valid,
    output logic [$clog2(FEATURE_MAP_WIDTH)-1:0] output_x,
    output logic [$clog2(FEATURE_MAP_HEIGHT)-1:0] output_y,
    output logic [$clog2(OUTPUT_NB_CHANNELS)-1:0] output_ch,
   
    input logic start,
    output logic running,

    output bit driving_cons
  );

  top_chip #(
  .IO_DATA_WIDTH(IO_DATA_WIDTH),
  .ACCUMULATION_WIDTH(ACCUMULATION_WIDTH),
  .EXT_MEM_HEIGHT(EXT_MEM_HEIGHT),
  .EXT_MEM_WIDTH(EXT_MEM_WIDTH),
  .FEATURE_MAP_WIDTH(FEATURE_MAP_WIDTH),
  .FEATURE_MAP_HEIGHT(FEATURE_MAP_HEIGHT),
  .INPUT_NB_CHANNELS(INPUT_NB_CHANNELS),
  .OUTPUT_NB_CHANNELS(OUTPUT_NB_CHANNELS),
  .KERNEL_SIZE(KERNEL_SIZE)
  ) top_chip_i 
  (
    .clk(clk),
    .arst_n_in(arst_n_in),

    //system input/output connections
    .con_1(con_1),
    .con_2(con_2),
    .con_3(con_3),

    .con_valid (con_valid),
    .con_ready (con_ready),

    //Control
    .driving_cons (driving_cons),

    .output_valid (output_valid),
    .output_x(output_x),
    .output_y(output_y),
    .output_ch(output_ch),

    .start(start),
    .running(running)
  );
endmodule
