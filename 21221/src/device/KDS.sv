module KDS #(
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
   input logic [IO_DATA_WIDTH-1:0] v_1,
   input logic [IO_DATA_WIDTH-1:0] v_2,
   input logic [IO_DATA_WIDTH-1:0] v_3,

   //output
   output logic [IO_DATA_WIDTH-1:0] out [35:0],

   // Control
   input logic [11:0] LE_select,
   input logic cycle_enable
  );

genvar i;

generate
for (i=0;i<12;i=i+1) begin
  logic [IO_DATA_WIDTH-1:0] mux_1_out;
  assign mux_1_out = ( LE_select[i] == 1 ) ? v_1:out[3*i];

  logic [IO_DATA_WIDTH-1:0] mux_2_out;
  assign mux_2_out = ( LE_select[i] == 1 ) ? v_2:out[(3*i+1)];

  logic [IO_DATA_WIDTH-1:0] mux_3_out;
  assign mux_3_out = ( LE_select[i] == 1 ) ? v_3:out[(3*i+2)];

  logic read_out_fifo;
  assign read_out_fifo = (cycle_enable) ? 1'b1 : 1'b0;

  fifo #(.WIDTH(IO_DATA_WIDTH), .LOG2_OF_DEPTH(3), .USE_AS_EXTERNAL_FIFO (0)) fifo_1
  (
    .clk (clk),
    .arst_n_in (arst_n_in), //asynchronous reset, active low
    .din (mux_1_out),
    .input_valid (1'b1), //write enable
    .input_ready (), // not fifo full
    .qout (out[3*i]),
    .output_valid (), // not empty
    .output_ready (read_out_fifo)  //read enable
  );

  fifo #(.WIDTH(IO_DATA_WIDTH), .LOG2_OF_DEPTH(3), .USE_AS_EXTERNAL_FIFO (0)) fifo_2
  (
    .clk (clk),
    .arst_n_in (arst_n_in), //asynchronous reset, active low
    .din (mux_2_out),
    .input_valid (1'b1), //write enable
    .input_ready (), // not fifo full
    .qout (out[(3*i+1)]),
    .output_valid (), // not empty
    .output_ready (read_out_fifo)  //read enable
  );

  fifo #(.WIDTH(IO_DATA_WIDTH), .LOG2_OF_DEPTH(3), .USE_AS_EXTERNAL_FIFO (0)) fifo_3
  (
    .clk (clk),
    .arst_n_in (arst_n_in), //asynchronous reset, active low
    .din (mux_3_out),
    .input_valid (1'b1), //write enable
    .input_ready (), // not fifo full
    .qout (out[(3*i+2)]),
    .output_valid (), // not empty
    .output_ready (read_out_fifo)  //read enable
  );
end
endgenerate

endmodule
