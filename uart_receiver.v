module uart_receiver(
    input               clk,
    input               rst_n,
    input               uart_rxd,       // receive data from PC
    output              receive_done,   // 1:receive over
    output reg [7:0]    data_receive    // transfer received data to parallel data 
    );

    // the definition of some important periods
    parameter SYS_PERIOD        = 50_000_000;       // my FPGA clock period
    parameter BPS               = 115_200;          // my defined BPS(bit/s)
    parameter HALF_BIT_PERIOD   = SYS_PERIOD/BPS/2; // HALF_BIT_PERIOD = 50000000/115200 = 217 , each half_bit receive_time_cnt
                                                    // 10bits data needs receive_time_cnt = 217*20 = 4340 
    
    reg [14:0]  receive_time_cnt;                   // counting for receiving data
    reg         uart_rxd_delay1, uart_rxd_delay2;   // to find negedge of uart_rxd
    reg         start_flag;                         // the flag to start 
    reg         receive_flag;                       // receive_flag = 1 in the period of receiving datas
  
    // when receive_receive_time_cnt = 20*HALF_BIT_PERIOD, it means data finished receiving, then receive_done = 1.
    assign receive_done = (receive_time_cnt == 20*HALF_BIT_PERIOD);

    // clk delay for 2 periods, to check the coming of uart_rxd's negedge(for starting receiving) 
    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            uart_rxd_delay1 <= 1'b0;
            uart_rxd_delay2 <= 1'b0;
        end
        else begin
            uart_rxd_delay1 <= uart_rxd;
            uart_rxd_delay2 <= uart_rxd_delay1;
        end
        start_flag <= (~uart_rxd) & uart_rxd_delay2; // start_flag = 1, when negedge's coming
    end

    // receive_time_cnt start counting when reveive_flag=1, receiving 10bits data needs 217*20 = 4340 counting
    always @(posedge clk, negedge rst_n) begin
        if (!rst_n ) 
            receive_time_cnt <= 15'd0;
        else if(receive_flag)
            receive_time_cnt <= (receive_time_cnt == 20*HALF_BIT_PERIOD) ? 15'd0 : receive_time_cnt + 1'b1; 
        else 
            receive_time_cnt <= 15'd0;   
    end

    // when uart_rxd's negedge is coming, receive_time_cnt start counting. receive_flag = 1 in the period of 10bits receiving
    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) 
            receive_flag <= 1'b0;
        else begin
            if (start_flag)
                receive_flag <= 1'b1;
            else if ((receive_time_cnt == 20*HALF_BIT_PERIOD)  && (uart_rxd==1'b1)) 
                receive_flag <= 1'b0;
            else 
                receive_flag <= receive_flag;       
        end
    end

  
    // data receiving
    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) 
            data_receive <= 8'b0;
        else if (receive_flag) begin
            case (receive_time_cnt) 
                 3*HALF_BIT_PERIOD: 
                    data_receive[0] <= uart_rxd; // receiving 1st data
                 5*HALF_BIT_PERIOD: 
                    data_receive[1] <= uart_rxd; // receiving 2nd data
                 7*HALF_BIT_PERIOD: 
                    data_receive[2] <= uart_rxd; // receiving 3st data
                 9*HALF_BIT_PERIOD: 
                    data_receive[3] <= uart_rxd; // receiving 4st data
                11*HALF_BIT_PERIOD: 
                    data_receive[4] <= uart_rxd; // receiving 5st data
                13*HALF_BIT_PERIOD: 
                    data_receive[5] <= uart_rxd; // receiving 6st data
                15*HALF_BIT_PERIOD: 
                    data_receive[6] <= uart_rxd; // receiving 7st data
                17*HALF_BIT_PERIOD: 
                    data_receive[7] <= uart_rxd; // receiving 8st data
                default:            
                    data_receive    <= data_receive;
            endcase
        end
        else 
            data_receive <= data_receive;
    end

endmodule