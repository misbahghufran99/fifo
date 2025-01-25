`timescale 1ns/1ps

module tb_fifo ();

  //parameters
  parameter   DEPTH   =   128               ;
  parameter   WIDTH   =   32                ;



  //signals
  logic                 i_clk               ;      // Clock
  logic                 arst_n              ;      // active low Reset
  logic                 wr_en               ;      // Write enable
  logic                 rd_en               ;      // Read enable
  logic   [WIDTH-1:0]   wr_data             ;      // Write data
  logic   [WIDTH-1:0]   rd_data             ;      // Read data
  logic                 o_full              ;      // FIFO o_full flag
  logic                 o_empty             ;      // FIFO o_empty flag


  //internal logic 
  logic   [WIDTH-1:0]   ref_queue[$]        ;      // Reference Queue to push data_in
  logic   [WIDTH-1:0]   exp_data            ;      // exoected data
  int                   error_count = 0     ;      //for counting errors
  int                   num_seq     = 50    ;      // number of test sequences



  //dut instantiation
  fifo #(.DEPTH(DEPTH), .WIDTH(WIDTH))uut(
    .i_clk      (i_clk)     ,
    .arst_n     (arst_n)    , 
    .o_full     (o_full)    , 
    .o_empty    (o_empty)   , 
    .wr_en      (wr_en)     , 
    .rd_en      (rd_en)     , 
    .rd_data    (rd_data)   , 
    .wr_data    (wr_data)
    );

  logic   [$clog2(DEPTH):0 ]       rd_ptr   ;       // Read pointer
  logic   [$clog2(DEPTH):0 ]       wr_ptr   ;       // Write pointer
  logic   [$clog2(DEPTH):0 ]       count    ;       // Counter to track entries in FIFO
  logic   [128-1:0] [32-1:0]      fifo_mem  ;       // FIFO memory array packed array 


  assign    rd_ptr     =     uut.rd_ptr     ;
  assign    wr_ptr     =     uut.wr_ptr     ;
  assign    count      =     uut.count      ;
  assign    fifo_mem   =     uut.fifo_mem   ;


  // Clock generation
  always begin
      i_clk <= 0; #10;
      i_clk <= 1; #10;
  end


  // Reset logic
  initial begin
      i_clk     <= 0;
      arst_n    <= 0;
      wr_en     <= 0;
      rd_en     <= 0;
      wr_data   <= 0;
      // ref_queue <= {};
      exp_data  <= 0;
      
      // Wait for a few positive edges before de-asserting reset
      repeat (2) @(posedge i_clk);
      arst_n    <= 1;                // De-assert reset
  end



  initial begin

      repeat (num_seq) begin
          // Random write operation
          if ((!$urandom_range(0, 3)) && (!o_full) && (arst_n)) begin
              wr_en   <= 1;
              wr_data <= $random;
          end else begin
              wr_en <= 0;
          end

          // Random read operation    
          if ((!$urandom_range(0, 3)) && (!o_empty) && (arst_n)) begin
              rd_en <= 1;
          end else begin
              rd_en <= 0;
          end
          
          @(posedge i_clk); // Wait for the clock edge before pushing or popping

          // Perform the push_back operation after checking wr_en
          if (wr_en && !o_full) begin
              ref_queue.push_back(wr_data);
          end

          // Perform the pop_front operation after checking rd_en
          if (rd_en && !o_empty) begin
              exp_data <= ref_queue.pop_front();
          end

          // Verify read data
          if (rd_en && !o_empty) begin
              if (rd_data !== exp_data) begin
                  $display("ERROR at time %0t: DUT rd_data <= %h, Expected <= %h", $time, rd_data, exp_data);
                  error_count <= error_count + 1;
              end else begin
                  $display("PASS at time %0t: rd_data <= %h", $time, rd_data);
              end
          end
      end


      // // Additional sequence: Write until full, then test full write
      // repeat (DEPTH + 10) begin
      //     if (!o_full) begin
      //         wr_en <= 1;
      //         wr_data <= $random;
      //         @(posedge i_clk);
      //     end else begin
      //         wr_en <= 0;
      //         @(posedge i_clk);
      //         if (o_full && wr_en) begin
      //             $display("INFO: Tried to write when FIFO is full at time %0t", $time);
      //         end
      //     end
      // end


      // // Additional sequence: Read until empty, then test empty read
      // repeat (DEPTH + 10) begin
      //     if (!o_empty) begin
      //         rd_en <= 1;
      //         @(posedge i_clk);
      //         if (o_empty && rd_en) begin
      //             $display("INFO: Tried to read when FIFO is empty at time %0t", $time);
      //         end
      //     end else begin
      //         rd_en <= 0;
      //     end
      //     @(posedge i_clk);
      // end

      



      // Report results
      $display("Test complete. Errors: %d", error_count);
      $stop                                             ;  
  end 


endmodule