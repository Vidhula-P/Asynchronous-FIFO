// burst length = 16 words
// write frequency = 10 ns
// read  frequency = 20 ns
// Hence, minimum FIFO depth = 16 - (16 x 10)/20 = 8

module asynchronous_fifo_tb;
  
  parameter DEPTH = 8;
  parameter WIDTH = 8;
  parameter BURST_LENGTH = 10;
  
  logic wr_clk, rd_clk, reset, write_en, read_en;
  logic [WIDTH-1:0] write_data; 
  logic [WIDTH-1:0] read_data;
  logic full, empty;
  
  int i; // loop variable
  int burst_counter;
  
  asynchronous_fifo #(DEPTH, WIDTH) f1 (wr_clk, rd_clk, reset, 
                           write_en, write_data,
                           read_en, read_data,
                           full, empty);
  
  covergroup cg_wr @(posedge wr_clk);
    writing: coverpoint write_data {
      bins valid_wr[] = {[8'h01:8'h1a]};
      bins transition = ( 8'h01 => 8'h02 => 8'h05 );
    }
  endgroup
  
  covergroup cg_rd @(posedge rd_clk);
  	reading: coverpoint read_data {
      bins valid_wr[] = {[8'h01:8'h1a]};
    }
  endgroup

  cg_wr cg_wr_inst = new();
  cg_rd cg_rd_inst = new();
  
  initial wr_clk = 0;
  always #5 wr_clk = ~wr_clk;
  
  initial rd_clk = 0;
  always #10 rd_clk = ~rd_clk; // read is slower
  
  initial begin
    $dumpfile("asynchronous_fifo.vcd");   // name of waveform file
    $dumpvars(0, asynchronous_fifo_tb);   // dump all signals in testbench hierarchy
    reset = 0;
    #2 reset = 1;
    #10 reset = 0;
    repeat (30) @(posedge rd_clk);
    $display("SPI monitor read coverage = %0.2f",
             cg_rd_inst.get_inst_coverage());
    $display("SPI monitor write coverage = %0.2f",
             cg_wr_inst.get_inst_coverage());
    $finish;
  end
  
  always @(posedge wr_clk) begin
    if (reset) begin
      burst_counter <= 0;
      write_data <= 0;
      write_en <= 0;
    end else if (!full && burst_counter < BURST_LENGTH) begin
      write_en <= 1;
      write_data <= write_data + 1;
      burst_counter <= burst_counter + 1;
    end else if (burst_counter == BURST_LENGTH) begin
      write_en <= 0;
      write_data <= write_data - 1; // to be able to see continuous values
      burst_counter <= 0;
    end
  end
  
  always @(posedge rd_clk) begin
    if (reset) begin
      read_en <= 0;
    end else begin
      read_en <= !empty;
      if (read_en && !empty)
        $strobe("Read- %0h", read_data);
    end
  end
  
endmodule