`define log2(VALUE) ( (VALUE) == ( 1 ) ? 0 : (VALUE) < ( 2 ) ? 1 : (VALUE) < ( 4 ) ? 2 : (VALUE)< (8) ? 3:(VALUE) < ( 16 )  ? 4 : (VALUE) < ( 32 )  ? 5 : (VALUE) < ( 64 )  ? 6 : (VALUE) < ( 128 ) ? 7 : (VALUE) < ( 256 ) ? 8 : (VALUE) < ( 512 ) ? 9 : (VALUE) < ( 1024 ) ? 10 : (VALUE) < ( 2048 ) ? 11: (VALUE) < ( 4096 ) ? 12 : (VALUE) < ( 8192 ) ? 13 : (VALUE) < ( 16384 ) ? 14 : (VALUE) < ( 32768 ) ? 15 : (VALUE) < ( 65536 ) ? 16 : (VALUE) < ( 131072 ) ? 17 : (VALUE) < ( 262144 ) ? 18 : (VALUE) < ( 524288 ) ? 19 :  (VALUE) < ( 1048576 ) ? 20 : -1)
//`define TLB_MULTIHIT
module check_ram
  #(
    parameter ADDR_WIDTH   = 32,
    parameter PAGE_SIZE    = 4096, // 4kB
    parameter SET_WIDTH    = 5, 
    parameter OFFSET_WIDTH = 4 
    )
  (
   input  logic                                clk_i,
   input  logic                                rst_ni,
   input  logic [ADDR_WIDTH-1:0]               in_addr,
   input  logic                                rw_type, //1 => write, 0=> read 
   input  logic                                ram_we,
   input  logic [SET_WIDTH+OFFSET_WIDTH+1-1:0] port0_addr,
   input  logic [SET_WIDTH+OFFSET_WIDTH+1-1:0] port1_addr,
   input  logic [ADDR_WIDTH-1:0]               ram_wdata,
   input  logic                                send_outputs,
   input  logic                                searching,
   input  logic [OFFSET_WIDTH-1:0]             offset_addr_d,
   input  logic                                start_search,
   output logic [SET_WIDTH+OFFSET_WIDTH+1-1:0] hit_addr,
   output logic                                master,
   output logic                                hit,
   output logic                                multi_hit,
   output logic                                prot
   );

   localparam IGNORE_LSB = `log2(PAGE_SIZE-1); // 12  

   logic [31:0]                         port0_data_i; // RAM write data input
   logic [31:0]                         port0_data_o, port1_data_o; // RAM read data outputs
   logic                                port0_hit, port1_hit; // Ram output matches in_addr
      
   // Hit FSM Signals
   typedef enum                         logic {SEARCH, HIT} hit_state_t;
   hit_state_t                          hit_SP; // Hit FSM state
   hit_state_t                          hit_SN; // Hit FSM next state

   // Multi Hit FSM signals
`ifdef TLB_MULTIHIT
   typedef enum                         logic[1:0] {NO_HITS, ONE_HIT, MULTI_HIT} multi_state_t;
   multi_state_t                        multi_SP; // Multi Hit FSM state
   multi_state_t                        multi_SN; // Multi Hit FSM next state

   logic [SET_WIDTH+OFFSET_WIDTH+1-1:0] hit_addr_saved; 
   logic                                master_saved;
