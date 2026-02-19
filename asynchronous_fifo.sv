// circular FIFO design where read and write have different clocks
// We will keep binary pointers for addressing, but transport 
// Gray-coded pointers across clock domains.

module asynchronous_fifo #(
  parameter DEPTH = 8,
  parameter WIDTH = 8
)(
  input  logic              wr_clk,
  input  logic              rd_clk,
  input  logic              reset,

  input  logic              write_en,
  input  logic [WIDTH-1:0]  write_data,

  input  logic              read_en,
  output logic  [WIDTH-1:0]  read_data,

  output logic 			   full,
  output logic 			   empty
);

  parameter ADDR = $clog2(DEPTH);
  
  logic [WIDTH-1:0] mem [DEPTH-1:0];
  logic [ADDR:0] wr_ptr_bin, rd_ptr_bin; // MSB bit checks overflow/ if full
  logic [ADDR:0] wr_ptr_gray, rd_ptr_gray;
  logic [ADDR:0] wr_ptr_gray_next;
  int i; // loop variable
  
  // write synchronizer (into read clock domain)
  logic [ADDR:0] wr_ptr_gray_sync1, wr_ptr_gray_sync2;
  always @(posedge rd_clk or posedge reset) begin
    if(reset) begin
      wr_ptr_gray_sync1 <= 0;
      wr_ptr_gray_sync2 <= 0;
    end else begin
      wr_ptr_gray_sync1 <= wr_ptr_gray; // meta-stable
      wr_ptr_gray_sync2 <= wr_ptr_gray_sync1; // stable
    end
  end
  
  // read synchronizer (into write clock domain)
  logic [ADDR:0] rd_ptr_gray_sync1, rd_ptr_gray_sync2;
  always @(posedge wr_clk or posedge reset) begin
    if(reset) begin
      rd_ptr_gray_sync1 <= 0;
      rd_ptr_gray_sync2 <= 0;
    end else begin
      rd_ptr_gray_sync1 <= rd_ptr_gray; // meta-stable
      rd_ptr_gray_sync2 <= rd_ptr_gray_sync1; // stable
    end
  end
  
  // write
  always @(posedge wr_clk or posedge reset) begin
    if (reset) begin
      wr_ptr_bin <= '0;
      for (i = 0; i < DEPTH; i = i + 1) begin
        mem[i] <= 0;
      end
    end else begin
      if(write_en && !full) begin
        mem [wr_ptr_bin[ADDR-1:0]] <= write_data;
        wr_ptr_bin <= wr_ptr_bin + 1;
      end
    end
  end
  
  // read
  always @(posedge rd_clk or posedge reset) begin
    if (reset) begin
      rd_ptr_bin <= '0;
    end else begin
      if(read_en && !empty) begin
        read_data <= mem [rd_ptr_bin[ADDR-1:0]];
        rd_ptr_bin <= rd_ptr_bin + 1;
      end
    end
  end
  
  assign rd_ptr_gray      = rd_ptr_bin ^ (rd_ptr_bin >> 1);
  assign wr_ptr_gray      = wr_ptr_bin ^ (wr_ptr_bin >> 1);
  // calculate next write pointer to determine if full to avoid writing to a full FIFO
  assign wr_ptr_gray_next = (wr_ptr_bin+1) ^ ((wr_ptr_bin+1) >> 1);
  
  assign empty = ( rd_ptr_gray == wr_ptr_gray_sync2 );
  assign full  = ( {~rd_ptr_gray_sync2[ADDR:ADDR-1], rd_ptr_gray_sync2[ADDR-2:0]} ==  wr_ptr_gray_next);
  // flipping 2 MSB bits in gray code is equivalent ti flipping 1MSB bit in binary 
  // ex- 4'b0000 -> 4'b1000 FIFO full
  //	 4'g0000 -> 4'g1100 FIFO full
  // 4'b1000 == 4'g1100. This is no coincidence. 
  // Mathematically, bin to gray conversion depends on current bit + bit to the right.
 
  
endmodule