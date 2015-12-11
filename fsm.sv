`timescale 1ns / 1ps

module fsm(
           input    logic             s_axi_aclk,
           input    logic             s_axi_aresetn,
           input    logic             port1_addr_valid,
           input    logic             port2_addr_valid,
           input    logic             port1_sent,
           input    logic             port2_sent,
           input    logic             select,        
           input    logic             no_hit,   
           input    logic             multiple_hit,
           input    logic             no_prot,
           input    logic    [31:0]   out_addr,   
           output   logic             port1_accept,
           output   logic             port1_drop,  
           output   logic             port2_accept, 
           output   logic             port2_drop,  
           output   logic    [31:0]   out_addr_reg,
           output   logic             int_miss,    
           output   logic             int_multi,  
           output   logic             int_prot     
           );
   
   parameter READY  = 1'b0;
   parameter WAIT   = 1'b1;
   
   //-------------Internal Signals----------------------
   
   logic                              state;      // Seq part of the FSM
   logic                              next_state; // combo part of FSM

   logic                              port1_accept_SN;
   logic                              port1_drop_SN;
   logic                              port2_accept_SN;
   logic                              port2_drop_SN;
   logic [31:0]                       out_addr_reg_SN;
   logic                              int_miss_SN;
   logic                              int_multi_SN;
   logic                              int_prot_SN;
      
   //----------FSM comb------------------------------
   
   always_comb
     begin: FSM_COMBO
        next_state = state;
        
        case(state)
          READY :
            if (port1_addr_valid || port2_addr_valid)
              next_state = WAIT;
          
          WAIT :
            if (port1_sent || port2_sent)
              next_state = READY;
          
        endcase
     end
   
   //----------FSM seq-------------------------------
   
   always_ff @(posedge s_axi_aclk, negedge s_axi_aresetn)
     begin: FSM_SEQ
        if (s_axi_aresetn == 1'b0)
          state <= #1 READY;
        else
          state <= #1 next_state;
     end
   
   //----------Output comb---------------------------

   always_comb 
     begin: OUTPUT_COMB

        // default
        port1_accept_SN = 1'b0;
        port1_drop_SN   = 1'b0;
        port2_accept_SN = 1'b0;
        port2_drop_SN   = 1'b0;
        out_addr_reg_SN = out_addr_reg; // hold
        int_miss_SN     = 1'b0;
        int_multi_SN    = 1'b0;
        int_prot_SN     = 1'b0;
        
        if ( state == READY ) // Ready to accept new trans
          begin
             port1_accept_SN = port1_addr_valid &  select & ~(no_hit | multiple_hit | ~no_prot);
             port1_drop_SN   = port1_addr_valid &  select &  (no_hit | multiple_hit | ~no_prot);
             port2_accept_SN = port2_addr_valid & ~select & ~(no_hit | multiple_hit | ~no_prot);
             port2_drop_SN   = port2_addr_valid & ~select &  (no_hit | multiple_hit | ~no_prot);
             int_miss_SN     = (port1_addr_valid || port2_addr_valid) & no_hit;
             int_multi_SN    = (port1_addr_valid || port2_addr_valid) & multiple_hit;
             int_prot_SN     = (port1_addr_valid || port2_addr_valid) & ~no_prot;
             out_addr_reg_SN = out_addr;
          end
     end // block: OUTPUT_COMB
      
   //----------Output seq--------------------------
   
   always_ff @(posedge s_axi_aclk, negedge s_axi_aresetn)
     begin: OUTPUT_SEQ
        if (s_axi_aresetn == 1'b0)
          begin
             port1_accept =  1'b0;
             port1_drop   =  1'b0;
             port2_accept =  1'b0;
             port2_drop   =  1'b0;
             out_addr_reg = 32'h0;
             int_miss     =  1'b0;
             int_multi    =  1'b0;
             int_prot     =  1'b0;
          end
        else
          begin
             port1_accept = port1_accept_SN;
             port1_drop   = port1_drop_SN;
             port2_accept = port2_accept_SN;
             port2_drop   = port2_drop_SN;
             out_addr_reg = out_addr_reg_SN;
             int_miss     = int_miss_SN;
             int_multi    = int_multi_SN;
             int_prot     = int_prot_SN;
          end
     end // block: OUTPUT_SEQ
   
endmodule
