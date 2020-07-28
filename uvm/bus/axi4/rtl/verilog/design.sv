////////////////////////////////////////////////////////////////////////////////
//                                            __ _      _     _               //
//                                           / _(_)    | |   | |              //
//                __ _ _   _  ___  ___ _ __ | |_ _  ___| | __| |              //
//               / _` | | | |/ _ \/ _ \ '_ \|  _| |/ _ \ |/ _` |              //
//              | (_| | |_| |  __/  __/ | | | | | |  __/ | (_| |              //
//               \__, |\__,_|\___|\___|_| |_|_| |_|\___|_|\__,_|              //
//                  | |                                                       //
//                  |_|                                                       //
//                                                                            //
//                                                                            //
//              MPSoC-RISCV / OR1K / MSP430 CPU                               //
//              General Purpose Input Output Bridge                           //
//              AMBA4 APB-Lite Bus Interface                                  //
//              Universal Verification Methodology                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

/* Copyright (c) 2020-2021 by the author(s)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * =============================================================================
 * Author(s):
 *   Paco Reina Campo <pacoreinacampo@queenfield.tech>
 */

interface dut_if;
  logic        clk;
  logic        rst;

  logic [10:0] aw_id;
  logic [31:0] aw_addr;
  logic [ 7:0] aw_len;
  logic [ 2:0] aw_size;
  logic [ 1:0] aw_burst;
  logic        aw_lock;
  logic [ 3:0] aw_cache;
  logic [ 2:0] aw_prot;
  logic [ 3:0] aw_qos;
  logic [ 3:0] aw_region;
  logic [10:0] aw_user;
  logic        aw_valid;
  logic        aw_ready;

  logic [10:0] ar_id;
  logic [31:0] ar_addr;
  logic [ 7:0] ar_len;
  logic [ 2:0] ar_size;
  logic [ 1:0] ar_burst;
  logic        ar_lock;
  logic [ 3:0] ar_cache;
  logic [ 2:0] ar_prot;
  logic [ 3:0] ar_qos;
  logic [ 3:0] ar_region;
  logic [10:0] ar_user;
  logic        ar_valid;
  logic        ar_ready;

  logic [31:0] dw_data;
  logic [10:0] dw_strb;
  logic        dw_last;
  logic [10:0] dw_user;
  logic        dw_valid;
  logic        dw_ready;

  logic [10:0] dr_id;
  logic [31:0] dr_data;
  logic [ 1:0] dr_resp;
  logic        dr_last;
  logic [10:0] dr_user;
  logic        dr_valid;
  logic        dr_ready;

  logic [10:0] b_id;
  logic [ 1:0] b_resp;
  logic [10:0] b_user;
  logic        b_valid;
  logic        b_ready;
  
  //Master Clocking block - used for Drivers
  clocking master_cb @(posedge pclk);
    output paddr;
    output psel;
    output penable;
    output pwrite;
    output pwdata;
    input  prdata;
  endclocking: master_cb

  //Slave Clocking Block - used for any Slave BFMs
  clocking slave_cb @(posedge pclk);
     input  paddr;
     input  psel;
     input  penable;
     input  pwrite;
     input  pwdata;
     output prdata;
  endclocking: slave_cb

  //Monitor Clocking block - For sampling by monitor components
  clocking monitor_cb @(posedge pclk);
    input paddr;
    input psel;
    input penable;
    input pwrite;
    input prdata;
    input pwdata;
  endclocking: monitor_cb

  modport master(clocking master_cb);
  modport slave(clocking slave_cb);
  modport passive(clocking monitor_cb);
endinterface

module axi4_slave(dut_if dif);
  logic [31:0] mem [0:256];
  logic [ 1:0] axi4_st;

  const logic [1:0] SETUP=0;
  const logic [1:0] W_ENABLE=1;
  const logic [1:0] R_ENABLE=2;
  
  always @(posedge dif.pclk or negedge dif.prst) begin
    if (dif.prst==0) begin
      axi4_st <=0;
      dif.prdata <=0;
      dif.pready <=1;
      for(int i=0;i<256;i++) mem[i]=i;
    end
    else begin
      case (axi4_st)
        SETUP: begin
          dif.prdata <= 0;
          if (dif.psel && !dif.penable) begin
            if (dif.pwrite) begin
              axi4_st <= W_ENABLE;
            end
            else begin
              axi4_st <= R_ENABLE;
              dif.prdata <= mem[dif.paddr];
            end
          end
        end
        W_ENABLE: begin
          if (dif.psel && dif.penable && dif.pwrite) begin
            mem[dif.paddr] <= dif.pwdata;
          end
          axi4_st <= SETUP;
        end
        R_ENABLE: begin
          axi4_st <= SETUP;
        end
      endcase
    end
  end
endmodule
