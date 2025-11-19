
module i2c_slave (rstb, ready, start, stop, data_in, data_out, r_w, data_vld, scl_in, scl_oe, sda_in, sda_oeb);
      
// generic ports
input        rstb;                // System Reset
input        ready;               // back end system ready signal
//input  [6:0] I2C_SLAVE_ADDR;    // I2C addr from regmap
input  [7:0] data_in;             // parallel data in
output [7:0] data_out;            // parallel data out 
output       r_w;                 // read/write signal to the reg_map block
output       data_vld;            // data valid from i2c 
output       start;               // start of the i2c cycle
output       stop;                // stop the i2c cycle

// i2c ports
input        scl_in;              // SCL clock line
output       scl_oe;
input        sda_in;              // i2c serial data line in
output       sda_oeb;             // controls sda output enable


/*****************************************
 Define states of the state machine
*****************************************/

parameter I2C_SLAVE_ADDR = 7'b1010010;

parameter idle=5'h0,   addr7=5'h1, addr6=5'h2, addr5=5'h3, 
          addr4=5'h4,  addr3=5'h5, addr2=5'h6, addr1=5'h7,
          det_rw=5'h8, ack=5'h9,   data7=5'ha, data6=5'hb, 
          data5=5'hc,  data4=5'hd, data3=5'he, data2=5'hf, 
          data1=5'h10, data0=5'h11;

reg [7:0] data_int;               // internal data register
reg start, stop;                  // start and stop detection of I2C cycles
reg [4:0] sm_state;               // state machine
reg [7:0] shift;                  // shift register attached to I2C controller
reg r_w;                          // indicate read/write operation
reg ack_out;                      // acknowledge output from slave to master
reg sda_en;                       // OE control of sda signal, could use open drain feature
reg vld_plse;                     // data valid pulse

wire start_rst;                   // reset signals for START and STOP bits

/*****************************************
 Generate reset signals for start and stop
*****************************************/
assign start_rst = (sm_state == addr7) ? 1'b1 : 1'b0;    // used to reset the start register after we move to addr7

wire start_async_rst = start_rst | !rstb;                // oring the reset signal external and internal
wire stop_async_rst  = start | !rstb;                    // same for stop reset

/*****************************************
 Detect I2C Cycle Start
*****************************************/
always @ (negedge sda_in or posedge start_async_rst) begin
  if (start_async_rst) begin
    start <= 1'b0;
  end
  else begin 
    start <= scl_in;
  end
end

/*****************************************
 Detect I2C Cycle Stop
*****************************************/
always @(posedge sda_in or posedge stop_async_rst) begin
  if (stop_async_rst) begin
    stop <= 1'b0;
  end
  else begin 
    stop <= scl_in;
  end
end

/*****************************************
 FSM check the addr byte and track rw opp
*****************************************/
always @(posedge scl_in or negedge rstb) begin
  if (!rstb) begin
    sm_state <= idle;        // reset fsm to idle
    r_w      <= 1'b1;        // initial value for read
    vld_plse <= 1'b0;
  end
  else begin

    case (sm_state)

      idle : begin
        vld_plse <= 1'b0;
        if (start) begin      // start the I2C addr cycle
          sm_state <= addr7;
        end
        else if (stop) begin  // stop and go to idle
          sm_state <= idle;
        end 
        else begin
          sm_state <= idle;
        end 
      end

      addr7 : begin
        if (shift[0] == I2C_SLAVE_ADDR[6]) begin // checking the slave addr
          sm_state <= addr6;
        end 
        else begin
          sm_state <= idle;
        end
      end

      addr6 : begin
        if (shift[0] == I2C_SLAVE_ADDR[5]) begin
          sm_state <= addr5;
        end
        else begin
          sm_state <= idle;
        end
      end

      addr5 : begin
        if (shift[0] == I2C_SLAVE_ADDR[4]) begin
          sm_state <= addr4;
        end
        else begin
          sm_state <= idle;
        end
      end

      addr4 : begin
        if (shift[0] == I2C_SLAVE_ADDR[3]) begin
          sm_state <= addr3;
        end
        else begin
          sm_state <= idle;
        end
      end

      addr3 : begin
        if (shift[0] == I2C_SLAVE_ADDR[2]) begin
          sm_state <= addr2;
        end
        else begin
          sm_state <= idle;
        end
      end

      addr2 : begin
        if (shift[0] == I2C_SLAVE_ADDR[1]) begin
          sm_state <= addr1;
        end
        else begin
          sm_state <= idle;
        end
      end

      addr1 : begin
        if (shift[0] == I2C_SLAVE_ADDR[0]) begin
          sm_state <= det_rw;
          r_w      <= sda_in;    // store the read / write direction bit
        end
        else begin
          sm_state <= idle;
        end
      end

      det_rw : begin
        sm_state <=  ack;
      end

      ack : begin 
        if (ready) begin
          sm_state <=  data7;
          vld_plse <=  1'b0;
        end
        else begin
          sm_state <= idle;  
          vld_plse <= 1'b0;
        end
      end

      data7 : begin
        if (stop) begin
          sm_state <= idle;         // detect stop signal from Master 
        end
        else if (start) begin
          sm_state <= addr7;        // detect RESTART signal from Master
        end
        else begin
          sm_state <= data6;
        end
      end

      data6 : begin
        sm_state <=  data5;
      end

      data5 : begin
        sm_state <=  data4;
      end

      data4 : begin 
        sm_state <=  data3;
      end

      data3 : begin
        sm_state <=  data2;
      end

      data2 : begin
        sm_state <=  data1;
      end

      data1 : begin
        sm_state <=  data0;
        vld_plse <= 1'b1;
      end

      data0 : begin  
        vld_plse <= 1'b0;   // detect repeated read, write or read/write 
        
        if (!sda_in & ~r_w) begin       // 0 means acknowledged 
          sm_state <= ack;
        end
        else if (!sda_in & r_w) begin   // 0 means acknowledged 
          sm_state <= ack;
        end
        else begin
          sm_state <= idle;
        end
      end
      
      default : begin
        sm_state <= idle;
      end
    
    endcase
  end
