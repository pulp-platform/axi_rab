`define log2(VALUE) ( (VALUE) < ( 1 ) ? 0 : (VALUE) < ( 2 ) ? 1 : (VALUE) < ( 4 ) ? 2 : (VALUE)< (8) ? 3:(VALUE) < ( 16 )  ? 4 : (VALUE) < ( 32 )  ? 5 : (VALUE) < ( 64 )  ? 6 : (VALUE) < ( 128 ) ? 7 : (VALUE) < ( 256 ) ? 8 : (VALUE) < ( 512 ) ? 9 : (VALUE) < ( 1024 ) ? 10 : (VALUE) < ( 2048 ) ? 11: (VALUE) < ( 4096 ) ? 12 : (VALUE) < ( 8192 ) ? 13 : (VALUE) < ( 16384 ) ? 14 : (VALUE) < ( 32768 ) ? 15 : (VALUE) < ( 65536 ) ? 16 : (VALUE) < ( 131072 ) ? 17 : (VALUE) < ( 262144 ) ? 18 : (VALUE) < ( 524288 ) ? 19 :  (VALUE) < ( 1048576 ) ? 20 : -1)
//`define TLB_MULTIHIT
module tlb_l2
  #(
    parameter ADDR_WIDTH             = 32,
    parameter SET                    = 16,
    parameter NUM_OFFSET             = 2, //per port. There are 2 ports.
    parameter PAGE_SIZE              = 4096, // 4kB
    parameter PARALLEL_NUM           = 8,
    parameter HIT_OFFSET_STORE_WIDTH = 1 // Num of bits of VA RAM offset stored. This should not be greater than OFFSET_WIDTH
    )
   (
    input  logic                  clk_i,
    input  logic                  rst_ni,
    input  logic [ADDR_WIDTH-1:0] in_addr,
    input  logic                  rw_type, //1 => write, 0=> read 
    input  logic                  l1_miss,
    input  logic                  we,
    input  logic [31:0]           waddr,
    input  logic [31:0]           wdata,
    input  logic                  l2_trans_sent,
    output logic                  miss_l2,
    output logic                  hit_l2,
    output logic                  multiple_hit_l2,
    output logic                  prot_l2,
    output logic                  l2_busy,    
    output logic [ADDR_WIDTH-1:0] out_addr   
    );

   localparam VA_RAM_DEPTH      = SET * NUM_OFFSET * 2;
   localparam PA_RAM_DEPTH      = VA_RAM_DEPTH * PARALLEL_NUM;
   localparam VA_RAM_ADDR_WIDTH = `log2(VA_RAM_DEPTH)-1;
   localparam PA_RAM_ADDR_WIDTH = `log2(PA_RAM_DEPTH)-1;
   localparam SET_WIDTH         = `log2(SET)-1;
   localparam OFFSET_WIDTH      = `log2(NUM_OFFSET)-1;
   localparam LL_WIDTH          = `log2(PARALLEL_NUM)-1;
   localparam IGNORE_LSB        = `log2(PAGE_SIZE -1);
      
   logic [PARALLEL_NUM-1:0]                                hit, prot, multi_hit;
   logic [PARALLEL_NUM-1:0]                                ram_we;
   logic                                                   last_search;
   logic [SET_WIDTH+OFFSET_WIDTH+1-1:0]                    ram_waddr;
   logic [PARALLEL_NUM-1:0] [SET_WIDTH+OFFSET_WIDTH+1-1:0] hit_addr;
   logic                                                   pa_ram_we, read_pa;
   logic [PA_RAM_ADDR_WIDTH-1:0]                           pa_port0_raddr,pa_port0_waddr; // PA RAM read, Write addr;
   logic [PA_RAM_ADDR_WIDTH-1:0]                           pa_port0_addr; // PA RAM addr
   logic [31:0]                                            pa_port0_data_o;
   logic                                                   prot_top;
   logic                                                   first_hit_top, hit_top;
   logic                                                   send_outputs; 
   int                                                     hit_block_num;
   logic                                                   multi_hit_top;
   
   logic                                                   searching, search_done;
   logic                                                   searching_next;
   logic [OFFSET_WIDTH-1:0]                                offset_addr, offset_addr_d;
   logic [SET_WIDTH+OFFSET_WIDTH+1-1:0]                    port0_addr, port0_raddr; // VA RAM port0 addr
   logic [SET_WIDTH+OFFSET_WIDTH+1-1:0]                    port1_addr; // VA RAM port1 addr
   logic [SET_WIDTH-1:0]                                   set_num;
   logic [ADDR_WIDTH-1:0]                                  in_addr_reg, in_addr_saved;
   logic                                                   rw_type_saved;
      
   genvar                                                  z;

   logic                                                   multi_hit_disabled;
   logic                                                   l2_busy_next, last_search_next;
   
   // Control FSM
   typedef enum                                            logic[1:0] {IDLE, SEARCH, DONE} cntrl_state_t;
   cntrl_state_t                                           cntrl_SP; // Present state
   cntrl_state_t                                           cntrl_SN; // Next State

   // Output FSM
   typedef enum                                            logic[1:0] {OUT_IDLE, SEND_OUTPUT, OUT_SENT} out_state_t;  
   out_state_t                                             out_SP; // Present state
   out_state_t                                             out_SN; // Next State
   
   logic                                                   miss_l2_next;
   logic                                                   hit_l2_next;
   logic                                                   prot_l2_next;
   logic                                                   multiple_hit_l2_next;

   logic [OFFSET_WIDTH-1:0]                                offset_start_addr, offset_end_addr, offset_first_addr;
        
   // Generate the VA Block rams and their surrounding logic
   generate
      for (z = 0; z < PARALLEL_NUM; z++) begin
         check_ram
           #(
    	       .ADDR_WIDTH   (ADDR_WIDTH) ,
    	       .PAGE_SIZE    (PAGE_SIZE)  ,             
    	       .SET_WIDTH    (SET_WIDTH)  ,
    	       .OFFSET_WIDTH (OFFSET_WIDTH)
             )
         u_check_ram
             (
              .clk_i         (clk_i)         ,
              .rst_ni        (rst_ni)        ,
              .in_addr       (in_addr_saved) ,
              .rw_type       (rw_type_saved) ,
              .ram_we        (ram_we[z])     ,
              .port0_addr    (port0_addr)    ,
              .port1_addr    (port1_addr)    ,
              .ram_wdata     (wdata)         ,
              .send_outputs  (send_outputs)  ,
              .searching     (searching)     ,
              .offset_addr_d (offset_addr_d) ,
              .start_search  (l1_miss)       ,
              .hit_addr      (hit_addr[z])   ,
              .hit           (hit[z])        ,
              .multi_hit     (multi_hit[z])  ,
              .prot          (prot[z])
              );
      end // for (z = 0; z < N_PORTS; z++)
   endgenerate
        
