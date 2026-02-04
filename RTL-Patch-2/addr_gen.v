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
parameter  WIDTH = 28,
parameter  HEIGHT = 28			
)(
    input clk,
    input rst,
    input [5:0] cycle_counts,
    input [2:0] stride,
    input [2:0] patch_size,
    input [2:0] k,
    input en,
    output reg clause_active,
    output reg [HEIGHT - 1:0] y1,
    output reg done
);

integer i;
reg [8:0] ycor1;
reg [5:0] cycle_count;
reg [7:0] cc_m1;
reg [7:0] cc_x8, cc_m1_x8;
reg [7:0] k_x3, k_x5, k_x6, k_x7;
reg [7:0] tmp;


// Stage 1 register
reg [8:0] ycalc;    // y co-ordinate address calculation


// Stage 1 : arithmetic only

always @(posedge clk) begin
    if (rst) begin
        ycalc <= 0;
    end
    else if (en) begin
        cc_m1 <= cycle_count - 1;

        cc_x8    <= cycle_count << 3;          // *8
        cc_m1_x8 <= (cycle_count - 1) << 3;

        k_x3 <= (k << 1) + k;                   // k*3
        k_x5 <= (k << 2) + k;                   // k*5
        k_x6 <= (k << 2) + (k << 1);             // k*6
        k_x7 <= (k << 3) - k;                   // k*7


        // main address generation logic
    

        if (patch_size == 3 && (stride == 1 || stride == 2)) begin
            if (cycle_count == 0)
                ycalc <= stride * k;
            else if ((k > 5 && stride == 1) || (k == 3 && stride == 2))
                ycalc <= cc_m1_x8 + stride * k;
            else
                ycalc <= cc_x8 + stride * k;
        end


        else if (patch_size == 3 && stride == 3) begin
            tmp   <= cycle_count / 3;
            ycalc <= k_x3 + (tmp << 4) + (tmp << 3);   // *24
        end


        else if (patch_size == 5 && (stride == 1 || stride == 2 || stride == 4)) begin
            if (cycle_count == 0)
                ycalc <= stride * k;
            else if ((k > 3 && stride == 1) || (k > 1 && stride == 2) || (k == 1 && stride == 4))
                ycalc <= cc_m1_x8 + stride * k;
            else
                ycalc <= cc_x8 + stride * k;
        end


        else if (patch_size == 5 && stride == 3) begin
            tmp   <= ((cc_m1 * (cycle_count > 1)) / 3)
                    + ((k==0 || k==1) && cycle_count>0);
            ycalc <= k_x3 + (tmp << 4) + (tmp << 3);   // *24
        end


        else if (patch_size == 5 && stride == 5) begin
            tmp   <= cycle_count / 5;
            ycalc <= k_x5 + (tmp << 5) + (tmp << 3);   // *40
        end


        else if (patch_size == 7 && (stride == 1 || stride == 2 || stride == 4)) begin
            if (cycle_count == 0)
                ycalc <= stride * k;
            else if ((k > 1 && stride == 1) || (k > 0 && stride == 2) || (k == 1 && stride == 4))
                ycalc <= cc_m1_x8 + stride * k;
            else
                ycalc <= cc_x8 + stride * k;
        end


        else if (patch_size == 7 && stride == 3) begin
            tmp   <= ((cc_m1 * (cycle_count > 1)) / 3)
                    + ((k==0) && cycle_count>0);
            ycalc <= k_x3 + (tmp << 4) + (tmp << 3);   // *24
        end


        else if (patch_size == 7 && stride == 5) begin
            tmp   <= ((cc_m1 * (cycle_count > 1)) / 5)
                    + ((k==0) && cycle_count>0);
            ycalc <= k_x5 + (tmp << 5) + (tmp << 3);   // *40
        end


        else if (stride == 6) begin
            tmp   <= ((cc_m1 * (cycle_count > 1)) / 3)
                    + ((k==0) && cycle_count>0);
            ycalc <= k_x6 + (tmp << 4) + (tmp << 3);   // *24
        end


        else if (stride == 7) begin
            tmp   <= cycle_count / 7;
            ycalc <= k_x7 + (tmp << 6) - (tmp << 3);   // *56
        end
    end
    else ycalc <= 0;
end

always @(posedge clk) begin
    if (rst)
        ycor1 <= 0;
    else
        ycor1 <= ycalc;
end

//Thermometer encoding of address

always @(posedge clk) begin
    if (rst) begin
        y1 <= 0;
    end
    else begin
        for (i=0;i<HEIGHT;i=i+1)
            y1[i] <= (i < ycor1);
    end
end

    always @(posedge clk) begin
    if(rst)clause_active <= 0;
    else if(en) clause_active <= 1'b1;
    else clause_active <= 1'b0;     
    
    cycle_count <= cycle_counts - 1;
    if(y1[HEIGHT - patch_size - 1])done <= 1'b1;
    else done <= 1'b0; 
end
    
endmodule
