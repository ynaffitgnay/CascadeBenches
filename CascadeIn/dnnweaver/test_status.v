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


    // THIS LEADS TO INCORRECT BEHAVIOR!!!!
    //always @(*) begin
    //    if (reset) begin
    //        $write("%c[1;34m",27);
    //        $display ("***********************************************");
    //        $display ("%s - Test Begin", PREFIX);
    //        $display ("***********************************************");
    //        $write("%c[0m",27);
    //        $display();
    //    end else if (!pass && fail) begin
    //        $display();
    //        $write("%c[1;31m",27);
    //        $display ("***********************************************");
    //        $display ("%s - Test Failed", PREFIX);
    //        $display ("***********************************************");
    //        $write("%c[0m",27);
    //        $display();
    //    end else if (pass && !fail) begin
    //        $display();
    //        $write("%c[1;32m",27);
    //        $display ("***********************************************");
    //        $display ("%s - Test Passed", PREFIX);
    //        $display ("***********************************************");
    //        $write("%c[0m",27);
    //        $display();
    //    end else if (pass && fail) begin
    //        $display();
    //        $display ("***********************************************");
    //        $display ("%s - Test Finished", PREFIX);
    //        $display ("***********************************************");
    //        $display();
    //    end            
    //end // always @ (*)

    always @(reset) begin
        if (rst) begin
            $write("%c[1;34m",27);
            $display ("***********************************************");
            $display ("%s - Test Begin", PREFIX);
            $display ("***********************************************");
            $write("%c[0m",27);
            $display();
        end
    end

    always @(pass) begin
        if (pass && !fail) begin
            $display();
            $write("%c[1;32m",27);
            $display ("***********************************************");
            $display ("%s - Test Passed", PREFIX);
            $display ("***********************************************");
            $write("%c[0m",27);
            $display();
        end else if (pass && fail) begin
            $display();
            $display ("***********************************************");
            $display ("%s - Test Finished", PREFIX);
            $display ("***********************************************");
            $display();
        end
    end

    always @(fail) begin
        if (!pass && fail) begin
            $display();
            $write("%c[1;31m",27);
            $display ("***********************************************");
            $display ("%s - Test Failed", PREFIX);
            $display ("***********************************************");
            $write("%c[0m",27);
            $display();
        end else if (pass && fail) begin
            $display();
            $display ("***********************************************");
            $display ("%s - Test Finished", PREFIX);
            $display ("***********************************************");
            $display();
        end            
    end
endmodule

//reg p;
//reg f;
//reg rst;
//
//initial rst = 0;
//
//test_status t(clock.val, rst, f, p);
//
//
//// Start tests
//initial rst = 1;
//initial rst = 0;
//
//
//initial p = 1; // get a pass here
//
//// Start a new test
//initial rst = 1;
//
//initial rst = 0;
//
//// pass a test
//initial begin  // nothing happens here bc pass and fail haven't actually changed...
//  p = 1;
//  f = 0;
//end
//
//// fail a test
//initial begin
//  p = 0;
//  f = 1;
//end
//
//// finish
//initial begin
//  p = 1;
//  f = 1;
//end
