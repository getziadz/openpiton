// ========== Copyright Header Begin ============================================
// Copyright (c) 2017 Princeton University
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in the
//       documentation and/or other materials provided with the distribution.
//     * Neither the name of Princeton University nor the
//       names of its contributors may be used to endorse or promote products
//       derived from this software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY PRINCETON UNIVERSITY "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL PRINCETON UNIVERSITY BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// ========== Copyright Header End ============================================

//--------------------------------------------------
// Description:     Top level for FPGA MAC
// Author:          Alexey Lavrov
// Company:         Princeton University
// Created:         1/25/2017
//--------------------------------------------------

module lewiz_eth_top (
    input                                   chipset_clk,

    input                                   rst_n,

    output                                  net_interrupt,

    input                                   noc_in_val,
    input       [`NOC_DATA_WIDTH-1:0]       noc_in_data,
    output                                  noc_in_rdy,

    output                                  noc_out_val,
    output      [`NOC_DATA_WIDTH-1:0]       noc_out_data,
    input                                   noc_out_rdy,

    input                                   net_axi_clk,
    output                                  net_phy_rst_n,

    input                                   net_phy_tx_clk,
    output                                  net_phy_tx_en,
    output  [3 : 0]                         net_phy_tx_data,
    
    input                                   net_phy_rx_clk,
    input                                   net_phy_dv,    
    input  [3 : 0]                          net_phy_rx_data,
    input                                   net_phy_rx_er,
    
    inout                                   net_phy_mdio_io,
    output                                  net_phy_mdc
);

`ifdef PITON_FPGA_ETHERNETLITE

// afifo <-> netbridge
wire                            afifo_netbridge_val;
wire    [`NOC_DATA_WIDTH-1:0]   afifo_netbridge_data;
wire                            netbridge_afifo_rdy;

