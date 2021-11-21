module controller_fsm #(
  parameter int LOG2_OF_MEM_HEIGHT = 20,
  parameter int FEATURE_MAP_WIDTH = 1024,
  parameter int FEATURE_MAP_HEIGHT = 1024,
  parameter int INPUT_NB_CHANNELS = 64,
  parameter int OUTPUT_NB_CHANNELS = 32,
  parameter int KERNEL_SIZE = 3
  )
  (input logic clk,
  input logic arst_n_in, //asynchronous reset, active low

  input logic start,
  output logic running,

  //datapad control interface & external handshaking communication
  input logic con_valid,
  output logic con_ready,

  output logic output_valid,
  output logic [32-1:0] output_x,
  output logic [32-1:0] output_y,
  output logic [32-1:0] output_ch,

  output logic ctrl_IDSS_shift,
  output logic [2:0] ctrl_IDSS_LE_select,

  output logic [11:0] ctrl_KDS_LE_select,
  output logic ctrl_to_KDS_cycle_enable,

  output logic ctrl_ODS_shift,
  output logic [1:0] ctrl_ODS_sel_out, 

  output logic driving_cons
  );

  //loop counters (see register.sv for macro)
  `REG(32, x);
  `REG(32, y);
  `REG(32, ch_out);

  logic reset_x, reset_y, reset_ch_out;
  assign x_next = reset_x ? 0 : x + 1;
  assign y_next = reset_y ? 0 : y + 1;
  assign ch_out_next = reset_ch_out ? 0 : ch_out + 6;

  logic last_x, last_y, last_ch_out;
  assign last_x = x == 63;
  assign last_y = y == 63;
  assign last_ch_out = ch_out == OUTPUT_NB_CHANNELS - 1;

  assign reset_x = last_x;
  assign reset_y = last_y;
  assign reset_ch_out = last_ch_out;

  /*
  chosen loop order:
  for ch_out/6
    for y
      for x
        for ch_out_1
          for ch_in    --
            for k_v    -- Paralell 
              for k_h  --
                body
  */
  logic inc_x;
  assign x_we      = inc_x ; //only if last of all enclosed loops
  assign y_we      = inc_x && last_x; //only if last of all enclosed loops
  assign ch_out_we = inc_x && last_x && last_y; //only if last of all enclosed loops

  logic last_overall;
  assign last_overall   = last_ch_out && last_y && last_x;

  // Due to two return cycles we need to add
  logic add_to_chout;
  logic [31:0] chout_updated;
  assign chout_updated = (add_to_chout) ? ch_out + 3 : ch_out;

  //mark outputs
  `REG(1, output_valid_reg);
  assign output_valid_reg_we   = 1;
  assign output_valid = output_valid_reg;

  // Flags
  `REG(1, calc_1_done); // During the first calculation, no output ready, due to pipelining

  logic we_chout_override;
  logic we_chout;
  assign we_chout = ((inc_x || add_to_chout) & calc_1_done) || we_chout_override;

  register #(.WIDTH(32)) output_x_r (.clk(clk), .arst_n_in(arst_n_in),
                                                .din(x),
                                                .qout(output_x),
                                                .we(1'b1));
  register #(.WIDTH(32)) output_y_r (.clk(clk), .arst_n_in(arst_n_in),
                                                .din(y),
                                                .qout(output_y),
                                                .we(1'b1));
  register #(.WIDTH(32)) output_ch_r (.clk(clk), .arst_n_in(arst_n_in),
                                                .din(chout_updated),
                                                .qout(output_ch),
                                                .we(we_chout));

  // Counters
  logic last_partial_load_K;
  logic last_partial_load_I;
  logic last_load_K;

  `REG(2, load_I_counter);
  `REG(3, load_K_counter);
  
  assign last_partial_load_K = (load_K_counter == 0);
  assign last_partial_load_I = (load_I_counter == 0);
  
  // ======================================== Control FSM ========================================

  typedef enum {IDLE, 
	        LK_1, LK_2, LK_3, LK_4, LK_5, LK_6, LK_7, LK_8, LK_9, LK_10, LK_11, LK_12,
                LI_1, LI_2, LI_3, LI_4, LI_shift,
                CC_1, CC_2, CC_3, CC_4, CC_5, CC_6} fsm_state;
  fsm_state current_state;
  fsm_state next_state;
  always @ (posedge clk or negedge arst_n_in) begin
    if(arst_n_in==0) begin
      current_state <= IDLE;
    end else begin
      current_state <= next_state;
    end
  end

  always_comb begin
    //defaults: applicable if not overwritten below
    next_state = current_state;
    inc_x = 0;
    running = 1;
    ctrl_IDSS_shift = 0 ;
    ctrl_IDSS_LE_select = 0 ;
    ctrl_KDS_LE_select = 12'b0000_0000_0000; // Default is shift config for all values
    ctrl_to_KDS_cycle_enable = 0;
    ctrl_ODS_sel_out = 2'b11; 
    ctrl_ODS_shift = 0;
    driving_cons = 0; 

    output_valid_reg_next = 0;

    load_I_counter_next = load_I_counter;
    load_K_counter_next = load_K_counter;
    load_I_counter_we = 1;
    load_K_counter_we = 1;

    calc_1_done_next = calc_1_done;
    calc_1_done_we = 1;

    add_to_chout = 0;
    we_chout_override = 0;

    case (current_state)
      // IDLE
      IDLE: begin
        running = 0;

        load_K_counter_next = 3'b101; // 5
        next_state = start ? LK_1 : IDLE;
      end

      // LOAD_k
      LK_1: begin
        con_ready = 1;
        ctrl_KDS_LE_select = 12'b0000_0000_0001; 
        we_chout_override = 1;

        next_state = (con_valid) ? LK_2 : current_state;
      end

      LK_2: begin
        con_ready = 1;
        ctrl_KDS_LE_select = 12'b0000_0000_0010;

        next_state = LK_3;
      end

      LK_3: begin
        con_ready = 1;
        ctrl_KDS_LE_select = 12'b0000_0000_0100;

        next_state = LK_4;
      end

      LK_4: begin
        con_ready = 1;
        ctrl_KDS_LE_select = 12'b0000_0000_1000;

        next_state = LK_5;
      end

      LK_5: begin
        con_ready = 1;
        ctrl_KDS_LE_select = 12'b0000_0001_0000;

        next_state = LK_6;
      end

      LK_6: begin
        con_ready = 1;
        ctrl_KDS_LE_select = 12'b0000_0010_0000;

        next_state = LK_7;
      end

      LK_7: begin
        con_ready = 1;
        ctrl_KDS_LE_select = 12'b0000_0100_0000;

        next_state = LK_8;
      end

      LK_8: begin
        con_ready = 1;
        ctrl_KDS_LE_select = 12'b0000_1000_0000;

        next_state = LK_9;
      end

      LK_9: begin
        con_ready = 1;
        ctrl_KDS_LE_select = 12'b0001_0000_0000;

        next_state = LK_10;
      end

      LK_10: begin
        con_ready = 1;
        ctrl_KDS_LE_select = 12'b0010_0000_0000;

        next_state = LK_11;
      end

      LK_11: begin
        con_ready = 1;
        ctrl_KDS_LE_select = 12'b0100_0000_0000;

        next_state = LK_12;
      end

      LK_12: begin
        con_ready = 1;
        ctrl_KDS_LE_select = 12'b1000_0000_0000;

        load_I_counter_next = 2'b10; //2 --> [2,1,0] ==> 3X
        load_K_counter_next = load_K_counter - 1;
        next_state = last_partial_load_K ? LI_1 : LK_1;
      end

      // LOAD_I
      LI_1: begin
        con_ready = 1;
        ctrl_IDSS_LE_select = 3'b001; 

        next_state = (con_valid) ? LI_2 : current_state;
      end

      LI_2: begin
        con_ready = 1;
        ctrl_IDSS_LE_select = 3'b010; 

        next_state = LI_3;
      end

      LI_3: begin
        con_ready = 1;
        ctrl_IDSS_LE_select = 3'b011; 

        next_state = LI_4;
      end

      LI_4: begin
        con_ready = 1;
        ctrl_IDSS_LE_select = 3'b100;

        next_state = LI_shift;
      end

      LI_shift: begin
        ctrl_IDSS_shift = 1;
        calc_1_done_next = 0; // Reset flag

        load_I_counter_next = load_I_counter - 1;
        next_state = (last_partial_load_I) ? CC_1 : LI_1;
      end

      // OPERATION
      CC_1: begin
        con_ready = 1;
        ctrl_IDSS_LE_select = 3'b001; 
        ctrl_ODS_sel_out = 2'b00; // ODS: in --> reg_1_1
        ctrl_ODS_shift = 1;       // ODS: shift first 3 values
        ctrl_to_KDS_cycle_enable = 1;

        next_state = CC_2;
      end

      CC_2: begin
        con_ready = 1;
        ctrl_IDSS_LE_select = 3'b010; 
        ctrl_ODS_sel_out = 2'b01; // ODS: in --> reg_2_1
        ctrl_to_KDS_cycle_enable = 1;

        next_state = CC_3;
      end

      CC_3: begin
        con_ready = 1;
        ctrl_IDSS_LE_select = 3'b011; 
        ctrl_ODS_sel_out = 2'b10; // ODS: in --> reg_3_1
        ctrl_to_KDS_cycle_enable = 1;

        next_state = CC_4;
      end

      CC_4: begin
        con_ready = 1;
        ctrl_IDSS_LE_select = 3'b100;
        ctrl_ODS_sel_out = 2'b00;  // ODS: in --> reg_1_1
        ctrl_ODS_shift = 1;        // ODS: shift first 3 values to out
        ctrl_to_KDS_cycle_enable = 1;
        output_valid_reg_next = (calc_1_done) ? 1 : 0;

        next_state = CC_5;
      end

      CC_5: begin
        con_ready = 1;
        ctrl_ODS_sel_out = 2'b01;  // ODS: in --> reg_2_1
        ctrl_ODS_shift = 1;        // ODS: shift second 3 values to out
        ctrl_to_KDS_cycle_enable = 1;
        driving_cons = 1;
        add_to_chout = 1; // Will add +3 to ch out in the next cycle
        output_valid_reg_next = (calc_1_done) ? 1 : 0;

        next_state = CC_6;
      end

      CC_6: begin
        con_ready = 1;
        ctrl_ODS_sel_out = 2'b10;  // ODS: in --> reg_3_1
        ctrl_IDSS_shift = 1; 
        ctrl_to_KDS_cycle_enable = 1;
        driving_cons = 1; 
        inc_x = (calc_1_done) ? 1 : 0; // happens only if output is "valid" --> Delayed due to pipeline
        calc_1_done_next = 1;

        load_K_counter_next = 3'b101; //5
        load_I_counter_next = 2'b10;  //2
        next_state = (!last_x) ? CC_1 : (!last_y) ? LI_1 : (!last_ch_out) ? LK_1 : IDLE;
      end

    endcase
  end
endmodule
