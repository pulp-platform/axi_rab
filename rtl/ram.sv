module ram
  #(
    parameter ADDR_WIDTH = 10,
    parameter DATA_WIDTH = 36
    )
  (
   input                   clk,
   input                   we,
   input  [ADDR_WIDTH-1:0] addr0,
   input  [ADDR_WIDTH-1:0] addr1,
   input  [DATA_WIDTH-1:0] d_i,
   output [DATA_WIDTH-1:0] d0_o,
   output [DATA_WIDTH-1:0] d1_o
   );

   localparam DEPTH = 2**ADDR_WIDTH;
   
   reg [DATA_WIDTH-1:0] ram[DEPTH];
   reg [ADDR_WIDTH-1:0]  raddr0;
   reg [ADDR_WIDTH-1:0]  raddr1;
      
   always_ff @(posedge clk) begin
      if(we == 1'b1) begin
         ram[addr0] <= d_i;
      end
      raddr0 <= addr0;
      raddr1 <= addr1;
   end
   assign d0_o = ram[raddr0];
   assign d1_o = ram[raddr1];

endmodule // ram
