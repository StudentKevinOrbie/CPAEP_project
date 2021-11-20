interface intf #(
    config_t cfg
  )
  (
    input logic clk
  );
  logic arst_n;

  /*#############################
  WHEN ADJUSTING THIS INTERFACE, ADJUST THE ENERGY ADDITIONS AT THE BOTTOM ACCORDINGLY!
  ################################*/

  // input interface
  logic [cfg.DATA_WIDTH - 1 : 0] con_1;
  logic [cfg.DATA_WIDTH - 1 : 0] con_2;
  logic [cfg.DATA_WIDTH - 1 : 0] con_3;

  logic con_valid;
  logic con_ready;

  logic [cfg.DATA_WIDTH-1:0] to_con_1;   //to_bidir_bus;
  logic [cfg.DATA_WIDTH-1:0] to_con_2;
  logic [cfg.DATA_WIDTH-1:0] to_con_3;
  logic [cfg.DATA_WIDTH-1:0] from_con_1; //from_bidir_bus;
  logic [cfg.DATA_WIDTH-1:0] from_con_2;
  logic [cfg.DATA_WIDTH-1:0] from_con_3;

  assign con_1 = (dut_driving_cons) ? 'Z : to_con_1;
  assign con_2 = (dut_driving_cons) ? 'Z : to_con_2;
  assign con_3 = (dut_driving_cons) ? 'Z : to_con_3;

  assign from_con_1 = con_1;
  assign from_con_2 = con_2;
  assign from_con_3 = con_3;

  // output interface
  logic output_valid;
  logic [$clog2(cfg.FEATURE_MAP_WIDTH)-1:0] output_x;
  logic [$clog2(cfg.FEATURE_MAP_HEIGHT)-1:0] output_y;
  logic [$clog2(cfg.OUTPUT_NB_CHANNELS)-1:0] output_ch;

  logic start;
  logic running;

  logic dut_driving_cons;

  default clocking cb @(posedge clk);
    default input #0.01 output #0.01;
    output arst_n;

    output to_con_1;
    input  from_con_1;

    output to_con_2;
    input  from_con_2;

    output to_con_3;
    input  from_con_3;

    output con_valid;
    input  con_ready;

    input output_valid;
    input output_x;
    input output_y;
    input output_ch;

    output start;
    input  running;

    input dut_driving_cons;
  endclocking

  modport tb (clocking cb); // testbench's view of the interface

  //ENERGY ESTIMATION:
  always @ (posedge clk) begin
    if(con_1_valid && con_1_ready) begin
      tbench_top.energy += 1*(cfg.DATA_WIDTH);
    end
  end
  always @ (posedge clk) begin
    if(con_2_valid && con_2_ready) begin
      tbench_top.energy += 1*(cfg.DATA_WIDTH);
    end
  end
  always @ (posedge clk) begin
    if(con_3_valid && con_3_ready) begin
      tbench_top.energy += 1*(cfg.DATA_WIDTH);
    end
  end

endinterface
