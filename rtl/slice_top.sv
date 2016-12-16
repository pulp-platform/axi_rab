module slice_top 
 #(
    parameter N_SLICES        = 16,
    parameter N_REGS          = 4*N_SLICES,
    parameter ADDR_WIDTH_PHYS = 40,
    parameter ADDR_WIDTH_VIRT = 32
    )
   (
    input   logic   [N_REGS-1:0] [63:0] int_cfg_regs,
    input   logic                       int_rw,
    input   logic [ADDR_WIDTH_VIRT-1:0] int_addr_min,
    input   logic [ADDR_WIDTH_VIRT-1:0] int_addr_max,
    output  logic        [N_SLICES-1:0] prot,
    output  logic        [N_SLICES-1:0] hit,
    output  logic                       multiple_hit,
    output  logic                       cache_coherent,
    output  logic [ADDR_WIDTH_PHYS-1:0] out_addr
  );
 
  logic first_hit;
  logic second_hit;
  
  genvar  i;
  integer j;
  integer k;  
  
  logic [ADDR_WIDTH_PHYS*N_SLICES-1:0]  slice_out_addr;
   
  generate
    for ( i=0; i<N_SLICES; i++ )
      begin
        rab_slice
          #( 
            .ADDR_WIDTH_PHYS ( ADDR_WIDTH_PHYS ),
            .ADDR_WIDTH_VIRT ( ADDR_WIDTH_VIRT )
            )
          u_slice
          (
            .cfg_min       ( int_cfg_regs[4*i]  [ADDR_WIDTH_VIRT-1:0]                              ),
            .cfg_max       ( int_cfg_regs[4*i+1][ADDR_WIDTH_VIRT-1:0]                              ),
            .cfg_offset    ( int_cfg_regs[4*i+2][ADDR_WIDTH_PHYS-1:0]                              ),
            .cfg_wen       ( int_cfg_regs[4*i+3][2]                                                ),
            .cfg_ren       ( int_cfg_regs[4*i+3][1]                                                ),
            .cfg_en        ( int_cfg_regs[4*i+3][0]                                                ),
            .in_trans_type ( int_rw                                                                ),
            .in_addr_min   ( int_addr_min                                                          ),
            .in_addr_max   ( int_addr_max                                                          ),
            .out_addr      ( slice_out_addr[ADDR_WIDTH_PHYS*i+ADDR_WIDTH_PHYS-1:ADDR_WIDTH_PHYS*i] ),
            .out_prot      ( prot[i]                                                               ),
            .out_hit       ( hit[i]                                                                )
          );
     end
  endgenerate

  always_comb
    begin
      first_hit       = 0;
      second_hit      = 0;
      k               = 0;
      multiple_hit    = 0;
      out_addr        = '0;
      cache_coherent  = 0;
        for (j = 0; j < N_SLICES; j++)
        begin
          if (hit[j] == 1'b1)
            begin
              if (first_hit)
                begin
                  second_hit = 1'b1;
                  first_hit  = 1'b0;
                end
              else if (second_hit)
                begin
                  multiple_hit    = 1'b1;
                  out_addr        = '0;
                  cache_coherent  = 0;
                end
              else
                begin
                  first_hit       = 1'b1;
                  k               = j;
                  out_addr        = slice_out_addr[ADDR_WIDTH_PHYS*j +: ADDR_WIDTH_PHYS];
                  cache_coherent  = int_cfg_regs[4*j+3][3];
                end
            end
        end
    end
   
endmodule
