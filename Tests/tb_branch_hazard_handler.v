`timescale 1ns / 1ps

module tb_branch_hazard_handler();

    reg        take_branch;
    reg [31:0] branch_target;
    wire       pc_src;
    wire       flush_IF;
    wire       flush_ID;

    branch_hazard_handler uut (
        .take_branch(take_branch),
        .branch_target(branch_target),
        .pc_src(pc_src),
        .flush_IF(flush_IF),
        .flush_ID(flush_ID)
    );

    initial begin
        // Test 1: Branch not taken
        take_branch = 0;
        branch_target = 32'h00001000;
        #10;
        if (pc_src === 0 && flush_IF === 0 && flush_ID === 0)
            $display("PASS: Test 1 (Not taken) pc_src=0, flush_IF=0, flush_ID=0");
        else
            $display("FAIL: Test 1 (Not taken)");

        // Test 2: Branch taken
        take_branch = 1;
        #10;
        if (pc_src === 1 && flush_IF === 1 && flush_ID === 1)
            $display("PASS: Test 2 (Taken) pc_src=1, flush_IF=1, flush_ID=1");
        else
            $display("FAIL: Test 2 (Taken)");

        $display("Branch Hazard Handler Test completed.");
        $finish;
    end

endmodule
