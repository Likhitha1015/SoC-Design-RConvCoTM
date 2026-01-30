`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.06.2025 20:46:55
// Design Name: 
// Module Name: addr_gen
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

module addr_gen#(
parameter  WIDTH = 32,
parameter  HEIGHT = 32			
)(
    input clk,
    input rst,
    input [5:0] cycle_counts,
    input [2:0] stride,
    input [2:0] patch_size,
    input [2:0] k,
    input done_rmu,
    input [$clog2(WIDTH):0] xcor1,
    input en,
    output reg clause_active,
    (* keep = "true" *)output reg [HEIGHT - 1:0] y1,
    (* keep = "true" *)output reg [WIDTH - 1:0] x1,
    output reg done
);

integer i;
reg [8:0] ycor1,xcor1d;// xcor delay to match with pe_en
reg [5:0] cycle_count;
/* ============================================================
   PIPELINED Y-ADDRESS GENERATOR
   Fixes ycor1 timing violation
   ============================================================ */


// Stage 1 register
reg [8:0] ycalc;



// ---------------------------
// Stage 1 : arithmetic only
// ---------------------------
always @(posedge clk) begin
    if (rst) begin
        ycalc <= 0;
    end
    else if (en) begin

        if (patch_size == 3 && (stride == 1 || stride == 2)) begin
            if(cycle_count == 0)
                ycalc <= stride * k;
            else if((k > 5 && stride == 1) || (k == 3 && stride == 2))
                ycalc <= (cycle_count - 1) * 8 + stride * k;
            else
                ycalc <= cycle_count * 8 + stride * k;
        end

        else if (patch_size == 3 && stride == 3)
            ycalc <= k * 3 + (cycle_count / 3) * 24;

        else if (patch_size == 5 && (stride == 1 || stride == 2 || stride == 4)) begin
            if(cycle_count == 0)
                ycalc <= stride * k;
            else if((k > 3 && stride == 1) || (k > 1 && stride == 2) || (k == 1 && stride == 4))
                ycalc <= (cycle_count - 1) * 8 + stride * k;
            else
                ycalc <= cycle_count * 8 + stride * k;
        end

        else if (patch_size == 5 && stride == 3)
            ycalc <= k * 3 + ((((cycle_count - 1) * (cycle_count > 1)) / 3) + ((k==0||k==1)&&cycle_count>0)) * 24;

        else if (patch_size == 5 && stride == 5)
            ycalc <= k * 5 + (cycle_count / 5) * 40;

        else if (patch_size == 7 && (stride == 1 || stride == 2 || stride == 4)) begin
            if(cycle_count == 0)
                ycalc <= stride * k;
            else if((k > 1 && stride == 1) || (k > 0 && stride == 2) || (k == 1 && stride == 4))
                ycalc <= (cycle_count - 1) * 8 + stride * k;
            else
                ycalc <= cycle_count * 8 + stride * k;
        end

        else if (patch_size == 7 && stride == 3)
            ycalc <= k * 3 + ((((cycle_count - 1) * (cycle_count > 1)) / 3) + ((k==0)&&cycle_count>0)) * 24;

        else if (patch_size == 7 && stride == 5)
            ycalc <= k * 5 + ((((cycle_count - 1) * (cycle_count > 1)) / 5) + ((k==0)&&cycle_count>0)) * 40;

        else if (stride == 6)
            ycalc <= k * 6 + ((((cycle_count - 1) * (cycle_count > 1)) / 3) + ((k==0)&&cycle_count>0)) * 24;

        else if (stride == 7)
            ycalc <= k * 7 + (cycle_count / 7) * 56;

        else
            ycalc <= 0;
    end
end


// ---------------------------
// Stage 2 : register output
// ---------------------------
always @(posedge clk) begin
    if (rst)
        ycor1 <= 0;
    else
        ycor1 <= ycalc;
end


// ---------------------------
// Stage 3 : one-hot vector
// ---------------------------
always @(posedge clk) begin
    if (rst) begin
        y1 <= 0;
    end
    else begin
        for (i=0;i<HEIGHT;i=i+1)
            y1[i] <= (i < ycor1);
    end
end

/* ============================================================ */

    always @(posedge clk) begin
    xcor1d <= xcor1;// xcor delay to match with pe_en
    if(rst)clause_active <= 0;
    else if(en) clause_active <= 1'b1;     
    end
    always @(*) begin
    
    if (xcor1d != 0) begin
        for (i = 0; i < WIDTH; i = i + 1) begin
            if (i < xcor1)
//           for (i = WIDTH - 1; i >= 0; i = i - 1) begin
//           if  (i >= WIDTH - xcor1 + 1)
                x1[i] = 1'b1;
            else
                x1[i] = 1'b0;
        end
    end else begin
        x1 = 0;
    end
    cycle_count = cycle_counts - 1;
    if(y1[HEIGHT - patch_size - 1] && x1[WIDTH - 1])done = 1'b1;
//    if(y1[patch_size] && x1[2]) done = 1'b1;
    else done = 1'b0; 
end
    
endmodule
