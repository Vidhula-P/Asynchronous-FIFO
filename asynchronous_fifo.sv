// circular FIFO design where read and write have different clocks
module asynchronous_fifo #(
  parameter DEPTH = 8,
  parameter WIDTH = 8
)(
  input  wire              wr_clk,
  input  wire              rd_clk,
  input  wire              reset,

  input  wire              write_en,
  input  wire [WIDTH-1:0]  write_data,

  input  wire              read_en,
  output reg  [WIDTH-1:0]  read_data,

  output wire 			   full,
  output wire 			   empty
);
  
  parameter ADDR = $clog2(DEPTH);
  
  reg [WIDTH-1:0] mem [DEPTH-1:0];
  reg [ADDR:0] wr_ptr, rd_ptr; // MSB bit checks overflow/ if full
  int i; // loop variable
  
  
  // write
  always @(posedge wr_clk or posedge reset) begin
    if (reset) begin
      wr_ptr <= '0;
      for (i = 0; i < DEPTH; i = i + 1) begin
        mem[i] <= 0;
      end
    end else if(write_en && !full) begin
      mem [wr_ptr[ADDR-1:0]] <= write_data;
      wr_ptr <= wr_ptr + 1;
    end
  end
  
  // read
  always @(posedge rd_clk or posedge reset) begin
    if (reset) begin
      rd_ptr <= '0;
    end else if(read_en && !empty) begin
      read_data <= mem [rd_ptr[ADDR-1:0]];
      rd_ptr <= rd_ptr + 1;
    end
  end
  
  assign empty = (wr_ptr[ADDR-1:0] == rd_ptr[ADDR-1:0]) && (wr_ptr[ADDR]==1'b0);
  assign full  = (wr_ptr[ADDR-1:0] == rd_ptr[ADDR-1:0]) && (wr_ptr[ADDR]==1'b1);
  
endmodule