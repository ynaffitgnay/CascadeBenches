module test_status
#(
    parameter         PREFIX  = "TEST_MODULE",
    parameter integer TIMEOUT = 100
)
(
    input wire      clk,
    input wire      reset,
    input wire      fail,
    input wire      pass
);

//task watchdog;
//  input integer timeout;
//  begin
//    repeat(timeout) begin
//        #1;
//    end
//    $display;
//    $display("ERROR: Timeout. Increase the parameter TIMEOUT of test_status module to prevent early termination of test bench");
//    test_fail;
//  end
//endtask
    reg [31:0] ctr;  // keep track of number of cycles into current loop
    reg [2:0] state;

    parameter idle = 3'd0;
    parameter start = 3'd1;
    parameter check_status = 3'd2;
    parameter test_fail = 3'd3;
    parameter test_pass = 3'd4;
    parameter finish = 3'd5;

    initial begin
        ctr <= 0;
        state <= start;
    end

    always @(posedge clk) begin
        ctr <= ctr + 1;

        if (reset) begin
            ctr <= 0;
            state <= start;
        end else begin
            case(state)
                idle : begin
                    // Don't do anything here
                end

                start : begin
                    if (ctr == 0) begin
                        $write("%c[1;34m",27);
                        $display ("***********************************************");
                        $display ("%s - Test Begin", PREFIX);
                        $display ("***********************************************");
                        $write("%c[0m",27);
                        $display();
                    end else begin
                        ctr <= 0;
                        state <= check_status;
                    end // else: !if(ctr == 0)
                end // case: start

                check_status : begin
                    if ((!reset) && (pass || fail)) begin
                        if (fail == 1'b1)
                            state <= test_fail;
                        else if (pass == 1'b1)
                            state <= test_pass;

                        ctr <= 0;
                    end
                end

                test_fail : begin
                    if (ctr == 0) begin
                        $display();
                        $write("%c[1;31m",27);
                        $display ("***********************************************");
                        $display ("%s - Test Failed", PREFIX);
                        $display ("***********************************************");
                        $write("%c[0m",27);
                        $display();
                        //$fatal;

                    end else begin
                        ctr <= 0;
                        state <= finish;
                    end // else: !if(ctr == 0)
                end // case: test_fail

                test_pass : begin
                    if (ctr == 0) begin
                        $display();
                        $write("%c[1;32m",27);
                        $display ("***********************************************");
                        $display ("%s - Test Passed", PREFIX);
                        $display ("***********************************************");
                        $write("%c[0m",27);
                        $display();
                        //$finish;

                    end else begin // if (ctr == 0)
                        ctr <= 0;
                        state <= finish;
                    end // else: !if(ctr == 0)
                end // case: test_pass

                finish : begin
                    if (ctr == 0) begin
                        $display();
                        $display ("***********************************************");
                        $display ("%s - Test Finished", PREFIX);
                        $display ("***********************************************");
                        $display();
                        //$finish;
                        
                    end else begin
                        ctr <= 0;
                        state <= idle;
                    end
                end

                default : begin
                    state <= idle;
                end

            endcase // case (state)
        end // else: !if(reset)
    end // always @ (posedge clk)




//initial
//    check_status;
//
////-------------------------------------------------------------------
//task automatic start;
//    begin
//        $display();
//        $write("%c[1;34m",27);
//        $display ("***********************************************");
//        $display (PREFIX, " - Test Begin");
//        $display ("***********************************************");
//        $write("%c[0m",27);
//        $display();
//    end
//endtask
////-------------------------------------------------------------------
//
////-------------------------------------------------------------------
//task automatic test_fail;
//    begin
//        $display();
//        $write("%c[1;31m",27);
//        $display ("***********************************************");
//        $display (PREFIX, " - Test Failed");
//        $display ("***********************************************");
//        $write("%c[0m",27);
//        $display();
//        $fatal;
//    end
//endtask
////-------------------------------------------------------------------
//
////-------------------------------------------------------------------
//task automatic test_pass;
//    begin
//        $display();
//        $write("%c[1;32m",27);
//        $display ("***********************************************");
//        $display (PREFIX, " - Test Passed");
//        $display ("***********************************************");
//        $write("%c[0m",27);
//        $display();
//        $finish;
//    end
//endtask
////-------------------------------------------------------------------
//
////-------------------------------------------------------------------
//task automatic check_status;
//    begin
//        wait ((!reset) && (pass || fail));
//        if (fail === 1'b1)
//        begin
//            test_fail;
//        end
//        else if (pass === 1'b1)
//            test_pass;
//        begin
//        end
//    end
//endtask
////-------------------------------------------------------------------
//
////-------------------------------------------------------------------
//task automatic finish;
//    begin
//        $display();
//        $display ("***********************************************");
//        $display (PREFIX, " - Test Finished");
//        $display ("***********************************************");
//        $display();
//        $finish;
//    end
//endtask
////-------------------------------------------------------------------

endmodule

reg p;
reg f;
reg rst;

initial rst = 0;

test_status t(clock.val, rst, f, p);