wire                            netbridge_afifo_val;
wire    [`NOC_DATA_WIDTH-1:0]   netbridge_afifo_data;
wire                            fifo_netbridge_rdy;

// netbridge <-> mac axi
wire [12:0]                     net_s_axi_awaddr;
wire                            net_s_axi_awvalid;
wire                            net_s_axi_awready;

wire [31:0]                     net_s_axi_wdata;
wire [3:0]                      net_s_axi_wstrb;
wire                            net_s_axi_wvalid;
wire                            net_s_axi_wready;

wire [1:0]                      net_s_axi_bresp;
wire                            net_s_axi_bvalid;
wire                            net_s_axi_bready;

wire [12:0]                     net_s_axi_araddr;
wire                            net_s_axi_arvalid;
wire                            net_s_axi_arready;

wire [31:0]                     net_s_axi_rdata;
wire [1:0]                      net_s_axi_rresp;
wire                            net_s_axi_rvalid;
wire                            net_s_axi_rready;

// MDIO
wire                            net_phy_mdio_i;
wire                            net_phy_mdio_o;
wire                            net_phy_mdio_t;

wire net_phy_crs = 1'b0;
wire net_phy_col = 1'b0;

(* dont_touch = "true" *) wire unsync_net_int;

noc_bidir_afifo  net_afifo  (
    .clk_1           (chipset_clk           ),
    .rst_1           (~rst_n                ),

    .clk_2           (net_axi_clk           ),
    .rst_2           (~rst_n                ),

    // CPU --> EMACLITE
    .flit_in_val_1   (noc_in_val      ),
    .flit_in_data_1  (noc_in_data     ),
    .flit_in_rdy_1   (noc_in_rdy      ),

    .flit_out_val_2  (afifo_netbridge_val   ),
    .flit_out_data_2 (afifo_netbridge_data  ),
    .flit_out_rdy_2  (netbridge_afifo_rdy   ),

    // EMACLITE --> CPU
    .flit_in_val_2   (netbridge_afifo_val   ),
    .flit_in_data_2  (netbridge_afifo_data  ),
    .flit_in_rdy_2   (afifo_netbridge_rdy   ),

    .flit_out_val_1  (noc_out_val      ),
    .flit_out_data_1 (noc_out_data     ),
    .flit_out_rdy_1  (noc_out_rdy      )
);

noc_axilite_bridge #(
    .SLAVE_RESP_BYTEWIDTH   (4)
) noc_ethernet_bridge (
    .clk                    (net_axi_clk        ),
    .rst                    (~rst_n             ),      // TODO: rewrite to positive ?
           
    .splitter_bridge_val    (afifo_netbridge_val   ),
    .splitter_bridge_data   (afifo_netbridge_data  ),
    .bridge_splitter_rdy    (netbridge_afifo_rdy   ),   // CRAZY NAMING !

    .bridge_splitter_val    (netbridge_afifo_val   ),
    .bridge_splitter_data   (netbridge_afifo_data  ),
    .splitter_bridge_rdy    (afifo_netbridge_rdy   ),   // CRAZY NAMING !
       
    //axi lite signals             
    //write address channel
    .m_axi_awaddr        (net_s_axi_awaddr),
    .m_axi_awvalid       (net_s_axi_awvalid),
    .m_axi_awready       (net_s_axi_awready),

    //write data channel
    .m_axi_wdata         (net_s_axi_wdata),
    .m_axi_wstrb         (net_s_axi_wstrb),
    .m_axi_wvalid        (net_s_axi_wvalid),
    .m_axi_wready        (net_s_axi_wready),

    //read address channel
    .m_axi_araddr        (net_s_axi_araddr),
    .m_axi_arvalid       (net_s_axi_arvalid),
    .m_axi_arready       (net_s_axi_arready),

    //read data channel
    .m_axi_rdata         (net_s_axi_rdata),
    .m_axi_rresp         (net_s_axi_rresp),
    .m_axi_rvalid        (net_s_axi_rvalid),
    .m_axi_rready        (net_s_axi_rready),

    //write response channel
    .m_axi_bresp         (net_s_axi_bresp),
    .m_axi_bvalid        (net_s_axi_bvalid),
    .m_axi_bready        (net_s_axi_bready)
);

net_int_sync net_int_sync(
  .clk_emac(net_axi_clk),
  .clk_ciop(chipset_clk),
  .rst_n(rst_n),                          
  .net_int(unsync_net_int),
  .sync_int(net_interrupt)                          
);
   

mac_eth_axi_lite mac_eth_axi_lite (
  .s_axi_aclk       (net_axi_clk),       // input wire s_axi_aclk
  .s_axi_aresetn    (rst_n),    // input wire s_axi_aresetn
  .ip2intc_irpt     (unsync_net_int),     // output wire ip2intc_irpt
  .s_axi_awaddr     (net_s_axi_awaddr),     // input wire [12 : 0] s_axi_awaddr
  .s_axi_awvalid    (net_s_axi_awvalid),    // input wire s_axi_awvalid
  .s_axi_awready    (net_s_axi_awready),    // output wire s_axi_awready
  .s_axi_wdata      (net_s_axi_wdata),      // input wire [31 : 0] s_axi_wdata
  .s_axi_wstrb      (net_s_axi_wstrb),      // input wire [3 : 0] s_axi_wstrb
  .s_axi_wvalid     (net_s_axi_wvalid),     // input wire s_axi_wvalid
  .s_axi_wready     (net_s_axi_wready),     // output wire s_axi_wready
  .s_axi_bresp      (net_s_axi_bresp),      // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid     (net_s_axi_bvalid),     // output wire s_axi_bvalid
  .s_axi_bready     (net_s_axi_bready),     // input wire s_axi_bready
  .s_axi_araddr     (net_s_axi_araddr),     // input wire [12 : 0] s_axi_araddr
  .s_axi_arvalid    (net_s_axi_arvalid),    // input wire s_axi_arvalid
  .s_axi_arready    (net_s_axi_arready),    // output wire s_axi_arready
  .s_axi_rdata      (net_s_axi_rdata),      // output wire [31 : 0] s_axi_rdata
  .s_axi_rresp      (net_s_axi_rresp),      // output wire [1 : 0] s_axi_rresp
  .s_axi_rvalid     (net_s_axi_rvalid),     // output wire s_axi_rvalid
  .s_axi_rready     (net_s_axi_rready),     // input wire s_axi_rready

  .phy_rst_n        (net_phy_rst_n),        // output wire phy_rst_n

  .phy_tx_clk       (net_phy_tx_clk),       // input wire phy_tx_clk
  .phy_tx_en        (net_phy_tx_en),        // output wire phy_tx_en
  .phy_tx_data      (net_phy_tx_data),      // output wire [3 : 0] phy_tx_data
  
  .phy_rx_clk       (net_phy_rx_clk),       // input wire phy_rx_clk
  .phy_dv           (net_phy_dv),           // input wire phy_dv
  .phy_rx_data      (net_phy_rx_data),      // input wire [3 : 0] phy_rx_data
  .phy_rx_er        (net_phy_rx_er),        // input wire phy_rx_er

  .phy_crs          (net_phy_crs),          // input wire phy_crs
  .phy_col          (net_phy_col),          // input wire phy_col

  .phy_mdio_i       (net_phy_mdio_i),       // input wire phy_mdio_i
  .phy_mdio_o       (net_phy_mdio_o),       // output wire phy_mdio_o
  .phy_mdio_t       (net_phy_mdio_t),       // output wire phy_mdio_t
  .phy_mdc          (net_phy_mdc)           // output wire phy_mdc
);


register_interface register_interface1(
.reg_clk			(clk),						//i,   
.reset_				(reset_),        			//i,   
.host_addr			(host_addr),       	 		//o-16,
.reg_rd_start		(reg_rd_start),				//o,   
.reg_rd_done_out	(reg_rd_done_out),			//i,   
.mac_regdout		(mac_regdout),				//i-32,
.start				(start),					//i,   
.address			(address)                   //i-16,
);


   
LMAC_CORE_TOP lmac_core_top (
  .clk(net_axi_clk),           //i-1 250 Mhz // changed to 125 MHz - 7 june 2018  
  .xauiA_clk(net_axi_clk),     //i-1 156.25 Mhz  // changed to 125 MHz - 7 june 2018
  .gige_clk(net_axi_clk),     //i-1 125MHz
  .reset_(rst_n),     //i-1 FMAC specific reset
  .fmac_speed(),    //i(), 1G(), 23jul18
  .TCORE_MODE (1'b0), //i-1(), Always tie to 1     
// Interface to TX PATH
  .tx_mac_wr(),   // i-1
  .tx_mac_data(),  // i-64
  .tx_mac_full(),  // o-1
  .tx_mac_usedw(),  // o-13
// Interface to RX PATH
  .rx_mac_data(),  // o-64
  .rx_mac_ctrl(),  //o-8(), rsvd(), pkt_end(), pkt_start
  .rx_mac_empty(),  // o-1
  .rx_mac_rd(),   // i-1
  .rx_mac_rd_cycle(), // i-1(), from EXTR
//for field debug
  .rx_mac_full_dbg(), //o-1
  .rx_mac_usedw_dbg(), //o-12  
//for pre_CS/parser (I/F to RX Path/EXTR)
  .cs_fifo_rd_en  (), //i-1
  .cs_fifo_empty  (), //o-1
  .ipcs_fifo_dout (), //o-64  
//gige_gmii 11 July 2018
  .gmii_txd(), 
  .gmii_txc(),
  .gmii_tx_en(),   //12 july 2018
  .gmii_tx_vld(),  //17 july 2018  
                       
  .xauiA_linkup(),  // o-1(), link up for either 10G or 10G mode
 
// From central decoder 
  .host_addr_reg(),  // i-16
  .SYS_ADDR(),   //i-4(), system assigned addr for the FMAC
  
// From mac_register
  .fail_over(),   // i-1
  .fmac_ctrl(),   // i-32
  .fmac_ctrl1(),   // i-32
 
  .fmac_rxd_en (),  //i-1(), 13jul11

  .mac_pause_value(), // i-32
  .mac_addr0(),    // i-48
  .mcast_saddr(),   // i-48
 
  .reg_rd_start(),  // i-1
  .reg_rd_done(),  // i-1
  
// To mac_register
  .FMAC_REGDOUT(),  // o-32
  .FIFO_OV_IPEND(),  // o-1

//gige_rx_gmii signals 16jul2018
  .gmii_rxd(),   //i-8
  .gmii_rxc(),   //i-1
  .gmii_rx_dv(),   //i-1

  .sfp_los()    //i-1(), assign to zero   
			
);

   
// Tri-state buffer
IOBUF u_iobuf_dq (
    .I  (net_phy_mdio_o),
    .O  (net_phy_mdio_i),
    .T  (net_phy_mdio_t),
    .IO (net_phy_mdio_io)
);

`else   // PITON_FPGA_ETHERNETLITE

    assign noc_in_rdy    = 1'b0;
    assign noc_out_val    = 1'b0;
    assign noc_out_data   = {`NOC_DATA_WIDTH{1'b0}};

    assign net_phy_tx_en        = 1'b0;
    assign net_phy_mdc          = 1'b0;

`endif  // PITON_FPGA_ETHERNETLITE

endmodule
