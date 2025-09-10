module SIMD_tb;

// ---------------------------------------------------------------------
// Parameters & Variables
// ---------------------------------------------------------------------
localparam CLK_PERIOD = 20.0;

reg clk, rst;
reg [17:0] INST_MEM[1023:0];
reg [7:0] DATA_MEM[1023:0];
wire done;
reg [17:0] inst_in;
reg [7:0] data_in;
wire [9:0] data_out;
wire [9:0] inst_adds;
wire [9:0] data_adds;
wire data_R;
wire data_W;

// ---------------------------------------------------------------------
// UUT (Unit Under Test) Instantiation
// ---------------------------------------------------------------------
CPUtop uut (
    .clk (clk),
    .rst (rst),
    .inst_in (inst_in),
    .data_in (data_in), 
    .data_out (data_out),
    .inst_adds (inst_adds),
    .data_adds (data_adds),
    .data_R (data_R),
    .data_W (data_W),
    .done (done)
);

// ---------------------------------------------------------------------
// SDF Annotation (if a timing file is available)
// ---------------------------------------------------------------------
initial begin
    $sdf_annotate("CPU.Mapped.sdf", uut);
end

// ---------------------------------------------------------------------
// Clock Generation
// ---------------------------------------------------------------------
initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD/2.0) clk = ~clk;
end

// ---------------------------------------------------------------------
// Memory & Reset Initialization
// ---------------------------------------------------------------------
initial begin
    // Load program into instruction memory from an external file
    // The 'test_program.mem' file contains the instructions
    $readmemb("test_program.mem", INST_MEM);
    $display("INFO: Loaded instructions from test_program.mem");

    // Initialize data memory
    $readmemh("test_data.mem", DATA_MEM);
    $display("INFO: Loaded initial data from test_data.mem");
    
    // Asynchronous reset sequence
    rst = 1'b1;
    # (CLK_PERIOD / 4.0); // Small delay to ensure reset is captured
    @(posedge clk);
    rst = 1'b0;
    $display("INFO: CPU reset complete.");
end

// ---------------------------------------------------------------------
// Memory Interface Logic (Read/Write)
// ---------------------------------------------------------------------
// Note: This logic models the interaction with external memories
always @(negedge clk) begin
    // Handle data memory access
    if (data_R) begin
        if (data_W) begin
            DATA_MEM[data_adds] <= data_out;
            $display("TIME: %0t -- DATA_MEM[%d] <= %h (data_out)", $time, data_adds, data_out);
        end else begin
            data_in <= DATA_MEM[data_adds];
            $display("TIME: %0t -- data_in <= DATA_MEM[%d] (%h)", $time, data_adds, DATA_MEM[data_adds]);
        end
    end
    
    // Handle instruction memory access
    inst_in <= INST_MEM[inst_adds];
    $display("TIME: %0t -- inst_in <= INST_MEM[%d] (%b)", $time, inst_adds, INST_MEM[inst_adds]);
end

// ---------------------------------------------------------------------
// Simulation Control & Self-Checking
// ---------------------------------------------------------------------
initial begin
    // Wait for the CPU to signal completion
    @(posedge done);
    
    $display("\n=======================================================");
    $display("SIMULATION FINISHED: CPU 'done' signal asserted.");
    
    // Self-checking mechanism
    // Compare the final state of DATA_MEM with a golden reference file
    $display("INFO: Comparing final data memory state with 'golden_data.mem'");
    
    // A temporary memory to hold the golden data
    reg [7:0] golden_DATA_MEM[1023:0];
    integer i;
    reg failed = 1'b0;

    // Load the golden reference data
    $readmemh("golden_data.mem", golden_DATA_MEM);

    // Compare memories word by word
    for (i = 0; i < 1024; i = i + 1) begin
        if (DATA_MEM[i] !== golden_DATA_MEM[i]) begin
            $display("ERROR: Mismatch at address %d. Expected %h, but got %h",
                i, golden_DATA_MEM[i], DATA_MEM[i]);
            failed = 1'b1;
        end
    end

    if (failed) begin
        $display("=======================================================");
        $display("TEST FAILED! Refer to the log for mismatches.");
        $display("=======================================================\n");
    end else begin
        $display("=======================================================");
        $display("TEST PASSED! Final data memory state matches the golden reference.");
        $display("=======================================================\n");
    end
    
    // Stop the simulation
    $finish;
end

endmodule
