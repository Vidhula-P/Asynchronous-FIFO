// minimum depth ≈ 2 x clock ratio
// Hence FIFO DEPTH > 4 

module asynchronous_fifo_tb;
  
  parameter DEPTH = 8;
  parameter WIDTH = 8;
  
  logic wr_clk, rd_clk, reset, write_en, read_en;
  logic  [WIDTH-1:0] write_data; 
  logic [WIDTH-1:0] read_data;
  logic full, empty;
  
  int i; // loop variable
  
  asynchronous_fifo #(DEPTH, WIDTH) f1 (wr_clk, rd_clk, reset, 
                           write_en, write_data,
                           read_en, read_data,
                           full, empty);
  
  initial wr_clk = 0;
  always #5 wr_clk = ~wr_clk;
  
  initial rd_clk = 0;
  always #10 rd_clk = ~rd_clk; // read is slower
  
  initial begin
    $dumpfile("asynchronous_fifo.vcd");   // name of waveform file
    $dumpvars(0, asynchronous_fifo_tb);   // dump all signals in testbench hierarchy
    reset = 0;
    write_en = 0;
    read_en = 0;
    write_data = 8'h00;
    #2 reset = 1;
    #10 reset = 0;
    repeat (30) @(posedge rd_clk);
    $finish;
  end
  
  always @(posedge wr_clk) begin
    if (!reset && !full) begin //after reset deasserted and if FIFO not full
      write_en <= 1;
      write_data <= write_data + 1;
    end
  end
  
  always @(posedge rd_clk) begin
    if (reset)
      read_en <= 0;
    else begin
      read_en <= !empty;
      if (read_en && !empty)
        $display("Read- %0h", read_data);
    end
  end
  
endmodule