module top_chip #(
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

    output logic driving_cons
  );

  // ================== SIGNALS ==================
  logic signed [ACCUMULATION_WIDTH-1:0] mac_out;

  logic signed [IO_DATA_WIDTH-1:0] ODS_in;

  // Bidir busses
  logic [IO_DATA_WIDTH-1:0] to_con_1;   //to_bidir_bus;
  logic [IO_DATA_WIDTH-1:0] to_con_2;
  logic [IO_DATA_WIDTH-1:0] to_con_3;
  logic [IO_DATA_WIDTH-1:0] from_con_1; //from_bidir_bus;
  logic [IO_DATA_WIDTH-1:0] from_con_2;
  logic [IO_DATA_WIDTH-1:0] from_con_3;

  // Interconnect
  logic [IO_DATA_WIDTH-1:0] IDSS_to_MAC [35:0];
  logic [IO_DATA_WIDTH-1:0] KDS_to_MAC [35:0];

  // ctrl
  logic ctrl_to_IDSS_shift;
  logic [1:0] ctrl_to_IDSS_LE_select;
  logic [11:0] ctrl_to_KDS_LE_select;
  logic [1:0] ctrl_to_ODS_sel_out;
  logic ctrl_to_ODS_shift;

  // ================== CONNECTIONS ==================
  assign ODS_in = mac_out;

  // Bidir busses
  //assign bidir_bus = (direction) ? 'Z : to_bidir_bus;
  //assign from_bidir_bus = bidir_bus;
  assign con_1 = (driving_cons) ? to_con_1 : 'Z;
  assign from_con_1 = con_1;
  assign con_2 = (driving_cons) ? to_con_2 : 'Z;
  assign from_con_2 = con_2;
  assign con_3 = (driving_cons) ? to_con_3 : 'Z;
  assign from_con_3 = con_3;

  // ================== ADD SUB UNITS ==================
  IDSS IDSS_unit
  (.clk(clk),
   .arst_n_in(arst_n_in),

   //inputs
   .row_1 (from_con_1),
   .row_2 (from_con_2),
   .row_3 (from_con_3),

   //output
   .out (IDSS_to_MAC),

   // Control
   .shift (ctrl_to_IDSS_shift),
   .LE_select (ctrl_to_IDSS_LE_select)
  );

  KDS KDS_unit
  (.clk(clk),
   .arst_n_in(arst_n_in),

   //inputs
   .v_1 (from_con_1),
   .v_2 (from_con_2),
   .v_3 (from_con_3),

   //output
   .out (KDS_to_MAC),

   // Control
   .LE_select (ctrl_to_KDS_LE_select)
  );

  super_MAC super_MAC_unit
  (.clk(clk),
   .arst_n_in(arst_n_in),

   //inputs
   .I_in (IDSS_to_MAC),
   .K_in (KDS_to_MAC),

   //output
   .out (mac_out)
  );

  ODS ODS_unit
  (.clk(clk),
   .arst_n_in(arst_n_in),  //asynchronous reset, active low

   .in (ODS_in), 
   .out_1 (to_con_1), 
   .out_2 (to_con_2), 
   .out_3 (to_con_3),

   .sel_out (ctrl_to_ODS_sel_out),
   .shift (ctrl_to_ODS_shift)
  ); 
  // ================== CONTROL ==================
  // LOOP COUNTERS + TOTAL FSM

  controller_fsm controller_unit
  (.clk(clk),
  .arst_n_in(arst_n_in),

  .start(start),
  .running(running),

  //datapad control interface & external handshaking communication
  .con_valid(con_valid),
  .con_ready(con_ready),

  .output_valid(output_valid),
  .output_x(output_x),
  .output_y(output_y),
  .output_ch(output_ch),

  .ctrl_IDSS_shift(ctrl_to_IDSS_shift),
  .ctrl_IDSS_LE_select(ctrl_to_IDSS_LE_select),

  .ctrl_KDS_LE_select(ctrl_to_KDS_LE_select),

  .ctrl_ODS_shift(ctrl_to_ODS_shift),
  .ctrl_ODS_sel_out(ctrl_to_ODS_sel_out), 

  .driving_cons(driving_cons)
  );

endmodule
