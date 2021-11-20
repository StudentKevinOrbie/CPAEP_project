module super_MAC #(
    parameter int IN_WIDTH = 16,
    parameter int ACCUMULATOR_WIDTH = 32,
    parameter int OUTPUT_WIDTH = 32
  )
  (input logic clk,
   input logic arst_n_in,  //asynchronous reset, active low

   //system inputs
   input logic signed [IN_WIDTH-1:0] I_in [35:0],
   input logic signed [IN_WIDTH-1:0] K_in [35:0],

   //system outputs
   output logic signed [OUTPUT_WIDTH-1:0] out 
  );

genvar i;

// Multipliers: 36
`REG(ACCUMULATOR_WIDTH*36, mul_out);

generate
for (i=0;i<36;i=i+1) begin
    multiplier #( .A_WIDTH(IN_WIDTH),
                  .B_WIDTH(IN_WIDTH),
                  .OUT_WIDTH(ACCUMULATOR_WIDTH),
                  .OUT_SCALE(0))
    mul
    (.a(I_in[i]),
     .b(K_in[i]),
     .out(mul_out_next[i*ACCUMULATOR_WIDTH:(i+1)*ACCUMULATOR_WIDTH-1]));
end
endgenerate

// ADDER: 18
`REG(ACCUMULATOR_WIDTH*9, sum_1);
logic signed [ACCUMULATOR_WIDTH-1:0] sum_sub_1 [17:0];

//logic [....][ACUMMULATOR_WIDTH-1:0 mul_out_reformatted;
//assing mul_out_reformatted = mul_out;

generate
for (i=0;i<18;i=i+1) begin
    adder #( .A_WIDTH(ACCUMULATOR_WIDTH),
           .B_WIDTH(ACCUMULATOR_WIDTH),
           .OUT_WIDTH(ACCUMULATOR_WIDTH),
           .OUT_SCALE(0))
    add
    (.a(mul_out[2*i*ACCUMULATOR_WIDTH:(2*i+1)*ACCUMULATOR_WIDTH-1]),
     .b(mul_out[(2*i + 1)*ACCUMULATOR_WIDTH:(2*i+2)*ACCUMULATOR_WIDTH-1]),
     .out(sum_sub_1[i]));
end
endgenerate

// ADDER: 9
generate
for (i=0;i<9;i=i+1) begin
    adder #( .A_WIDTH(ACCUMULATOR_WIDTH),
           .B_WIDTH(ACCUMULATOR_WIDTH),
           .OUT_WIDTH(ACCUMULATOR_WIDTH),
           .OUT_SCALE(0))
    add
    (.a(sum_sub_1[2*i]),
     .b(sum_sub_1[2*i + 1]),
     .out(sum_1_next[i*ACCUMULATOR_WIDTH:(i+1)*ACCUMULATOR_WIDTH-1]));
end
endgenerate

// ADDER: 4
`REG(ACCUMULATOR_WIDTH*3, sum_2);
logic signed [ACCUMULATOR_WIDTH-1:0] sum_sub_2 [3:0];

generate
for (i=0;i<4;i=i+1) begin
    adder #( .A_WIDTH(ACCUMULATOR_WIDTH),
           .B_WIDTH(ACCUMULATOR_WIDTH),
           .OUT_WIDTH(ACCUMULATOR_WIDTH),
           .OUT_SCALE(0))
    add
    (.a(sum_1[2*i*ACCUMULATOR_WIDTH:(2*i+1)*ACCUMULATOR_WIDTH-1]),
     .b(sum_1[(2*i+1)*ACCUMULATOR_WIDTH :(2*i+2)*ACCUMULATOR_WIDTH-1]),
     .out(sum_sub_2[i]));
end
endgenerate

// ADDER: 2
adder #( .A_WIDTH(ACCUMULATOR_WIDTH),
         .B_WIDTH(ACCUMULATOR_WIDTH),
         .OUT_WIDTH(ACCUMULATOR_WIDTH),
         .OUT_SCALE(0))
add_1_4
    (.a(sum_sub_2[0]),
     .b(sum_sub_2[1]),
     .out(sum_2_next[0:ACCUMULATOR_WIDTH*1-1]));

adder #( .A_WIDTH(ACCUMULATOR_WIDTH),
         .B_WIDTH(ACCUMULATOR_WIDTH),
         .OUT_WIDTH(ACCUMULATOR_WIDTH),
         .OUT_SCALE(0))
add_2_4
    (.a(sum_sub_2[2]),
     .b(sum_sub_2[3]),
     .out(sum_2_next[ACCUMULATOR_WIDTH*1:ACCUMULATOR_WIDTH*2-1]));

assign sum_2_next[ACCUMULATOR_WIDTH*2:ACCUMULATOR_WIDTH*3-1] = sum_1[ACCUMULATOR_WIDTH*8: ACCUMULATOR_WIDTH*9-1];

// ADDER: 1
logic signed [ACCUMULATOR_WIDTH-1:0] sum_sub_3;
logic signed [ACCUMULATOR_WIDTH-1:0] sum_3;

adder #( .A_WIDTH(ACCUMULATOR_WIDTH),
         .B_WIDTH(ACCUMULATOR_WIDTH),
         .OUT_WIDTH(ACCUMULATOR_WIDTH),
         .OUT_SCALE(0))
add_1_5
    (.a(sum_2[0:ACCUMULATOR_WIDTH-1]),
     .b(sum_2[ACCUMULATOR_WIDTH:2*ACCUMULATOR_WIDTH-1]),
     .out(sum_sub_3));

// ADDER: 1
adder #( .A_WIDTH(ACCUMULATOR_WIDTH),
         .B_WIDTH(ACCUMULATOR_WIDTH),
         .OUT_WIDTH(ACCUMULATOR_WIDTH),
         .OUT_SCALE(0))
add_last
    (.a(sum_sub_3),
     .b(sum_2[ACCUMULATOR_WIDTH*2:ACCUMULATOR_WIDTH*3-1]),
     .out(sum_3));

assign out = sum_3;

endmodule
