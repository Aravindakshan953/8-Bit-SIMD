module CPU(
    input clk,
    input rst,
    input [17:0] inst_in,
    input [7:0] data_in,
    input [7:0] data_out,
    input [9:0] data_adds,
    input [9:0] inst_adds,
    output data_R,
    output data_W,
    output done
    );                                 //Declaration of necessary Variables for the CPU Core
 parameter [2:0] STATE_IDL = 0;
 parameter [2:0] STATE_IF = 1;
 parameter [2:0] STATE_ID = 2;
 parameter [2:0] STATE_EX = 3;
 parameter [2:0] STATE_MEM = 4;
 parameter [2:0] STATE_WB = 5;
 parameter [2:0] STATE_HALT = 6;         // declaration of state Parameters
 
 reg [2:0] curr_state, next_state;
 reg [9:0] PC, next_PC;                            // storing the current and next state of the byte values in register
 
 wire [5:0] opcode = inst_in[17:12];
 wire [1:0] reg_dest = inst_in[11:10];
 wire [1:0] reg_src_A = inst_in[5:4];
 wire [1:0] reg_src_B = inst_in[3:2];
 wire [1:0] reg_src_C = inst_in[1:0];
 wire [9:0] im_val = inst_in[9:0];   //installing op_code, source and Destination Registers.
 
 reg [7:0] R [0:3];
 reg [9:0] LC;
 
 reg [5:0] ex_opcode;
 reg [1:0] ex_reg_dest;
 reg [7:0] ex_operand_A, ex_operand_B;
 reg [9:0] ex_im_val;      // register allocation for both the operand and Opcode
 
 reg [5:0] mem_opcode;
 reg [1:0] mem_reg_dest;
 reg [7:0] mem_alu_result;
 reg [9:0] mem_data_addr;              // memory allocation for opcode, destination Register and ALU are been stored in memory
 
 reg [5:0] mem_opcode;
 reg [1:0] mem_reg_dest;
 reg [7:0] mem_alu_result;
 reg [9:0] mem_data_addr;
 
 reg [5:0] wb_opcode;
 reg [1:0] wb_reg_dest;
 reg [7:0] wb_data_result;               
 
 reg rdata_en_reg, wdata_en_reg;
 reg [9:0] data_adds_reg;
 reg [7:0] data_out_reg;
 
 assign done = curr_state == STATE_HALT;
 assign inst_adds = PC;
 assign data_out = data_out_reg;
 assign data_R = rdata_en_reg;
 assign data_W = wdata_en_reg;
 assign data_adds = data_adds_reg;                 //assignment of the instruction address, Data_R, Data_W
  
 wire is_half_word = (ex_opcode[1:0] == 2'b01);
 wire is_octa_word = (ex_opcode[1:0] == 2'b10);     //Putting Half_word & Octa_word in Action
 
 wire is_add = (ex_opcode[5:2] == 4'b0000);
 wire is_sub = (ex_opcode[5:2] == 4'b0001);
 wire is_mul = (ex_opcode[5:2] == 4'b0011);
 wire is_mac = (ex_opcode[5:2] == 4'b0100);
 wire is_rshift = (ex_opcode[5:2] == 4'b0101);
 wire is_lshift = (ex_opcode[5:2] == 4'b0110);
 wire is_and = (ex_opcode[5:2] == 4'b0110);
 wire is_or = (ex_opcode[5:2] == 4'b0111);
 wire is_not = (ex_opcode[5:2] == 4'b1000);
 
 wire [7:0] alu_input_A = R[reg_src_A];
 wire [7:0] alu_input_B = R[reg_src_B];   //input A and B.

  
 wire [7:0] add_result, mul_result, shift_result;       //Add and Subtract the resultant Output
  
  SIMD_add Add_ALU(
        .A(alu_input_A),
        .B(alu_input_B),
        .H(is_half_word),
        .C(is_octa_word),
        .X(1'b0),
        .sub(is_sub),
        .sum(add_result)
     );                                                    // ALU ADD operation instance
  
  
  SIMD_x Mul_ALU(
  .multiplya(alu_input_A),
  .multiplyb(alu_input_B),
  .H(is_half_word),
  .X(is_octa_word),
  .C(1'b0),
  .multoutput(mul_result)
  );                                                       //ALU Multiply Operation instance
   

  SIMD_shift Shift(
    .shiftin(ex_operand_A),
    .left(is_lshift),
    .H(is_half_word), 
    .C(is_octa_word),
    .X(1'b0),
    .shiftout(shift_result)
    );                                                       // ALU Shifting operation instance
always @(posedge clk or posedge rst) begin
   if(rst) begin
      curr_state <= STATE_IDL;
      PC <= 0;
      LC <= 0;
   end
   else begin
       curr_state <= next_state;
       if(curr_state == STATE_WB)begin
            PC <= next_PC;
       end
   end
end                                                           // current_ state to Next_state possible either the positive Edged clk or rst Signal.

always @(*) begin
    next_state = curr_state;
    case (curr_state)
        STATE_IDL: begin
            if (rst == 0) next_state = STATE_IF;
        end
        STATE_IF: begin
            next_state = STATE_ID;
        end
        STATE_ID: begin
            next_state = STATE_EX;
        end
        STATE_MEM: begin
            next_state = STATE_MEM;
        end
        STATE_WB: begin
            if(opcode == 6'b111111) next_state = STATE_HALT;
            else next_state = STATE_IF;
        end
        STATE_HALT: begin
            next_state = STATE_HALT;
        end
    endcase 
 end                                                      //Switch Case Evaluation for SIMD ALU.
 
 always @(posedge clk) begin
    if (curr_state == STATE_ID) begin
        ex_opcode <= opcode;
        ex_reg_dest <= reg_dest;
        ex_im_val <= im_val;
        
        case (opcode)
            6'b100111, 6'b101010, 6'b101101: begin
                ex_operand_A <= R[reg_dest];
                ex_operand_B <= im_val[7:0];
            end
            
            default: begin
                ex_operand_A <= R[reg_src_A];
                ex_operand_B <= R[reg_src_B];               //asssigning different opcodes to the Source register
            end
        endcase
        
        $display("PC: %0d | Opcode: %b | Decoded: Dest =%d, SrcA=%d, SrcB=%d, Imm=%b", PC, opcode, reg_dest, reg_src_A, reg_src_B, im_val);
    end
 end   

always @ (posedge clk) begin
    if (curr_state == STATE_EX) begin
        mem_opcode <= ex_opcode;
        mem_reg_dest <= ex_reg_dest;
        mem_data_addr <= ex_im_val;
        
        case(ex_opcode[5:2])
            4'b0000: mem_alu_result <= add_result;
            4'b0001: mem_alu_result <= add_result;
            4'b0011: mem_alu_result <= mul_result;
            4'b0100: mem_alu_result <= mul_result + ex_operand_A;
            4'b0110: mem_alu_result <= shift_result;
            4'b0101: mem_alu_result <= shift_result;
            4'b0110: mem_alu_result <= ex_operand_A & ex_operand_B;
            4'b0111: mem_alu_result <= ex_operand_A | ex_operand_B;
            4'b1000: mem_alu_result <= ~ex_operand_A;
            4'b1011: mem_alu_result <= ex_im_val[7:0];
            4'b1001: mem_alu_result <= 8'h00;
            4'b1010: mem_alu_result <= ex_operand_A;
            default: mem_alu_result <= 8'h00;                       // Add, Multiply and Shift the result step by step.            
        endcase
        $display (" EX: opcode=%b, result=%b ", ex_opcode, mem_alu_result);
    end
 end
 
 always @(posedge clk) begin
    case (mem_opcode)
        6'b100111: begin
            rdata_en_reg <= 1;
            data_adds_reg <= mem_data_addr;
            wb_data_result <= data_in;
        end
        6'b101010: begin
            wdata_en_reg <= 1;
            data_adds_reg <= mem_data_addr;
            data_out_reg <= mem_alu_result;
            wb_data_result <= mem_alu_result;
        end
        default: begin
            rdata_en_reg <= 0;
            wdata_en_reg <= 0;
            wb_data_result <= mem_alu_result;       //Allocating the respective results in register
            end
        endcase
        $display (" MEM: mem_addr=%d ", mem_data_addr);
    end

 
 always @(posedge clk) begin
    if(curr_state == STATE_WB) begin
        case(wb_opcode)
            6'b100111: R[wb_reg_dest] <= data_in;
            6'b101010: begin
            end
            default: R[wb_reg_dest] <= wb_data_result;
        endcase
        next_PC <= PC + 1;
        if(wb_opcode == 6'b100100) begin
            if (LC != 0) begin
                next_PC <= im_val;
                LC <= LC - 1;
            end
        end
        if (wb_opcode == 6'b100101) begin
            LC <= im_val;                                    
        end
        
        $display (" WB: Write %h to R%d", wb_data_result, wb_reg_dest);
        $display("Registers: R0=%h, R1=%h, R2=%h, R3=%h", R[0], R[1], R[2], R[3]);
    end
