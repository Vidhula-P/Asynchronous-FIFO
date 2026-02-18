module asynchronous_fifo_tb;
  
  parameter DEPTH = 4;
  parameter WIDTH = 8;
  
  reg wr_clk, rd_clk, reset, write_en, read_en;
  reg  [WIDTH-1:0] write_data; 
  wire [WIDTH-1:0] read_data;
  wire full, empty;
  
  int i; // loop variable
  int counter;
  
  asynchronous_fifo #(DEPTH, WIDTH) f1 (wr_clk, rd_clk, reset, 
                           write_en, write_data,
                           read_en, read_data,
                           full, empty);
  
  initial wr_clk = 0;
  always #5 wr_clk = ~wr_clk;
  
  initial rd_clk = 0;
  always #5 rd_clk = ~rd_clk; // read is slower
  
  initial begin
    $dumpfile("asynchronous_fifo.vcd");   // name of waveform file
    $dumpvars(0, asynchronous_fifo_tb);   // dump all signals in testbench hierarchy
    reset = 0;
    counter = 0;
    write_en = 0;
    read_en = 0;
    write_data = 8'h00;
    #2 reset = 1;
    #5 reset = 0;
  end
  
  always @(posedge wr_clk) begin
    if (!reset && !full) begin
      write_en <= 1;
      write_data <= write_data + 1;
      counter <= counter + 1;
      if (counter == 8'd10)
        $finish;
    end
  end
  
  always @(posedge rd_clk) begin
    if (!reset) begin
      read_en <= 1;
      if (!empty) 
      	$strobe("Read- %0h", read_data);
      else
        $display("FIFO empty");
    end
  end
  
endmodule