end

/********************************************
 Read cycle (slave trasmit, master receive)  
 Write Cycle (slave receive, master transmit)
 Slave generate ACKOUT during write cycle    
********************************************/

always @(negedge scl_in or negedge rstb) begin  // data should be ready on SDA line when SCL is high
  if (!rstb) begin
    ack_out <= 1'b0;
  end
  else if (sm_state == det_rw) begin
    ack_out <= 1'b1;
  end
  else if (sm_state == data0) begin
    if (!r_w) begin                             // if slave is rx, acknowledge after successful receive
      ack_out <= 1'b1;
    end
	  else begin                                  // if slave is tx, acknowledge comes from Master
      ack_out <= 1'b0;
    end
  end
  else begin
    ack_out <= 1'b0;
  end
end

/********************************************
 Enable starting from ACK state              
********************************************/
always @(negedge scl_in or negedge rstb) begin
  if (!rstb) begin
    sda_en <= 1'b0;
  end
  else if (r_w && (sm_state == ack)) begin
    sda_en <= !data_in[7];
  end
  else if (r_w && ((sm_state > ack) && (sm_state < data0))) begin
    sda_en <= ~shift[6];
  end
  else begin
    sda_en <= 1'b0;
  end
end

/********************************************
 SDA OE cntr gen '1' will pull the line low
********************************************/

assign sda_oeb = !((ack_out == 1'b1) | (sda_en == 1'b1));    // sda_out is logic '0' at the top level.
                                                             // sda_oeb cntrl sda_out at top level

assign scl_oe = (sm_state == ack) & (~ready);                // if scl_oe = 1, then scl is pulled down

/*******************************
 Shift operation for READ data
*******************************/
always @(negedge scl_in or negedge rstb) begin
  if (!rstb) begin                                           // Reset added to make it work
    shift <= 8'b0;
  end
  else begin
    if ((sm_state == idle) && (start)) begin
      shift[0] <= sda_in;
    end
	  else if ((sm_state >= addr7) && (sm_state <= addr1)) begin
      shift[0] <= sda_in;
    end
	  else if (r_w && (sm_state == ack)) begin                 // 2nd version    
      shift <= data_in;                                      // load the GPIO data into shift registers
    end
	  else if ((sm_state > ack) && (sm_state <= data0)) begin  // start shift the data out to SDA line // 2nd version 
      shift[7:1] <= shift[6:0];
      shift[0]   <= sda_in;
    end
  end
end

/********************************************
 data output register
********************************************/
always @ (posedge scl_in or negedge rstb) begin
  if (!rstb) begin
    data_int <= 8'h0;
  end 
  else begin 
    if (!r_w && ack_out && vld_plse) begin 
      data_int <= shift;
	  end
  end	
end

assign data_out = data_int;
assign data_vld = vld_plse;

endmodule
