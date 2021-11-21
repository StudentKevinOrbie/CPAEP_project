class Driver #(config_t cfg);

  virtual intf #(cfg) intf_i;

  mailbox #(Transaction_Feature #(cfg)) gen2drv_feature;
  mailbox #(Transaction_Kernel #(cfg)) gen2drv_kernel;
  typedef Transaction_Kernel #(cfg) Transaction_Kernel_configured;
  typedef Transaction_Feature #(cfg) Transaction_Feature_configured;

  function new(
    virtual intf #(cfg) i,
    mailbox #(Transaction_Feature #(cfg)) g2d_feature,
    mailbox #(Transaction_Kernel #(cfg)) g2d_kernel
  );
    intf_i = i;
    gen2drv_feature = g2d_feature;
    gen2drv_kernel = g2d_kernel;
  endfunction : new

  task reset;
    $display("[DRV] ----- Reset Started -----");
     //asynchronous start of reset
    intf_i.cb.start   <= 0;
    intf_i.cb.con_valid <= 0;
    intf_i.cb.arst_n  <= 0;
    repeat (2) @(intf_i.cb);
    intf_i.cb.arst_n  <= 1; //synchronous release of reset
    repeat (2) @(intf_i.cb);
    $display("[DRV] -----  Reset Ended  -----");
  endtask

  // Loads num_kernels to the dut
  task load_kernels(input int start_ch_out, num_kernels, input Transaction_Kernel_configured tract_kernel);
    intf_i.cb.con_valid <= 1;
    $display("[DRV] Kernel --> Loading kernels %d to %d", start_ch_out, start_ch_out + num_kernels - 1);

    for (int outch = start_ch_out; outch < start_ch_out + num_kernels; outch++) begin

      // Load entire Kernel
      for(int inch = 0; inch < cfg.INPUT_NB_CHANNELS; inch++) begin
        for(int kx = cfg.KERNEL_SIZE - 1; kx >= 0; kx--) begin
          //$display("[DRV] Kernel --> outch: %d, kx: %d, inch: %d", outch, kx, inch);
          //$display(tract_kernel);
          assert (!$isunknown(tract_kernel.kernel[0][kx][inch][outch]));
          assert (!$isunknown(tract_kernel.kernel[1][kx][inch][outch]));
          assert (!$isunknown(tract_kernel.kernel[2][kx][inch][outch]));
          intf_i.cb.to_con_1 <= tract_kernel.kernel[0][kx][inch][outch];
          intf_i.cb.to_con_2 <= tract_kernel.kernel[1][kx][inch][outch];
          intf_i.cb.to_con_3 <= tract_kernel.kernel[2][kx][inch][outch];

          @(intf_i.cb); // Wait 1 clock cycle
        end
      end
      
    end

    intf_i.cb.con_valid <= 0;
  endtask

  // Loads a single input slide (12 Values) to the dut
  task load_input_slice(input int start_x, start_y, input Transaction_Feature_configured tract_feature);
    intf_i.cb.con_valid <= 1;

    for(int inch=0; inch < cfg.INPUT_NB_CHANNELS; inch++) begin
      //$display("[DRV] Feature --> start_x: %d, start_y: %d, inch: %d", start_x, start_y, inch);
      if (start_x == -1 || start_x >= cfg.FEATURE_MAP_WIDTH) begin
        intf_i.cb.to_con_1 <= 0;
        intf_i.cb.to_con_2 <= 0;
        intf_i.cb.to_con_3 <= 0;
      end else begin
        if(start_y == -1 || start_y >= cfg.FEATURE_MAP_HEIGHT) begin
          intf_i.cb.to_con_1 <= 0; // Zero pad
        end else begin
          assert (!$isunknown(tract_feature.inputs[start_y][start_x][inch]));
          intf_i.cb.to_con_1 <= tract_feature.inputs[start_y][start_x][inch];
        end

        if(start_y + 1 >= cfg.FEATURE_MAP_HEIGHT) begin
          intf_i.cb.to_con_2 <= 0; // Zero pad
        end else begin
          assert (!$isunknown(tract_feature.inputs[start_y + 1][start_x][inch]));
          intf_i.cb.to_con_2 <= tract_feature.inputs[start_y + 1][start_x][inch];
        end

        if(start_y + 2 >= cfg.FEATURE_MAP_HEIGHT) begin
          intf_i.cb.to_con_3 <= 0; // Zero pad
        end else begin
          assert (!$isunknown(tract_feature.inputs[start_y + 2][start_x][inch]));
          intf_i.cb.to_con_3 <= tract_feature.inputs[start_y + 2][start_x][inch];
        end
      end

      @(intf_i.cb);
    end

    intf_i.cb.con_valid <= 0;
  endtask

  task run();
    bit first = 1;

    // Get a transaction with kernel from the Generator
    // Kernel remains same throughput the verification
    Transaction_Kernel #(cfg) tract_kernel;
    gen2drv_kernel.get(tract_kernel);

    $display("[DRV] -----  Start execution -----");

    forever begin
      time starttime;
      // Get a transaction with feature from the Generator
      Transaction_Feature #(cfg) tract_feature;
      gen2drv_feature.get(tract_feature);

      $display("[DRV] Giving start signal");
      intf_i.cb.start <= 1;
      starttime = $time();
      @(intf_i.cb);
      intf_i.cb.start <= 0;

      $display("[DRV] ----- Driving a new input feature map -----");
      for(int outch=0; outch < cfg.OUTPUT_NB_CHANNELS; outch = outch + 6) begin
        $display("[DRV] %.2f %% of the input is transferred", ((outch)*100.0)/cfg.OUTPUT_NB_CHANNELS);

        if (outch == 30) begin
          load_kernels(outch, 2, tract_kernel);
        end else begin
          load_kernels(outch, 6, tract_kernel);
        end

        for(int y = -1; y <= cfg.FEATURE_MAP_HEIGHT - 2; y++) begin

          load_input_slice(-1, y, tract_feature);
          @(intf_i.cb); // Shift state
          load_input_slice(0, y, tract_feature);
          @(intf_i.cb); // Shift state
          load_input_slice(1, y, tract_feature);
          @(intf_i.cb); // Shift state

          for(int x = 2; x <= cfg.FEATURE_MAP_WIDTH; x++) begin

            load_input_slice(x, y, tract_feature);

            repeat (2) @(intf_i.cb); // 2 Recieve data states

          end

          if (outch == 30 && y == (cfg.FEATURE_MAP_HEIGHT - 2)) begin
            repeat (11) @(intf_i.cb); // Clear out pipeline
          end else begin
            repeat (12) @(intf_i.cb); // Clear out pipeline
          end
        end
      end

      $display("\n\n------------------\nLATENCY: input processed in %t\n------------------\n", $time() - starttime);

      //add mac cost to energy:
      tbench_top.energy += 0.0001 * cfg.KERNEL_SIZE * cfg.KERNEL_SIZE * cfg.INPUT_NB_CHANNELS * cfg.FEATURE_MAP_WIDTH * cfg.FEATURE_MAP_HEIGHT * cfg.OUTPUT_NB_CHANNELS;

      $display("------------------\nENERGY:  %0d\n------------------\n", tbench_top.energy);

      $display("------------------\nENERGYxLATENCY PRODUCT (/1e9):  %0d\n------------------\n", (longint'(tbench_top.energy) * ($time() - starttime))/1e9);

      tbench_top.energy=0;

      $display("\n------------------\nAREA (breakdown see start): %0d\n------------------\n", tbench_top.area);

    end
  endtask : run
endclass : Driver
