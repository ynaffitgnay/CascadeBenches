//`timescale 1ns/1ps
module file_mem (
  input  wire                         clk,
  input  wire                         off
);

    integer lutstream = $fopen("some_file.txt"); 
    integer i = 0;

    // Counter
    integer ctr;
    always @(posedge clk) begin
        ctr <= ctr + 1;
    end


    always @ (posedge clk) begin
        if (ctr > 10) begin
            $finish(1);
        end else begin
            $fseek(lutstream, off, 0);
            $fwrite(lutstream, "ctr: %d ", ctr);
            $fflush(lutstream);
        end            
    end

endmodule

reg offset;
initial offset <= 100;


file_mem tr(clock.val, offset);
