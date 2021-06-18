// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype wire

`ifndef MPRJ_IO_PADS
    `define MPRJ_IO_PADS 38
`endif
/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */

module user_proj_example #(
    parameter BITS = 32
)(
`ifdef USE_POWER_PINS
    inout vdda1, // User area 1 3.3V supply
    inout vdda2, // User area 2 3.3V supply
    inout vssa1, // User area 1 analog ground
    inout vssa2, // User area 2 analog ground
    inout vccd1,    // User area 1 1.8V supply
    inout vccd2,    // User area 2 1.8v supply
    inout vssd1,    // User area 1 digital ground
    inout vssd2,    // User area 2 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
    output [2:0] irq
);
    wire clk;
    wire rst;

    wire [`MPRJ_IO_PADS-1:0] io_in;
    wire [`MPRJ_IO_PADS-1:0] io_out;
    wire [`MPRJ_IO_PADS-1:0] io_oeb;

    wire [31:0] rdata; 
    wire [31:0] wdata;
    wire [BITS-1:0] count;

    wire valid;
    wire [3:0] wstrb;
    wire [31:0] la_write;

    assign io_oeb[8:0] = {9{1'b1}};
    assign io_oeb[23:9] = {15{1'b0}};

    // wire [3:0] empty_gpios; 
    // ChipTop chiptop(
    //     .clock(wb_clk_i),
    //     .reset_wire_reset(wb_rst_i),
    //     .jtag_TCK(io_in[0]),
    //     .jtag_TMS(io_in[1]),
    //     .jtag_TDI(io_in[2]),
    //     .jtag_TDO_data(io_out[9]),
    //     .jtag_TDO_driven(),
    //     .custom_gpio_input_pins({io_in[3], io_in[4], io_in[5], io_in[6], 1'b0, 1'b0, 1'b0, 1'b0}),
    //     .custom_gpio_output_pins({io_out[10], io_out[11], io_out[12], io_out[13], empty_gpios[0], empty_gpios[1], empty_gpios[2], empty_gpios[3]}),
    //     .pwm_0_gpio_0(io_out[14]),
    //     .pwm_0_gpio_1(io_out[15]),
    //     .pwm_0_gpio_2(io_out[16]),
    //     .pwm_0_gpio_3(io_out[17]),
    //     .i2c_0_scl_in(io_in[24]),
    //     .i2c_0_scl_out(io_out[24]),
    //     .i2c_0_scl_oe(!io_oeb[24]),
    //     .i2c_0_sda_in(io_in[25]),
    //     .i2c_0_sda_out(io_out[25]),
    //     .i2c_0_sda_oe(!io_oeb[25]),
    //     .qspi_0_sck(io_out[26]),
    //     .qspi_0_dq_0_i(io_in[26]),
    //     .qspi_0_dq_0_ie(io_oeb[26]),
    //     .qspi_0_dq_0_oe(),
    //     .qspi_0_dq_1_i(io_in[27]),
    //     .qspi_0_dq_1_ie(io_oeb[27]),
    //     .qspi_0_dq_1_oe(),
    //     .qspi_0_dq_2_i(io_in[28]),
    //     .qspi_0_dq_2_ie(io_oeb[28]),
    //     .qspi_0_dq_2_oe(),
    //     .qspi_0_dq_3_i(io_in[29]),
    //     .qspi_0_dq_3_ie(io_oeb[29]),
    //     .qspi_0_dq_3_oe(),
    //     .qspi_0_cs_0(io_in[7]),
    //     .uart_0_txd(io_out[18]),
    //     .uart_0_rxd(io_in[8]),
    //     .spi_0_sck(io_out[19]),    
    //     .spi_0_dq_0_i(io_in[30]),
    //     .spi_0_dq_0_o(io_out[30]),
    //     .spi_0_dq_0_ie(io_oeb[30]),
    //     .spi_0_dq_0_oe(),
    //     .spi_0_dq_1_i(io_in[31]),
    //     .spi_0_dq_1_o(io_out[31]),
    //     .spi_0_dq_1_ie(io_oeb[31]),
    //     .spi_0_dq_1_oe(),
    //     .spi_0_dq_2_i(io_in[32]),
    //     .spi_0_dq_2_o(io_out[32]),
    //     .spi_0_dq_2_ie(io_oeb[32]),
    //     .spi_0_dq_2_oe(),
    //     .spi_0_dq_3_i(io_in[33]),
    //     .spi_0_dq_3_o(io_out[33]),
    //     .spi_0_dq_3_ie(io_oeb[33]),
    //     .spi_0_dq_3_oe(),
    //     .spi_0_cs_0(io_out[20]),
    //     .spi_0_cs_1(io_out[21]),
    //     .spi_0_cs_2(io_out[22]),
    //     .spi_0_cs_3(io_out[23])
    // );

endmodule