module uart(
    input               clk,
    input               rst_n,
    input               uart_rxd, // receive data from PC
    output              uart_txd  // transmit data to PC
   );

    // the definition of some important periods
    parameter SYS_PERIOD        = 50_000_000;       // my FPGA clock period
    parameter BPS               = 115_200;          // my defined BPS(bit/s)
    parameter HALF_BIT_PERIOD   = SYS_PERIOD/BPS/2; // HALF_BIT_PERIOD = 217 , each half_bit time_cnt
                                                    // 10bits data needs time_cnt = 217*20 = 4340 
    wire        receive_done; // 1:receive over
    wire [7:0]  data_receive; // transfer received data to parallel data 
    
    uart_receiver #(
        .SYS_PERIOD     (SYS_PERIOD),
        .BPS            (BPS),
        .HALF_BIT_PERIOD(HALF_BIT_PERIOD)
    )u_uart_receiver
    (
        .clk            (clk),//input
        .rst_n          (rst_n),
        .uart_rxd       (uart_rxd),
        .receive_done   (receive_done),//output
        .data_receive   (data_receive) 
    );

    uart_transmitter #(
        .SYS_PERIOD     (SYS_PERIOD),
        .BPS            (BPS),
        .HALF_BIT_PERIOD(HALF_BIT_PERIOD)
    )u_uart_transmitter(
        .clk            (clk),//input
        .rst_n          (rst_n),
        .receive_done   (receive_done),
        .data_receive   (data_receive),
        .uart_txd       (uart_txd)//output
    );

endmodule