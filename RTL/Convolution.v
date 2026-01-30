`timescale 1ns / 1ps

module Convolution (
    input clk,
    input rst,
    input conv_enable,
    input pe_enable,
    input [6:0] pixels,
    input [2:0] patch_size,
    input [48:0] rule,
    input [48:0] neg_rule,
    input Xmatch,
    input Ymatch,
    output reg clause_op
);
reg [6:0] shift_reg,shift_reg2;
reg [6:0] conv_unit[0:6];
reg [6:0] out_3, out_5, out_7;
reg [6:0] neg_out_3, neg_out_5, neg_out_7;
reg row_3, row_5, row_7;
reg neg_row_3, neg_row_5, neg_row_7;
reg out [0:48];
reg neg_out [0:48];
reg conv_en_seen;
integer i,j;
wire x_match_d2,x_match_d4,x_match_d6,y_match_d2,y_match_d4,y_match_d6;
/* ============================================================
   PIPELINED CONVOLUTION CORE
   Fixes conv_unit timing violation
   ============================================================ */
/* -----------------------
   Stage 1 : Shift window
----------------------- */
always @(posedge clk) begin
    if (rst) begin
        for (i=0;i<7;i=i+1)
            for (j=0;j<7;j=j+1)
                conv_unit[i][j] <= 0;
    end
    else if (pe_enable) begin
        for (i=0;i<7;i=i+1) begin
            conv_unit[i][0] <= (i < patch_size) ? pixels[i] : 1'b0;
            for (j=1;j<7;j=j+1)
                conv_unit[i][j] <= (j < patch_size) ? conv_unit[i][j-1] : 1'b0;
        end
    end
end


/*************************
 Stage 2 : rule compare
*************************/
reg out_r     [0:48];
reg neg_out_r [0:48];

always @(posedge clk) begin
    if (rst) begin
        for(i=0;i<49;i=i+1) begin
            out_r[i]     <= 0;
            neg_out_r[i] <= 0;
        end
    end
    else begin
        for (i=0;i<49;i=i+1) begin
            out_r[i]     <= conv_unit[i/7][6-(i%7)] | (~rule[i]);
            neg_out_r[i] <= (~conv_unit[i/7][6-(i%7)]) | (~neg_rule[i]);
        end
    end
end


/*************************
 Stage 3 : row reduce
*************************/
reg [6:0] out3_r,out5_r,out7_r;
reg [6:0] neg3_r,neg5_r,neg7_r;

always @(posedge clk) begin
    if (rst) begin
        out3_r<=0; out5_r<=0; out7_r<=0;
        neg3_r<=0; neg5_r<=0; neg7_r<=0;
    end
    else begin
        for(i=0;i<7;i=i+1) begin
            out3_r[i] <= (patch_size>=3) ?
                (out_r[i*7+0] & out_r[i*7+1] & out_r[i*7+2]) : 0;

            out5_r[i] <= (patch_size>=5) ?
                (out3_r[i] & out_r[i*7+3] & out_r[i*7+4]) : 0;

            out7_r[i] <= (patch_size==7) ?
                (out5_r[i] & out_r[i*7+5] & out_r[i*7+6]) : 0;

            neg3_r[i] <= (patch_size>=3) ?
                (neg_out_r[i*7+0] & neg_out_r[i*7+1] & neg_out_r[i*7+2]) : 0;

            neg5_r[i] <= (patch_size>=5) ?
                (neg3_r[i] & neg_out_r[i*7+3] & neg_out_r[i*7+4]) : 0;

            neg7_r[i] <= (patch_size==7) ?
                (neg5_r[i] & neg_out_r[i*7+5] & neg_out_r[i*7+6]) : 0;
        end
    end
end


/*************************
 Stage 4 : final reduce
*************************/
reg row3_r,row5_r,row7_r;
reg negrow3_r,negrow5_r,negrow7_r;

always @(posedge clk) begin
    row3_r    <= &out3_r[1:0];
    row5_r    <= &out5_r[3:0];
    row7_r    <= &out7_r[5:0];

    negrow3_r <= &neg3_r[1:0];
    negrow5_r <= &neg5_r[3:0];
    negrow7_r <= &neg7_r[5:0];
end
always @(posedge clk) begin
            shift_reg <= {shift_reg[5:0], Xmatch};
            shift_reg2 <= {shift_reg2[5:0], Ymatch};
    end

    assign x_match_d2 = shift_reg[1];
    assign x_match_d4 = shift_reg[3];
    assign x_match_d6 = shift_reg[5];
    assign y_match_d2 = shift_reg2[1];
    assign y_match_d4 = shift_reg2[3];
    assign y_match_d6 = shift_reg2[5];

/*************************
 Stage 5 : clause output
*************************/
always @(posedge clk) begin
    if (rst)
        clause_op <= 0;
    else if (pe_enable && conv_enable) begin
        case(patch_size)
            3: clause_op <= x_match_d2 & y_match_d2 & row3_r & negrow3_r;
            5: clause_op <= x_match_d4 & y_match_d4 & row5_r & negrow5_r;
            7: clause_op <= x_match_d6 & y_match_d6 & row7_r & negrow7_r;
            default: clause_op <= 0;
        endcase
    end
    else
        clause_op <= 0;
end

/* ============================================================ */


endmodule
