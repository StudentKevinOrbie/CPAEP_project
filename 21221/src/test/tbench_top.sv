
module tbench_top;
  //change this according to your critical path length.
  //The code will error* if it too short, but you will get no feedback if it is longer than necessary
  //* if 1) you use the adder and multiplier modules for datapath adders and multipliers and not the plain verilog + and * operators
  // and 2) enough calculations are going on, with non-x data (this will be the case for functionally working code)
  localparam int CLK_PERIOD = 2;

  localparam int DATA_WIDTH         = 16;
  localparam int ACCUMULATION_WIDTH = 32;
  localparam int EXT_MEM_HEIGHT     = 1<<20;
  localparam int EXT_MEM_WIDTH      = ACCUMULATION_WIDTH;
  localparam int FEATURE_MAP_WIDTH  = 64;
  localparam int FEATURE_MAP_HEIGHT = 64;
  localparam int INPUT_NB_CHANNELS  = 4;
  localparam int OUTPUT_NB_CHANNELS = 32;
  localparam int KERNEL_SIZE        = 3;

  // initialize config_t structure, which is used to parameterize all other classes of the testbench
  localparam config_t cfg= '{
    DATA_WIDTH        ,
    ACCUMULATION_WIDTH,
    EXT_MEM_HEIGHT    ,
    EXT_MEM_WIDTH     ,
    FEATURE_MAP_WIDTH ,
    FEATURE_MAP_HEIGHT,
    INPUT_NB_CHANNELS ,
    OUTPUT_NB_CHANNELS,
    KERNEL_SIZE
  };

  initial $timeformat(-9, 3, "ns", 1);


  //clock
  bit clk;
  always #(CLK_PERIOD*0.85/2.0) clk = !clk;

  //interface
  intf #(cfg) intf_i (clk);

  testprogram #(cfg) t1(intf_i.tb);

  //DUT
  top_system #(
  .IO_DATA_WIDTH     (DATA_WIDTH),
  .ACCUMULATION_WIDTH(ACCUMULATION_WIDTH),
  .EXT_MEM_HEIGHT    (EXT_MEM_HEIGHT),
  .EXT_MEM_WIDTH     (EXT_MEM_WIDTH),
  .FEATURE_MAP_WIDTH (FEATURE_MAP_WIDTH),
  .FEATURE_MAP_HEIGHT(FEATURE_MAP_HEIGHT),
  .INPUT_NB_CHANNELS (INPUT_NB_CHANNELS),
  .OUTPUT_NB_CHANNELS(OUTPUT_NB_CHANNELS),
  .KERNEL_SIZE       (KERNEL_SIZE)
  ) dut (
   .clk         (intf_i.clk),
   .arst_n_in   (intf_i.arst_n),

   //system input/output connections
   .con_1        (intf_i.con_1),
   .con_2        (intf_i.con_2),
   .con_3        (intf_i.con_3),

   .con_valid  (intf_i.con_valid),
   .con_ready  (intf_i.con_ready),

   //Control
   .output_valid (intf_i.output_valid),
   .output_x     (intf_i.output_x),
   .output_y     (intf_i.output_y),
   .output_ch    (intf_i.output_ch),
   
   .start        (intf_i.start),
   .running      (intf_i.running),

   .driving_cons (intf_i.dut_driving_cons),
   .last_load_K (intf_i.last_load_K)
  );


  //area logging init
  longint area;
  initial begin
    area = 0;
    #0;
    #0;
    $display("\n\n------------\nAREA: %0d\n------------\n\n", area);
  end
  //energy loggin init;
  real energy;
  initial begin
    energy = 0;
  end



endmodule
