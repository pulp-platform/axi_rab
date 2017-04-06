/* Copyright (C) 2017 ETH Zurich, University of Bologna
 * All rights reserved.
 *
 * This code is under development and not yet released to the public.
 * Until it is released, the code is under the copyright of ETH Zurich and
 * the University of Bologna, and may contain confidential and/or unpublished 
 * work. Any reuse/redistribution is strictly forbidden without written
 * permission from ETH Zurich.
 *
 * Bug fixes and contributions will eventually be released under the
 * SolderPad open hardware license in the context of the PULP platform
 * (http://www.pulp-platform.org), under the copyright of ETH Zurich and the
 * University of Bologna.
 */

task FILL_LINEAR;
input  logic [31:0]                         address_base;
input  logic [AXI4_WDATA_WIDTH-1:0]         fill_pattern;
input  logic [15:0]                         transfer_count;
input  string                               transfer_type;
begin
  
  int unsigned                              count_local_AW;
  int unsigned                              count_local_W;
  logic   [31:0][AXI4_WDATA_WIDTH-1:0]       local_wdata;
  logic   [AXI_NUMBYTES-1:0]                local_be;

  case(transfer_type)

  "4_BYTE" : 
  begin
        
        fork
              for ( count_local_AW = 0; count_local_AW < transfer_count; count_local_AW++)
              begin
                  ST4_AW ( .id(count_local_AW[3:0]),               .address(address_base + count_local_AW*4  ),  .user(SRC_ID) );
              end
              
              for ( count_local_W = 0; count_local_W < transfer_count; count_local_W++)
              begin
                  local_wdata[0] = fill_pattern + count_local_W*4;
                  if(count_local_W % 2)
                        local_be = {  {AXI_NUMBYTES/2{1'b1}},{AXI_NUMBYTES/2{1'b0}}  };
                  else
                        local_be = {  {AXI_NUMBYTES/2{1'b0}},{AXI_NUMBYTES/2{1'b1}}  };
                  ST4_DW ( .wdata(local_wdata[0]),   .be('1),                              .user(SRC_ID) );
              end         
        join
  end


  "8_BYTE" : 
  begin
        
        fork
              for ( count_local_AW = 0; count_local_AW < transfer_count; count_local_AW++)
              begin
                  ST8_AW ( .id(count_local_AW[3:0]),  .address(address_base + count_local_AW*8 ),  .user(SRC_ID) );
              end
              
              for ( count_local_W = 0; count_local_W < transfer_count; count_local_W++)
              begin
                  local_wdata[0] = fill_pattern + count_local_W*8 + 0 ;
                  ST8_DW ( .wdata(local_wdata[0]),   .be('1),  .user(SRC_ID) );
              end         
        join
  end

  "16_BYTE" : 
  begin
        
        fork
              for ( count_local_AW = 0; count_local_AW < transfer_count; count_local_AW++)
              begin
                  ST8_AW ( .id(count_local_AW[1:0]),  .address(address_base + count_local_AW*16 ),  .user(SRC_ID) );
              end
              
              for ( count_local_W = 0; count_local_W < transfer_count; count_local_W++)
              begin
                  local_wdata[0] = fill_pattern + count_local_W*16 + 0 ;
                  local_wdata[1] = fill_pattern + count_local_W*16 + 8 ;
                  ST8_DW ( .wdata(local_wdata[1:0]),   .be('1),  .user(SRC_ID) );
              end         
        join
  end


  "32_BYTE" : 
  begin
        
        fork
              for ( count_local_AW = 0; count_local_AW < transfer_count; count_local_AW++)
              begin
                  ST16_AW ( .id(count_local_AW[3:0]),  .address(address_base + count_local_AW*32 ),  .user(SRC_ID) );
              end
              
              for ( count_local_W = 0; count_local_W < transfer_count; count_local_W++)
              begin
                  local_wdata[0] = fill_pattern + count_local_W*32 + 0 ;
                  local_wdata[1] = fill_pattern + count_local_W*32 + 8 ;
                  local_wdata[2] = fill_pattern + count_local_W*32 + 16 ;
                  local_wdata[3] = fill_pattern + count_local_W*32 + 24 ;
                  ST16_DW ( .wdata(local_wdata[3:0]),   .be('1),  .user(SRC_ID) );
              end         
        join
  end

  "64_BYTE" : 
  begin
        
        fork
              for ( count_local_AW = 0; count_local_AW < transfer_count; count_local_AW++)
              begin
                  ST32_AW ( .id(count_local_AW[7:0]),  .address(address_base + count_local_AW*64 ),  .user(SRC_ID) );
              end
              
              for ( count_local_W = 0; count_local_W < transfer_count; count_local_W++)
              begin
                  local_wdata[0] = fill_pattern + count_local_W*64 + 0 ;
                  local_wdata[1] = fill_pattern + count_local_W*64 + 8 ;
                  local_wdata[2] = fill_pattern + count_local_W*64 + 16 ;
                  local_wdata[3] = fill_pattern + count_local_W*64 + 24 ;
                  local_wdata[4] = fill_pattern + count_local_W*64 + 32 ;
                  local_wdata[5] = fill_pattern + count_local_W*64 + 40 ;
                  local_wdata[6] = fill_pattern + count_local_W*64 + 48 ;
                  local_wdata[7] = fill_pattern + count_local_W*64 + 56 ;                 
                  ST32_DW ( .wdata(local_wdata[7:0]),   .be('1),  .user(SRC_ID) );
              end         
        join
  end // case: "64_BYTE"

  "256_BYTE" : 
  begin
        
        fork
              for ( count_local_AW = 0; count_local_AW < transfer_count; count_local_AW++)
              begin
                  ST256_AW ( .id(count_local_AW[7:0]),  .address(address_base + count_local_AW*256 ),  .user(SRC_ID) );
              end
              
              for ( count_local_W = 0; count_local_W < transfer_count; count_local_W++)
              begin
                  local_wdata[0] = fill_pattern + count_local_W*64 + 0 ;
                  local_wdata[1] = fill_pattern + count_local_W*64 + 8 ;
                  local_wdata[2] = fill_pattern + count_local_W*64 + 16 ;
                  local_wdata[3] = fill_pattern + count_local_W*64 + 24 ;
                  local_wdata[4] = fill_pattern + count_local_W*64 + 32 ;
                  local_wdata[5] = fill_pattern + count_local_W*64 + 40 ;
                  local_wdata[6] = fill_pattern + count_local_W*64 + 48 ;
                  local_wdata[7] = fill_pattern + count_local_W*64 + 56 ; 
                  local_wdata[8] = fill_pattern + count_local_W*64 + 64 ;
                  local_wdata[9] = fill_pattern + count_local_W*64 + 72 ;
                  local_wdata[10] = fill_pattern + count_local_W*64 + 80 ;
                  local_wdata[11] = fill_pattern + count_local_W*64 + 88 ;
                  local_wdata[12] = fill_pattern + count_local_W*64 + 96 ;
                  local_wdata[13] = fill_pattern + count_local_W*64 + 104 ;
                  local_wdata[14] = fill_pattern + count_local_W*64 + 112 ;
                  local_wdata[15] = fill_pattern + count_local_W*64 + 120 ; 
                  local_wdata[16] = fill_pattern + count_local_W*64 + 128 ;
                  local_wdata[17] = fill_pattern + count_local_W*64 + 136 ;
                  local_wdata[18] = fill_pattern + count_local_W*64 + 144 ;
                  local_wdata[19] = fill_pattern + count_local_W*64 + 152 ;
                  local_wdata[20] = fill_pattern + count_local_W*64 + 160 ;
                  local_wdata[21] = fill_pattern + count_local_W*64 + 168 ;
                  local_wdata[22] = fill_pattern + count_local_W*64 + 176 ;
                  local_wdata[23] = fill_pattern + count_local_W*64 + 184 ; 
                  local_wdata[24] = fill_pattern + count_local_W*64 + 192 ;
                  local_wdata[25] = fill_pattern + count_local_W*64 + 200 ;
                  local_wdata[26] = fill_pattern + count_local_W*64 + 208 ;
                  local_wdata[27] = fill_pattern + count_local_W*64 + 216 ;
                  local_wdata[28] = fill_pattern + count_local_W*64 + 224 ;
                  local_wdata[29] = fill_pattern + count_local_W*64 + 232 ;
                  local_wdata[30] = fill_pattern + count_local_W*64 + 240 ;
                  local_wdata[31] = fill_pattern + count_local_W*64 + 248 ;    
                  ST256_DW ( .wdata(local_wdata[31:0]),   .be('1),  .user(SRC_ID) );
              end         
        join
  end // case: "64_BYTE"  

  default:
  begin
        fork
              for ( count_local_AW = 0; count_local_AW < transfer_count; count_local_AW++)
              begin
                  ST4_AW ( .id(count_local_AW[3:0]),               .address(address_base + count_local_AW*8  ),  .user(SRC_ID) );
              end
              
              for ( count_local_W = 0; count_local_W < transfer_count; count_local_W++)
              begin
                  local_wdata[0] = fill_pattern + count_local_W*8;      
                  ST4_DW ( .wdata(local_wdata[0]),   .be('1),                              .user(SRC_ID) );
              end         
        join
  end
  endcase

end
endtask







task READ_LINEAR;
input  logic [31:0]  address_base;
input  logic [15:0]  transfer_count;
input  string        transfer_type;
begin

  integer count_local_AR;
  logic   [7:0][31:0]           local_wdata;

  case(transfer_type)

      "4_BYTE" : 
      begin
          for ( count_local_AR = 0; count_local_AR < transfer_count; count_local_AR++)
          begin
                    LD4 ( .id(count_local_AR[3:0]),               .address(address_base + count_local_AR*4 ),  .user(SRC_ID) );
          end      
      end

      "8_BYTE" : 
      begin
          for ( count_local_AR = 0; count_local_AR < transfer_count; count_local_AR++)
          begin
                    LD8 ( .id(count_local_AR[3:0]),               .address(address_base + count_local_AR*8 ),  .user(SRC_ID) );
          end      
      end
      
      "16_BYTE" : 
      begin
          for ( count_local_AR = 0; count_local_AR < transfer_count; count_local_AR++)
          begin
                    LD16 ( .id(count_local_AR[3:0]),               .address(address_base + count_local_AR*16 ),  .user(SRC_ID) );
          end      
      end
      
      "32_BYTE" : 
      begin
          for ( count_local_AR = 0; count_local_AR < transfer_count; count_local_AR++)
          begin
                    LD32 ( .id(count_local_AR[3:0]),               .address(address_base + count_local_AR*32 ),  .user(SRC_ID) );
          end      
      end

      "64_BYTE" : 
      begin
          for ( count_local_AR = 0; count_local_AR < transfer_count; count_local_AR++)
          begin
                    LD64 ( .id(count_local_AR[3:0]),               .address(address_base + count_local_AR*64 ),  .user(SRC_ID) );
          end      
      end

      "256_BYTE" : 
      begin
          for ( count_local_AR = 0; count_local_AR < transfer_count; count_local_AR++)
          begin
                    LD256 ( .id(count_local_AR[3:0]),               .address(address_base + count_local_AR*256 ),  .user(SRC_ID) );
          end      
      end               
      
      default:
      begin
          for ( count_local_AR = 0; count_local_AR < transfer_count; count_local_AR++)
          begin
                    LD4 ( .id(count_local_AR[3:0]),               .address(address_base + count_local_AR*4 ),  .user(SRC_ID) );
          end  
      end
  
  endcase


end
endtask




task CHECK_LINEAR;
input  logic [31:0]  address_base;
input  logic [15:0]  transfer_count;
input  string        transfer_type;
input  logic [AXI4_WDATA_WIDTH-1:0]  check_pattern;

begin

  integer count_local_AR;
  logic   [7:0][AXI4_WDATA_WIDTH-1:0]           local_wdata;

  automatic int unsigned local_PASS = 0;
  automatic int unsigned local_FAIL = 0;
  
  case(transfer_type)

      "4_BYTE" : 
      begin
          for ( count_local_AR = 0; count_local_AR < transfer_count; count_local_AR++)
          begin
                    LD4 ( .id(count_local_AR[3:0]),               .address(address_base + count_local_AR*4 ),  .user(SRC_ID) );
                    @(IncomingRead);
                    if(RDATA != check_pattern + count_local_AR*4 )
                    begin
                      $error("RDATA ERROR: got %x != %x [expected]... Address is %h", RDATA , check_pattern+count_local_AR*4, address_base + count_local_AR*4);
                      local_FAIL++;
                    end
                    else
                    begin
                      local_PASS++;
                    end
          end      
      end

      "8_BYTE" : 
      begin
          for ( count_local_AR = 0; count_local_AR < transfer_count; count_local_AR++)
          begin
                    LD8 ( .id(count_local_AR[3:0]),               .address(address_base + count_local_AR*8 ),  .user(SRC_ID) );
                    @(IncomingRead);
                    if(RDATA != check_pattern + count_local_AR*8 )
                    begin
                      $error("RDATA ERROR: got %x != %x [expected]... Address is %h", RDATA , check_pattern+count_local_AR*8, address_base + count_local_AR*8);
                      local_FAIL++;
                    end
                    else
                    begin
                      local_PASS++;
                    end               
          end      
      end
      
      "16_BYTE" : 
      begin
          for ( count_local_AR = 0; count_local_AR < transfer_count; count_local_AR++)
          begin
                    LD16 ( .id(count_local_AR[3:0]),               .address(address_base + count_local_AR*16 ),  .user(SRC_ID) );
                    @(IncomingRead);
                    if(RDATA != check_pattern + count_local_AR*16)
                    begin
                      $error("RDATA ERROR: got %x != %x [expected]... Address is %h", RDATA , check_pattern+count_local_AR*16, address_base + count_local_AR*16);
                      local_FAIL++;
                    end
                    else
                    begin
                      local_PASS++;
                    end
          end      
      end
      
      "32_BYTE" : 
      begin
          for ( count_local_AR = 0; count_local_AR < transfer_count; count_local_AR++)
          begin
                    LD32 ( .id(count_local_AR[3:0]),               .address(address_base + count_local_AR*32 ),  .user(SRC_ID) );
                    @(IncomingRead);
                    if(RDATA != check_pattern + count_local_AR*32)
                    begin
                      $error("RDATA ERROR: got %x != %x [expected]... Address is %h", RDATA , check_pattern+count_local_AR*32, address_base + count_local_AR*32);
                      local_FAIL++;
                    end
                    else
                    begin
                      local_PASS++;
                    end               
          end      
      end

      "64_BYTE" : 
      begin
          for ( count_local_AR = 0; count_local_AR < transfer_count; count_local_AR++)
          begin
                    LD32 ( .id(count_local_AR[3:0]),               .address(address_base + count_local_AR*64 ),  .user(SRC_ID) );
                    @(IncomingRead);
                    if(RDATA != check_pattern + count_local_AR*64)
                    begin
                      $error("RDATA ERROR: got %x != %x [expected]... Address is %h", RDATA , check_pattern+count_local_AR*64, address_base + count_local_AR*64);
                      local_FAIL++;
                    end
                    else
                    begin
                      local_PASS++;
                    end               
          end      
      end 
      
      
      default:
      begin
          for ( count_local_AR = 0; count_local_AR < transfer_count; count_local_AR++)
          begin
                    LD4 ( .id(count_local_AR[3:0]),               .address(address_base + count_local_AR*4 ),  .user(SRC_ID) );
                    @(IncomingRead);;
                    if(RDATA != check_pattern + count_local_AR*4 )
                    begin
                      $error("RDATA ERROR: got %x != %x [expected]... Address is %h", RDATA , check_pattern+count_local_AR*4, address_base + count_local_AR*4);
                      local_FAIL++;
                    end
                    else
                    begin
                      local_PASS++;
                    end               
          end  
      end
  
  endcase

  PASS = PASS + local_PASS;
  FAIL = FAIL + local_FAIL;
end
endtask







task FILL_RANDOM;
input  logic [31:0]                   address_base;
input  logic [AXI4_WDATA_WIDTH-1:0]   fill_pattern;
input  logic [15:0]                   transfer_count;
input  string                         transfer_type;
parameter RANDOM_ADDR_BITS = 6;
begin
  
  integer                             count_local_AW;
  integer                             count_local_W;
  logic   [7:0][AXI4_WDATA_WIDTH-1:0] local_wdata;
  logic   [AXI_NUMBYTES-1:0]          local_be;
  logic   [31:0]                      local_addr;

  case(transfer_type)

  "4_BYTE" : 
  begin
        
        fork
              for ( count_local_AW = 0; count_local_AW < transfer_count; count_local_AW++)
              begin
                  local_addr = '0;
                  local_addr[2+RANDOM_ADDR_BITS-1:2] = $random();
                  local_addr = address_base + local_addr;
                  ST4_AW ( .id(count_local_AW[3:0]),               .address(local_addr),  .user(SRC_ID) );
              end
              
              for ( count_local_W = 0; count_local_W < transfer_count; count_local_W++)
              begin
                  if($random % 2)
                        local_be = {  {AXI_NUMBYTES/2{1'b1}},{AXI_NUMBYTES/2{1'b0}}  };
                  else
                        local_be = {  {AXI_NUMBYTES/2{1'b0}},{AXI_NUMBYTES/2{1'b1}}  };

                  local_wdata[0] = $random;      
                  ST4_DW ( .wdata(local_wdata[0]),   .be(local_be),                              .user(SRC_ID) );
              end         
        join
  end


  "8_BYTE" : 
  begin
        
        fork
              for ( count_local_AW = 0; count_local_AW < transfer_count; count_local_AW++)
              begin
                  local_addr = '0;
                  local_addr[3+RANDOM_ADDR_BITS-1:3] = $random();
                  local_addr = address_base + local_addr;
                  ST8_AW ( .id(count_local_AW[3:0]),               .address(local_addr  ),  .user(SRC_ID) );
              end
              
              for ( count_local_W = 0; count_local_W < transfer_count; count_local_W++)
              begin
                  local_wdata[0] = $random;   
                  ST8_DW ( .wdata(local_wdata[0]),   .be('1),                              .user(SRC_ID) );
              end         
        join
  end

  "16_BYTE" : 
  begin
        
        fork
              for ( count_local_AW = 0; count_local_AW < transfer_count; count_local_AW++)
              begin
                  local_addr = '0;
                  local_addr[4+RANDOM_ADDR_BITS-1:4] = $random();
                  local_addr = address_base + local_addr;
                  ST8_AW ( .id(count_local_AW[3:0]),               .address(local_addr  ),  .user(SRC_ID) );
              end
              
              for ( count_local_W = 0; count_local_W < transfer_count; count_local_W++)
              begin
                  local_wdata[0] = $random;   
                  local_wdata[1] = $random;
                  ST8_DW ( .wdata(local_wdata[1:0]),   .be('1),                              .user(SRC_ID) );
              end         
        join
  end


  "32_BYTE" : 
  begin
        
        fork
              for ( count_local_AW = 0; count_local_AW < transfer_count; count_local_AW++)
              begin
                  local_addr = '0;
                  local_addr[5+RANDOM_ADDR_BITS-1:5] = $random();
                  local_addr = address_base + local_addr;
                  ST16_AW ( .id(count_local_AW[3:0]),  .address(local_addr ),  .user(SRC_ID) );
              end
              
              for ( count_local_W = 0; count_local_W < transfer_count; count_local_W++)
              begin
                  local_wdata[0] = $random() ;
                  local_wdata[1] = $random() ;
                  local_wdata[2] = $random() ;
                  local_wdata[3] = $random() ;
                  ST16_DW ( .wdata(local_wdata[3:0]),   .be('1),  .user(SRC_ID) );
              end         
        join
  end

  "64_BYTE" : 
  begin
        
        fork
              for ( count_local_AW = 0; count_local_AW < transfer_count; count_local_AW++)
              begin
                  local_addr = '0;
                  local_addr[6+RANDOM_ADDR_BITS-1:6] = $random();
                  local_addr = address_base + local_addr;
                  ST4_AW ( .id(count_local_AW[3:0]),  .address(local_addr ),  .user(SRC_ID) );
              end
              
              for ( count_local_W = 0; count_local_W < transfer_count; count_local_W++)
              begin
                  local_wdata[0] = $random ;
                  local_wdata[1] = $random ;
                  local_wdata[2] = $random ;
                  local_wdata[3] = $random ;
                  local_wdata[4] = $random ;
                  local_wdata[5] = $random ;
                  local_wdata[6] = $random ;
                  local_wdata[7] = $random ;              
                  ST4_DW ( .wdata(local_wdata[7:0]),   .be('1),  .user(SRC_ID) );
              end         
        join
  end

  default:
  begin
        fork
              for ( count_local_AW = 0; count_local_AW < transfer_count; count_local_AW++)
              begin
                  ST8_AW ( .id(count_local_AW[3:0]),               .address(address_base + count_local_AW*8  ),  .user(SRC_ID) );
              end
              
              for ( count_local_W = 0; count_local_W < transfer_count; count_local_W++)
              begin
                  local_wdata[0] = fill_pattern + count_local_W*8;      
                  ST8_DW ( .wdata(local_wdata[0]),   .be('1),                              .user(SRC_ID) );
              end         
        join
  end
  endcase

end
endtask
