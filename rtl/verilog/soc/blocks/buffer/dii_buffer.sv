// Copyright 2016 by the authors
//
// Copyright and related rights are licensed under the Solderpad
// Hardware License, Version 0.51 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a
// copy of the License at http://solderpad.org/licenses/SHL-0.51.
// Unless required by applicable law or agreed to in writing,
// software, hardware and materials distributed under this License is
// distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS
// OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the
// License.
//
// Authors:
//    Wei Song <ws327@cam.ac.uk>
//    Stefan Wallentowitz <stefan@wallentowitz.de>

import dii_package::dii_flit;
import dii_package::dii_flit_assemble;

module dii_buffer #(
  parameter BUF_SIZE   = 4,  // length of the buffer
  parameter FULLPACKET = 0
)
  (
    input                               clk,
    input                               rst,

    output logic   [$clog2(BUF_SIZE):0] packet_size,

    input  dii_flit                     flit_in,
    output dii_flit                     flit_out,

    output                              flit_in_ready,
    input                               flit_out_ready
  );

  // the width of the index
  localparam ID_W = $clog2(BUF_SIZE);

  // internal shift register
  dii_flit [BUF_SIZE-1:0]   data;

  // read pointer
  reg [ID_W:0]              rp;

  // local output valid
  logic                     reg_out_valid;

  logic                     flit_in_fire;
  logic                     lit_out_fire;

  assign flit_in_ready = (rp != BUF_SIZE - 1) || !reg_out_valid;
  assign flit_in_fire = flit_in.valid && flit_in_ready;
  assign flit_out_fire = flit_out.valid && flit_out_ready;

  always_ff @(posedge clk) begin
    if(rst)
      reg_out_valid <= 0;
    else if(flit_in.valid)
      reg_out_valid <= 1;
    else if(flit_out_fire && rp == 0)
      reg_out_valid <= 0;
  end

  always_ff @(posedge clk) begin
    if(rst)
      rp <= 0;
    else if(flit_in_fire && !flit_out_fire && reg_out_valid)
      rp <= rp + 1;
    else if(flit_out_fire && !flit_in_fire && rp != 0)
      rp <= rp - 1;
  end

  always @(posedge clk) begin
    if(flit_in_fire)
      data <= {data, flit_in};
  end

  generate                     // SRL does not allow parallel read
    if(FULLPACKET != 0) begin
      logic [BUF_SIZE-1:0] data_last_buf, data_last_shifted;

      always_ff @(posedge clk) begin
        if(rst)
          data_last_buf <= 0;
        else if(flit_in_fire)
          data_last_buf <= {data_last_buf, flit_in.last && flit_in.valid};
      end

      // extra logic to get the packet size in a stable manner
      assign data_last_shifted = data_last_buf << BUF_SIZE - 1 - rp;

      function logic [ID_W:0] find_first_one(input logic [BUF_SIZE-1:0] data);
        automatic int i;
        for(i=BUF_SIZE-1; i>=0; i--)
          if(data[i]) return i;
        return BUF_SIZE;
      endfunction

      assign packet_size = BUF_SIZE - find_first_one(data_last_shifted);

      always @(*) begin
        flit_out = data[rp];
        flit_out.valid = reg_out_valid && |data_last_shifted;
      end
    end
    else begin
      assign packet_size = 0;
      always @(*) begin
        flit_out = data[rp];
        flit_out.valid = reg_out_valid;
      end
    end
  endgenerate
endmodule
