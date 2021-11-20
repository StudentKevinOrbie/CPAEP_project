module ODS #(
    parameter int IO_DATA_WIDTH = 16
  )
  (input logic clk,
   input logic arst_n_in,  //asynchronous reset, active low

   input logic [IO_DATA_WIDTH-1:0] in, 
   output logic [IO_DATA_WIDTH-1:0] out_1, 
   output logic [IO_DATA_WIDTH-1:0] out_2, 
   output logic [IO_DATA_WIDTH-1:0] out_3,

   input logic [1:0] sel_out,
   input logic shift
  );

  // r_row_col
  //       --> r_1_1 --> r_1_2 -- out_1 -->
  // -- in --> r_2_1 --> r_2_2 -- out_2 -->
  //       --> r_3_1 --> r_3_2 -- out_3 -->
  `REG(IO_DATA_WIDTH, r_1_1);
  `REG(IO_DATA_WIDTH, r_1_2);
  `REG(IO_DATA_WIDTH, r_2_1);
  `REG(IO_DATA_WIDTH, r_2_2);
  `REG(IO_DATA_WIDTH, r_3_1);
  `REG(IO_DATA_WIDTH, r_3_2);

  // ------------ Connections ------------
  // Passing values
  assign r_1_1_next = in;
  assign r_2_1_next = in;
  assign r_3_1_next = in;

  assign r_1_2_next = r_1_1;
  assign r_2_2_next = r_2_1;
  assign r_3_2_next = r_3_1;

  assign out_1 = r_1_2;
  assign out_2 = r_2_2;
  assign out_3 = r_3_2;

  assign r_1_2_WE = shift;
  assign r_2_2_WE = shift;
  assign r_3_2_WE = shift;

  // Write Enables
  always @(clk)
  begin
    r_1_1_WE <= 1'b0;
    r_2_1_WE <= 1'b0;
    r_3_1_WE <= 1'b0;
    case(sel_out)
      2'b00:
        r_1_1_WE <= 1'b1;
      2'b01:
        r_2_1_WE <= 1'b1;
      2'b10:
        r_3_1_WE <= 1'b1;
      default:
        begin
          r_1_1_WE <= 1'b0;
          r_2_1_WE <= 1'b0;
          r_3_1_WE <= 1'b0;
        end
  end

endmodule