`endif   
   
  //// --------------- Block RAM (Dual Port) -------------- ////
   ram #(
         .ADDR_WIDTH(SET_WIDTH+OFFSET_WIDTH+1),
         .DATA_WIDTH(32)
         )
   ram_0
     (
             .clk   (clk_i)        ,
             .we    (ram_we)       ,
             .addr0 (port0_addr)   ,
             .addr1 (port1_addr)   ,
             .d_i   (ram_wdata)    ,
             .d0_o  (port0_data_o) ,
             .d1_o  (port1_data_o)
             );

   //// Check Ram Outputs
   assign port0_hit = (port0_data_o[0] == 1'b1) && (in_addr[ADDR_WIDTH-1: IGNORE_LSB] == port0_data_o[4+ADDR_WIDTH-IGNORE_LSB-1:4]);
   assign port1_hit = (port1_data_o[0] == 1'b1) && (in_addr[ADDR_WIDTH-1: IGNORE_LSB] == port1_data_o[4+ADDR_WIDTH-IGNORE_LSB-1:4]);
   //// ----------------------------------------------------- /////

   //// ------------------- Check if Hit ------------------------ ////  
   // FSM
   always_ff @(posedge clk_i) begin
      if (rst_ni == 0) begin
         hit_SP <= SEARCH;
      end else begin
         hit_SP <= hit_SN;
      end
   end

   always_comb begin
      hit_SN   = hit_SP;
      hit      = 1'b0;
      hit_addr = 0;
      master   = 1'b0;
      unique case(hit_SP)
        SEARCH :
          if (searching)
            if (port0_hit || port1_hit) begin
               hit_SN   = HIT;
               hit      = 1'b1;
               hit_addr = port0_hit ? {port0_addr[SET_WIDTH+OFFSET_WIDTH:OFFSET_WIDTH], offset_addr_d} :
                          port1_hit ? {port1_addr[SET_WIDTH+OFFSET_WIDTH:OFFSET_WIDTH], offset_addr_d} :
                          0;
               master   = port0_hit ? port0_data_o[3] :
                          port1_hit ? port1_data_o[3] :
                          1'b0;
            end

        HIT : begin
`ifdef TLB_MULTIHIT // Since the search continues after the first hit, it needs to be saved to be accessed later.
           hit      = 1'b1;
           hit_addr = hit_addr_saved;
           master   = master_saved;
`endif           
           if (send_outputs)
             hit_SN = SEARCH;
        end        
      endcase // case (hit_SP)
   end // always_comb begin

   //// ------------------------------------------- ////      

   assign prot = searching && port0_hit ? ((~port0_data_o[2] && rw_type) || (~port0_data_o[1] && ~rw_type)) :
                 searching && port1_hit ? ((~port1_data_o[2] && rw_type) || (~port1_data_o[1] && ~rw_type)) :
                 1'b0;                   

   //// ------------------- Multi ------------------- ////
`ifdef TLB_MULTIHIT
   
   always_ff @(posedge clk_i) begin
      if (rst_ni == 0) begin
         hit_addr_saved <= 0;
         master_saved <= 1'b0;
      end else if (searching) begin
         hit_addr_saved <= hit_addr;
         master_saved <= master;
      end
   end
   
   // FSM
   always_ff @(posedge clk_i) begin
      if (rst_ni == 0) begin
         multi_SP <= NO_HITS;
      end else begin
         multi_SP <= multi_SN;
      end
   end

   always_comb begin
      multi_SN  = multi_SP;
      multi_hit = 1'b0;
      unique case(multi_SP)
        NO_HITS :
          if(searching && (port0_hit && port1_hit)) begin
             multi_SN  = MULTI_HIT;
             multi_hit = 1'b1;
          end else if(searching && (port0_hit || port1_hit))
            multi_SN = ONE_HIT;

        ONE_HIT :
          if(searching && (port0_hit || port1_hit)) begin
             multi_SN  = MULTI_HIT;
             multi_hit = 1'b1;
          end else if (send_outputs)
            multi_SN = NO_HITS;
        
        MULTI_HIT : begin
          multi_hit = 1'b1;
           if (send_outputs)
             multi_SN = NO_HITS;
        end
      
      endcase // case (multi_SP)
   end // always_comb begin
      
`else // !`ifdef TLB_MULTIHIT
   assign multi_hit = searching && port0_hit && port1_hit;
`endif // !`ifdef TLB_MULTIHIT
   //// ------------------------------------------- ////      
           
endmodule

   
