`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:  J. Callenes
// 
// Create Date: 01/04/2019 04:32:12 PM
// Design Name: 
// Module Name: PIPELINED_OTTER_CPU
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

  typedef enum logic [6:0] {
           LUI      = 7'b0110111,
           AUIPC    = 7'b0010111,
           JAL      = 7'b1101111,
           JALR     = 7'b1100111,
           BRANCH   = 7'b1100011,
           LOAD     = 7'b0000011,
           STORE    = 7'b0100011,
           OP_IMM   = 7'b0010011,
           OP       = 7'b0110011,
           SYSTEM   = 7'b1110011
 } opcode_t;
        
//typedef struct packed{
//    opcode_t opcode;
//    logic [4:0] rs1_addr;
//    logic [4:0] rs2_addr;
//    logic [4:0] rd_addr;
//    logic rs1_used;
//    logic rs2_used;
//    logic rd_used;
//    logic [3:0] alu_fun;
//    logic memWrite;
//    logic memRead2;
//    logic regWrite;
//    logic [1:0] rf_wr_sel;
//    logic [2:0] mem_type;  //sign, size
//    logic [31:0] pc;
//} instr_t;

module OTTER_MCU(input CLK,
                input INTR,
                input RESET,
                input [31:0] IOBUS_IN,
                output [31:0] IOBUS_OUT,
                output [31:0] IOBUS_ADDR,
                output logic IOBUS_WR 
);           
//    wire [6:0] opcode;
//    wire [31:0] pc, pc_value, next_pc, jalr_pc, branch_pc, jump_pc, int_pc,A,B,
//        I_immed,S_immed,U_immed,aluBin,aluAin,aluResult,rfIn,csr_reg, mem_data;
    
//    wire [31:0] IR;
//    wire memRead1,memRead2;
    
//    wire pcWrite,regWrite,memWrite, op1_sel,mem_op,IorD,pcWriteCond,memRead;
//    wire [1:0] opB_sel, rf_sel, wb_sel, mSize;
//    logic [1:0] pc_sel;
//    wire [3:0]alu_fun;
//    wire opA_sel;
    
//    logic br_lt,br_eq,br_ltu;
    
//    assign next_pc = pc + 4;


//==== Instruction Fetch ===========================================

//---- if signals ----

    logic [31:0] next_pc, jalr, branch, jal, pc_in, if_pc, dout1, ir;      
    logic [1:0] pcSource;
    logic pcWrite, memRead1;
    
    assign next_pc = if_pc + 4;
    
//---- instantiate PC ----
    Mult4to1 pc_mux (
        .In1(next_pc), 
        .In2(jalr), 
        .In3(branch), 
        .In4(jal), 
        .Sel(pcSource), 
        .Out(pc_in));
        
    ProgCount PC (
        .PC_CLK (CLK), 
        .PC_RST (RESET), 
        .PC_LD (pcWrite), 
        .PC_DIN (pc_in), 
        .PC_COUNT (if_pc));

//---- instantiate memory ----
    OTTER_mem_byte memory (
        .MEM_CLK(CLK),
        .MEM_ADDR1 (if_pc),
        .MEM_ADDR2 (mem_aluResult),
        .MEM_DIN2 (mem_rs2),
        .MEM_WRITE2 (mem_memWrite),
        .MEM_READ1 (memRead1),
        .MEM_READ2 (mem_memRead2),
        .ERR (),
        .MEM_DOUT1 (dout1),
        .MEM_DOUT2 (wb_dout2),
        .IO_IN (IOBUS_IN),
        .IO_WR (IOBUS_WR),
        .MEM_SIZE (mem_size),
        .MEM_SIGN (mem_sign)
    );
                
//---- if_de register ----
    logic [31:0] de_pc;
     
    always_ff @(posedge CLK) begin
        if(!stall)
            de_pc <= if_pc;
    end



//==== Instruction Decode ===========================================

//---- de signals ----

    logic [31:0] de_rs1, de_rs2, 
    utype, de_itype, stype, de_jtype, de_btype, de_opA, de_opB;
    logic [6:0] de_opcode, de_func7;
    logic [4:0] de_rs1_addr, de_rs2_addr, de_wa;
    logic [2:0] de_func3;
    logic [3:0] de_alu_fun;
    logic [1:0] alu_srcB, de_size, de_rf_wr_sel;
    logic de_regWrite, de_memWrite, de_memRead2, alu_srcA, 
    de_rs1_used, de_rs2_used, de_sign, ir_sel;
    
    assign de_rs1_addr = ir[19:15];
    assign de_rs2_addr = ir[24:20];
    assign de_wa = ir[11:7];
    
    assign de_func3 = ir[14:12];
    assign de_func7 = ir[31:25];
    
    assign de_size = ir[13:12];
    assign de_sign = ir[14];
    
    assign de_opcode = ir[6:0];
    opcode_t de_OPCODE;
    assign de_OPCODE = opcode_t'(de_opcode);
  
    assign de_rs1_used =    de_rs1_addr != 0
                                && de_OPCODE != LUI
                                && de_OPCODE != AUIPC
                                && de_OPCODE != JAL;
                                
    assign de_rs2_used =   de_rs2_addr != 0
                                && (de_OPCODE == BRANCH 
                                || de_OPCODE== OP);
                            
                                      
        
//---- instantiate DCDR ----

    OTTER_CU_Decoder dcdr(
        .CU_OPCODE (de_opcode),
        .CU_FUNC3 (de_func3),
        .CU_FUNC7 (de_func7),
        .CU_ALU_SRCA (alu_srcA),
        .CU_ALU_SRCB (alu_srcB),
        .CU_ALU_FUN (de_alu_fun),
        .CU_RF_WR_SEL (de_rf_wr_sel),
        .CU_REGWRITE (de_regWrite),
        .CU_MEMWRITE (de_memWrite),
        .CU_MEMREAD2 (de_memRead2)); 
    
//---- instantiate reg file ----
    OTTER_registerFile regFile(
        .Read1 (de_rs1_addr),
        .Read2 (de_rs2_addr),
        .WriteReg (wb_wa),
        .WriteData (wd),
        .RegWrite (wb_regWrite),
        .Data1 (de_rs1),
        .Data2 (de_rs2),
        .clock (CLK));
        
//---- immediate generator

    assign stype = {{20{ir[31]}},ir[31:25],ir[11:7]};
    assign de_itype = {{20{ir[31]}},ir[31:20]};
    assign utype = {ir[31:12],{12{1'b0}}};
    assign de_btype = {{20{ir[31]}},ir[7],ir[30:25],ir[11:8],1'b0};   
    assign de_jtype = {{12{ir[31]}}, ir[19:12], ir[20],ir[30:21],1'b0};

//---- create muxes ----
    
    Mult2to1 opA_mux (
        .In1 (de_rs1),
        .In2 (utype),
        .Sel (alu_srcA),
        .Out (de_opA));
        
    Mult4to1 opB_mux (
        .In1 (de_rs2),
        .In2 (de_itype),
        .In3 (stype),
        .In4 (de_pc),
        .Sel (alu_srcB),
        .Out (de_opB));
        
        
        
        
//---- load stall unit ----
    logic stall;

    always_comb
        if ((ex_memRead2) && (ex_wa == de_rs1_addr || ex_wa == de_rs2_addr) && (de_rs1_used || de_rs2_used))
            begin
                pcWrite = 0;
                memRead1 = 0;
                stall = 1;
            end
        else
            begin
                pcWrite = 1;
                memRead1 = 1;
                stall = 0;
            end
            
            
//---- Squashing unit ---- 
    logic ex_branch_taken, mem_branch_taken;
 
    assign ir_sel = ex_branch_taken || mem_branch_taken;

    Mult2to1 ir_mux (
        .In1 (dout1),
        .In2 (32'b0),
        .Sel (ir_sel),
        .Out (ir)
        );
    
//---- de_ex register

    always_ff @(posedge CLK) begin
        if (!stall) begin   
            ex_pc <= de_pc;
            ex_rs1 <= de_rs1;
            ex_rs2 <= de_rs2;
            ex_rs1_addr <= de_rs1_addr;
            ex_rs2_addr <= de_rs2_addr; 
            ex_wa <= de_wa;
            ex_jtype <= de_jtype;
            ex_btype <= de_btype;
            ex_itype <= de_itype;
            ex_opA <= de_opA;
            ex_opB <= de_opB;
            ex_opcode <= de_opcode;
            ex_func7 <= de_func7;
            ex_func3 <= de_func3;
            ex_size <= de_size;
            ex_regWrite <= de_regWrite;
            ex_memWrite <= de_memWrite;
            ex_memRead2 <= de_memRead2;
            ex_alu_fun <= de_alu_fun;
            ex_rf_wr_sel <= de_rf_wr_sel;
            ex_sign <= de_sign;
            ex_rs1_used <= de_rs1_used;
            ex_rs2_used <= de_rs2_used;
        end
        else
            begin
            ex_pc <= 0;
            ex_rs1 <= 0;
            ex_rs2 <= 0;
            ex_rs1_addr <= 0;
            ex_rs2_addr <= 0; 
            ex_wa <= 0;
            ex_jtype <= 0;
            ex_btype <= 0;
            ex_itype <= 0;
            ex_opA <= 0;
            ex_opB <= 0;
            ex_opcode <= 0;
            ex_func7 <= 0;
            ex_func3 <= 0;
            ex_size <= 0;
            ex_regWrite <= 0;
            ex_memWrite <= 0;
            ex_memRead2 <= 0;
            ex_alu_fun <= 0;
            ex_rf_wr_sel <= 0;
            ex_sign <= 0;
            ex_rs1_used <= 0;
            ex_rs2_used <= 0; 
            end
	end
	
//==== Execute ======================================================


//---- ex signals ----
    logic [31:0] ex_pc, ex_rs1, ex_rs2, ex_jtype, ex_btype, ex_itype, ex_opA, ex_opB,
         fw_opA, fw_opB, fw_rs2;
    logic [6:0] ex_opcode, ex_func7;
    logic [4:0] ex_wa,ex_rs1_addr, ex_rs2_addr;
    logic [3:0] ex_alu_fun;
    logic [2:0] ex_func3; 
    logic [1:0] ex_size, ex_rf_wr_sel, fw_srcA, fw_srcB, fw_rs2_sel;
    logic ex_regWrite, ex_memWrite, ex_memRead2, ex_sign, ex_rs1_used, ex_rs2_used;
    logic [31:0] ex_aluResult;
     
     
//---- branch cond gen----
    
    opcode_t ex_OPCODE;
    assign ex_OPCODE = opcode_t'(ex_opcode);
    logic br_lt, br_eq, br_ltu;
    logic brn_cond;
    
    always_comb
    begin
        br_lt = 0; br_eq = 0; br_ltu = 0;
        if($signed(fw_opA) < $signed(ex_rs2)) br_lt = 1;
        if(fw_opA == fw_opB) br_eq = 1;
        if(fw_opA < fw_opB) br_ltu = 1;
    end
    
    always_comb
    begin
        case(ex_func3)
            3'b000: brn_cond = br_eq;     //BEQ 
            3'b001: brn_cond = ~br_eq;    //BNE
            3'b100: brn_cond = br_lt;     //BLT
            3'b101: brn_cond = ~br_lt;    //BGE
            3'b110: brn_cond = br_ltu;    //BLTU
            3'b111: brn_cond = ~br_ltu;   //BGEU
            default: brn_cond =0;
        endcase
    end
    
    always_comb begin
        case(ex_OPCODE)
            JAL: pcSource = 2'b11;
            JALR: pcSource = 2'b01;
            BRANCH: pcSource = (brn_cond)?2'b10:2'b00;
            default: pcSource = 2'b00; 
        endcase  
    end
    
    assign ex_branch_taken = pcSource != 2'b0;
    
//---- target gen ----
    assign jalr = fw_opA + ex_itype;
    assign branch = ex_pc + ex_btype;
    assign jal = ex_pc + ex_jtype;
        
     
//---- instantiate alu ----
    OTTER_ALU ALU (
    .ALU_fun(ex_alu_fun), 
    .A(fw_opA),
    .B(fw_opB), 
    .ALUOut(ex_aluResult));
    
    
    
//---- Forwarding unit ----
    Mult4to1 fw_a_mux (
        .In1(ex_opA),
        .In2(mem_aluResult),
        .In3(wd),
        .In4(),
        .Sel(fw_srcA),
        .Out(fw_opA)
    );
    
    Mult4to1 fw_b_mux (
        .In1(ex_opB),
        .In2(mem_aluResult),
        .In3(wd),
        .In4(),
        .Sel(fw_srcB),
        .Out(fw_opB)
    );
    
    Mult4to1 fw_rs2_mux (
        .In1(ex_rs2),
        .In2(mem_aluResult),
        .In3(wd),
        .In4(),
        .Sel(fw_rs2_sel),
        .Out(fw_rs2)
    );
    
    
    //forwarding logic 
    always_comb
    begin
        //fw_opA logic
        if ((mem_regWrite) && (mem_wa != 5'b0) && (ex_rs1_addr == mem_wa) && (ex_rs1_used))
            fw_srcA = 2'b01;
        else if ((wb_regWrite) && (wb_wa != 5'b0) && (ex_rs1_addr == wb_wa) && (ex_rs1_used))
            fw_srcA = 2'b10;
        else
            fw_srcA = 2'b00;
            
            
        //fw_opB logic
        if ((mem_regWrite) && (mem_wa != 5'b0) && (ex_rs2_addr == mem_wa) && (ex_rs2_used))
            fw_srcB = 2'b01;
        else if ((wb_regWrite) && (wb_wa != 5'b0) && (ex_rs2_addr == wb_wa) && (ex_rs2_used))
            fw_srcB = 2'b10;
        else
            fw_srcB = 2'b00;
            
        //fw_rs2 logic
        if ((mem_regWrite) && (mem_wa != 5'b0) && (ex_rs2_addr == mem_wa))
            fw_rs2_sel = 2'b01;
        else if ((wb_regWrite) && (wb_wa != 5'b0) && (ex_rs2_addr == wb_wa))
            fw_rs2_sel = 2'b10;
        else
            fw_rs2_sel = 2'b00;      

    end 
//---- ex_mem pipeline register ----

    always_ff @(posedge CLK) begin
        mem_pc <= ex_pc;
        mem_rs1 <= ex_rs1;
        mem_rs2 <= fw_rs2;
        mem_wa <= ex_wa;
        mem_size <= ex_size;
        mem_regWrite <= ex_regWrite;
        mem_memWrite <= ex_memWrite;
        mem_memRead2 <= ex_memRead2;
        mem_rf_wr_sel <= ex_rf_wr_sel;
        mem_sign <= ex_sign;
        mem_aluResult <= ex_aluResult;
        mem_branch_taken <= ex_branch_taken;
	end

//==== Memory ======================================================

//---- mem signals ---- 
    logic [31:0] mem_pc, mem_rs1, mem_rs2, mem_aluResult;
    logic [1:0] mem_size;
    logic [4:0] mem_wa;
    logic [1:0] mem_rf_wr_sel;
    logic mem_sign, mem_regWrite, mem_memWrite, mem_memRead2;  
     
    assign IOBUS_ADDR = mem_aluResult;
    assign IOBUS_OUT = mem_rs2;
    
    

    
//---- mem_wb pipeline register ----    
    
     always_ff @(posedge CLK) begin
        wb_pc <= mem_pc;
        wb_wa <= mem_wa;
        wb_regWrite <= mem_regWrite;
        wb_rf_wr_sel <= mem_rf_wr_sel;
        wb_aluResult <= mem_aluResult;
	end
 
 
     
//==== Write Back ==================================================

//---- wb signals ----

logic [31:0] wb_pc, wd, wb_aluResult, wb_dout2;
logic [4:0] wb_wa;
logic [1:0] wb_rf_wr_sel;
logic wb_regWrite;     

//---- reg file mux ----

    Mult4to1 reg_file_mux (
    .In1 (wb_pc + 4),
    .In2 (0),
    .In3 (wb_dout2),
    .In4 (wb_aluResult),
    .Sel (wb_rf_wr_sel),
    .Out (wd)); 
 

       
            
endmodule
