class Monitor #( config_t cfg);
  virtual intf #(cfg) intf_i;
  mailbox #(Transaction_Output_Word#(cfg)) mon2chk;

  function new(
    virtual intf #(cfg) intf_i,
    mailbox #(Transaction_Output_Word#(cfg)) m2c
  );
    this.intf_i = intf_i;
    mon2chk = m2c;
  endfunction : new

  task run;
    @(intf_i.cb iff intf_i.arst_n);
    forever
    begin
      Transaction_Output_Word #(cfg) tract_output_1, tract_output_2, tract_output_3;
      tract_output_1 = new();
      tract_output_2 = new();
      tract_output_3 = new();

      @(intf_i.cb iff intf_i.cb.output_valid);
      tract_output_1.con_1 = intf_i.cb.con_1;
      tract_output_1.output_x = intf_i.cb.output_x;
      tract_output_1.output_y = intf_i.cb.output_y;
      tract_output_1.output_ch = intf_i.cb.output_ch;

      tract_output_2.con_2 = intf_i.cb.con_2;
      tract_output_3.con_3 = intf_i.cb.con_3;
      mon2chk.put(tract_output_1);
      mon2chk.put(tract_output_2);
      mon2chk.put(tract_output_3);
    end
  endtask

endclass : Monitor