`ifdef TLB_MULTIHIT
   assign multi_hit_disabled = 1'b0;
`else
   assign multi_hit_disabled = 1'b1;
`endif

   ////////////////// ---------------- Control and Address --------------- ////////////////////////
   // FSM
   always_ff @(posedge clk_i) begin
      if (rst_ni == 0) begin
         cntrl_SP <= IDLE;
      end else begin
         cntrl_SP <= cntrl_SN;
      end
   end   

   always_comb begin
      cntrl_SN          = cntrl_SP;
      searching_next    = 1'b0;
      l2_busy_next      = 1'b1;
      search_done  = 1'b0; 
      last_search_next  = 1'b0;
      offset_first_addr = 0;
      unique case (cntrl_SP)
        IDLE :
          if (l1_miss) begin
             cntrl_SN          = SEARCH;
             offset_first_addr = offset_start_addr;
          end else if (~l1_miss) begin
             l2_busy_next      = 1'b0;
          end

        SEARCH :
          // Terminate search if prot or multi is encountered.
          // If multi hit is disabled, terminate search when hit is encountered, else, search till last offset addr.
          if (last_search || (hit_top && multi_hit_disabled) || prot_top || multi_hit_top) begin
             cntrl_SN         = DONE;
             searching_next   = 1'b0;
             search_done = 1'b1;
          end else begin
             searching_next = 1'b1;
             if (offset_addr == offset_end_addr)
               last_search_next = 1'b1;
          end

        DONE : begin          
          if (l2_trans_sent || miss_l2 || prot_l2 || multiple_hit_l2)
            cntrl_SN = IDLE;
        end
      endcase // case (prot_SP)
   end // always_comb begin

   always_ff @(posedge clk_i) begin
      if (rst_ni == 0) begin
         last_search <= 1'b0;
         searching   <= 1'b0;
      end else begin
         last_search <= last_search_next;
         searching   <= searching_next;
      end
   end
   
   // Indicate L2 is busy
   always_ff @(posedge clk_i) begin
      if (rst_ni == 0) begin
         l2_busy <= 1'b0;
      end else begin
         l2_busy <= l2_busy_next;
      end
   end

   // address to search, rw_type
   always_ff @(posedge clk_i) begin
      if (rst_ni == 0) begin
         in_addr_reg   <= 0;
         rw_type_saved <= 1'b0;
      end else if (l1_miss) begin
         in_addr_reg   <= in_addr;
         rw_type_saved <= rw_type;
      end
   end
   assign in_addr_saved = l1_miss ? in_addr : in_addr_reg;
   assign set_num       = in_addr_saved[SET_WIDTH+IGNORE_LSB -1 : IGNORE_LSB];
   
   assign port0_raddr[OFFSET_WIDTH] = 1'b0;
   assign port1_addr [OFFSET_WIDTH] = 1'b1;
   
   assign port0_raddr[OFFSET_WIDTH-1:0] = offset_addr;
   assign port1_addr [OFFSET_WIDTH-1:0] = offset_addr;
   
   assign port0_raddr[SET_WIDTH+OFFSET_WIDTH : OFFSET_WIDTH+1] = set_num;
   assign port1_addr [SET_WIDTH+OFFSET_WIDTH : OFFSET_WIDTH+1] = set_num;

   assign port0_addr = ram_we ? ram_waddr : port0_raddr;

   // Offset
   always_ff @(posedge clk_i) begin
      offset_addr_d  <= offset_addr;
      if (rst_ni == 0) begin
         offset_addr <= 0;
      end else if (l1_miss) begin
         offset_addr <= offset_first_addr;
      end else if (cntrl_SP == SEARCH) begin
         offset_addr <= offset_addr + 1'b1;
      end
   end

   // Store the offset addr for hit to reduce latency for next search.
   generate
      if (HIT_OFFSET_STORE_WIDTH > 0) begin
`ifndef TLB_MULTIHIT 
         logic [SET-1:0][HIT_OFFSET_STORE_WIDTH-1:0]             hit_offset_addr; // Contains offset addr for previous hit for every SET.
         logic [SET_WIDTH+OFFSET_WIDTH+1-1:0]                    hit_addr_reg;
         
         assign offset_start_addr = { hit_offset_addr[set_num],{OFFSET_WIDTH-HIT_OFFSET_STORE_WIDTH{1'b0}} };
         assign offset_end_addr   = hit_offset_addr[set_num]-1'b1;

         // Register the hit addr
         always_ff @(posedge clk_i) begin
            if (rst_ni == 0) begin
               hit_addr_reg <= 0;
            end else begin
               hit_addr_reg <= hit_addr[hit_block_num];
            end
         end
         
         // Store hit addr for each set. The next search in the same set will start from the saved addr.
         always_ff @(posedge clk_i) begin
            if (rst_ni == 0) begin
               hit_offset_addr <= 0;
            end else if (hit_l2) begin
               hit_offset_addr[set_num][HIT_OFFSET_STORE_WIDTH-1:0] <= hit_addr_reg[OFFSET_WIDTH-1 : (OFFSET_WIDTH - HIT_OFFSET_STORE_WIDTH)];
            end
         end
`else // No need to store offset if multihit is enabled because the entire SET is searched.
         assign offset_start_addr = 0;
         assign offset_end_addr   = {OFFSET_WIDTH{1'b1}};
`endif         
      end else begin // if (HIT_OFFSET_STORE_WIDTH > 0)
         assign offset_start_addr = 0;
         assign offset_end_addr   = {OFFSET_WIDTH{1'b1}};
      end
   endgenerate
      
   //////////////////////////////////////////////////////////////////////////////////////

   
   // check for hit, multi hit, prot
   always_comb begin
      first_hit_top = 1'b0;
      multi_hit_top = 1'b0;
      hit_top       = 1'b0;      
      hit_block_num = 0;
      prot_top = |prot;
      hit_top  = |hit;
      for (int i=0; i<PARALLEL_NUM; i++) begin
         if (hit[i] == 1'b1) begin
            if (multi_hit[i] || multi_hit_top || first_hit_top == 1'b1) begin
               multi_hit_top = 1'b1;
               first_hit_top = 1'b0;
            end else begin                 
               first_hit_top = 1'b1;
               hit_block_num = i;
            end
         end
      end // for (int i=0; i<PARALLEL_NUM; i++)
   end // always_comb begin
   

   ///////////////////// ------------- Outputs ------------ //////////////////////////////////
   //// FSM
   always_ff @(posedge clk_i) begin
      if (rst_ni == 0) begin
         out_SP <= OUT_IDLE;
      end else begin
         out_SP <= out_SN;
      end
   end
   
   always_comb begin
      out_SN = out_SP;
      send_outputs         = 1'b0;
      hit_l2_next          = 1'b0;
      miss_l2_next         = 1'b0;
      prot_l2_next         = 1'b0;
      multiple_hit_l2_next = 1'b0;
      pa_port0_raddr = 0;
      unique case (out_SP)
        OUT_IDLE :
          if (multi_hit_top || prot_top || (search_done && ~hit_top)) begin // No Hit
             out_SN                 = SEND_OUTPUT;
             if (multi_hit_top)
               multiple_hit_l2_next = 1'b1;
             if (prot_top)
               prot_l2_next         = 1'b1;
             if (search_done && ~hit_top)
               miss_l2_next         = 1'b1;
          end else if (search_done && hit_top) begin // Hit
             out_SN         = SEND_OUTPUT;
             //pa_port0_raddr = (VA_RAM_DEPTH * hit_block_num) + hit_addr[hit_block_num];
             pa_port0_raddr = (PARALLEL_NUM * hit_addr[hit_block_num]) + hit_block_num;
             hit_l2_next    = 1'b1;
          end             
        
        SEND_OUTPUT : begin
           out_SN       = OUT_SENT;
           send_outputs = 1'b1;
        end
               
        OUT_SENT :
          if (l1_miss)
            out_SN = OUT_IDLE;
               
               
      endcase // case (out_SP)
   end // always_comb begin

   //// Output signals
   always_ff @(posedge clk_i) begin
      if (rst_ni == 0) begin
         miss_l2         <= 1'b0;
         prot_l2         <= 1'b0;
         multiple_hit_l2 <= 1'b0;
         hit_l2          <= 1'b0;
      end else begin
         miss_l2         <= miss_l2_next;
         prot_l2         <= prot_l2_next;
         multiple_hit_l2 <= multiple_hit_l2_next;
         hit_l2          <= hit_l2_next ;                    
      end
   end
   
   ///////////////////////////////////////////////////////////////////////////////////////////////////


   ///////////////////// --------------- Physical Address -------------- ////////////////////////////
  
   /// PA Block RAM
   ram #(
         .ADDR_WIDTH(PA_RAM_ADDR_WIDTH),
         .DATA_WIDTH(32)
         )
   pa_ram
     (
             .clk   (clk_i)           ,
             .we    (pa_ram_we)       ,
             .addr0 (pa_port0_addr)   ,
             .addr1 (0)               ,
             .d_i   (wdata)           ,
             .d0_o  (pa_port0_data_o) ,
             .d1_o  ()
             );

   assign out_addr[IGNORE_LSB-1:0]          = in_addr_saved[IGNORE_LSB-1:0];
   assign out_addr[ADDR_WIDTH-1:IGNORE_LSB] = pa_port0_data_o[ADDR_WIDTH-IGNORE_LSB-1:0];

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////   
   
   ///// Write enable for all block rams
generate if (LL_WIDTH != 0) begin
   always_comb begin
      var reg[LL_WIDTH:0] para;
      var int             para_int;      
      for (para = 0; para < PARALLEL_NUM; para=para+1'b1) begin
         para_int         = int'(para);
         //ram_we[para_int] = we && (waddr[LL_WIDTH+VA_RAM_ADDR_WIDTH:VA_RAM_ADDR_WIDTH] == para);
         ram_we[para_int] = we && (waddr[LL_WIDTH+VA_RAM_ADDR_WIDTH] == 1'b0) && (waddr[LL_WIDTH-1:0] == para);
      end
   end
end else begin
   assign ram_we[0] = we && (waddr[LL_WIDTH+VA_RAM_ADDR_WIDTH] == 1'b0);
end
endgenerate   
   assign pa_ram_we      = we && (waddr[LL_WIDTH+VA_RAM_ADDR_WIDTH] == 1'b1); //waddr[LL_WIDTH+VA_RAM_ADDR_WIDTH] will be 0 for all VA writes and 1 for all PA writes
   assign ram_waddr      = waddr[VA_RAM_ADDR_WIDTH-1:LL_WIDTH];
   assign pa_port0_waddr = waddr[PA_RAM_ADDR_WIDTH-1:0];             
   assign pa_port0_addr  = pa_ram_we? pa_port0_waddr : pa_port0_raddr;          

endmodule    