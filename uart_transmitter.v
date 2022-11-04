module uart_transmitter(
    input           clk,
    input           rst_n,
    input           receive_done, // 1:receive over
    input [7:0]     data_receive, // transfer received data to parallel data 
    output reg      uart_txd
    );
        
    // the definition of some important periods
    parameter SYS_PERIOD        = 50_000_000;       // my FPGA clock period
    parameter BPS               = 115_200;          // my defined BPS(bit/s)
    parameter HALF_BIT_PERIOD   = SYS_PERIOD/BPS/2; // HALF_BIT_PERIOD = 217 , each half_bit transmit_time_cnt
                                                    // 10bits data needs transmit_time_cnt = 217*20 = 4340 
    
    reg [14:0]   transmit_time_cnt; // counting for receiving data
    reg          transmit_flag;     // transmit_flag = 1 in the period of 10bits transmitting
    wire [7:0]   data_temp;         // save receiving data

    assign data_temp = receive_done ? data_receive : data_temp;  // save data_receive to data_temp when finished receiving

    // transmit_time_cnt start counting when receive_done = 1, sending 10bits data needs 217*20 = 4340 counting
    always @(posedge clk, negedge rst_n) begin
        if (!rst_n ) 
            transmit_time_cnt <= 15'd0;
        else if(transmit_flag)
            transmit_time_cnt <= (transmit_time_cnt == 20*HALF_BIT_PERIOD) ? 15'd0 : transmit_time_cnt + 1'b1; 
        else 
            transmit_time_cnt <= 15'd0;   
    end

    // when uart_rxd's negedge is coming, transmit_time_cnt start counting. transmit_flag = 1 in the period of 10bits transmitting
    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) 
            transmit_flag <= 1'b0;
        else begin
            if (receive_done)
                transmit_flag <= 1'b1;
            else if (transmit_time_cnt == 20*HALF_BIT_PERIOD) 
                transmit_flag <= 1'b0;
            else 
                transmit_flag <= transmit_flag;       
        end
    end

    // transmit data
    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) 
            uart_txd <= 1'b1;
        else if (transmit_flag) begin
            case (transmit_time_cnt) 
                 0*HALF_BIT_PERIOD: 
                    uart_txd <= 0;            // transmitting start bit = 0
                 2*HALF_BIT_PERIOD: 
                    uart_txd <= data_temp[0]; // transmitting 1st data
                 4*HALF_BIT_PERIOD: 
                    uart_txd <= data_temp[1]; // transmitting 2nd data
                 6*HALF_BIT_PERIOD: 
                     uart_txd <= data_temp[2]; // transmitting 3rd data
                 8*HALF_BIT_PERIOD: 
                    uart_txd <= data_temp[3]; // transmitting 4th data
                10*HALF_BIT_PERIOD: 
                    uart_txd <= data_temp[4]; // transmitting 5th data
                12*HALF_BIT_PERIOD: 
                    uart_txd <= data_temp[5]; // transmitting 6th data
                14*HALF_BIT_PERIOD: 
                    uart_txd <= data_temp[6]; // transmitting 7th data
                16*HALF_BIT_PERIOD: 
                    uart_txd <= data_temp[7]; // transmitting 8th data
                18*HALF_BIT_PERIOD: 
                    uart_txd <= 1;            // transmitting stop bit = 1
                default:            
                    uart_txd <= uart_txd;
            endcase
        end
        else 
            uart_txd <= uart_txd;
    end
endmodule
