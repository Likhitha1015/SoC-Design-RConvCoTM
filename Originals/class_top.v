`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.07.2025 18:30:22
// Design Name: 
// Module Name: class_top
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

module class_top#(
    parameter CLAUSEN = 140,
    CLASSN = 10,
    HEIGHT = 28,
    WIDTH = 28,
    CLAUSE_WIDTH = (35 + HEIGHT + WIDTH)*2
)(  
    input clk,
    input rt,
    input stop,
    input [18:0] model_params,
    input [127:0]tdata,
    input [255:0]clause_write,
    input [255:0]weight_write,
    input tvalid,
    input [15:0] tkeep, 
    input tlast,
    output reg [31:0]bram_addr_a,
    output reg [31:0]bram_addr_a2,
    output reg tready,
    output enb,
    output reg [3:0] output_params,
    output reg [31:0]web ,
    output reg [255:0] dinb,
        output img_done
);
    wire img_rst,rst;
    assign rst = rt | stop;
    integer x;
    wire [127:0]total_img;
    assign total_img = tdata;
    assign enb = 1;
    wire [2:0]stride;
    reg [3:0] class_op;
    wire [3:0] class_op_wire;
    wire wea,wea2;
    wire [31:0]bram_addr_a_wire;
    wire [31:0]bram_addr_a2_wire;
    reg [((HEIGHT + 8)*WIDTH)-1:0] total_memory;
    (* keep = "true" *)wire [8:0] clause = model_params[14:6];
    (* keep = "true" *) wire img_done_wire;
    assign img_rst = rst ? 1 : img_done_wire;
    integer i,j,k,l;
    wire done_rmu;
    genvar idx;
    wire clause_act; 
    reg [5:0] cycle_count;
    reg shift_enable;
    wire [7:0] pixel_out;
    wire [3:0]classes = model_params[18:15];
    reg [7:0] pixel_in;
    wire [7:2] residues_buf;
    (* keep = "true" *)wire [7:2] residues_rmu;
    wire [$clog2(WIDTH + 2) :0] img_width_count;
    wire [7:0] pe_en;   
    wire reset;
    wire [2:0] patch_size;
    assign patch_size = model_params[2:0];
    assign stride = model_params[5:3];
    assign wea = stop ? 1'b1 : (bram_addr_a <  { {23{1'b0}}, clause }) ? 1'b1 : 1'b0;
    assign wea2 = stop ? 1'b1 : (bram_addr_a2 < classes * 5) ? 1'b1 : 1'b0;
    reg img_load_done;
    assign reset = wea || rst || !img_load_done || wea2;
    wire[6:0] processor_in1,processor_in2,processor_in3,processor_in4,processor_in5,processor_in6,processor_in7,processor_in8;
    wire [WIDTH - 1:0] p1x1;
    wire [HEIGHT - 1:0] p1y1,p2y1,p3y1,p4y1,p5y1,p6y1,p7y1,p8y1;
    genvar b; 
    wire cycle_change;
    
    assign img_done = img_done_wire;
    
    always@(posedge clk)begin
    web <= 31'b0;
    dinb <= 255'b0;
    
    if(rst)begin
    	i <= 0;
        bram_addr_a <= 0;
        bram_addr_a2 <= 0;
    end
    else begin
        bram_addr_a <= bram_addr_a;
        bram_addr_a2 <= bram_addr_a2;
            
        if(wea || wea2) begin 
        bram_addr_a2 <= wea2 ?  bram_addr_a2 + 1 : bram_addr_a2;
        bram_addr_a <= wea ? bram_addr_a + 1 : bram_addr_a;
        end 
    end
    end
    
    wire [4:0] img_wide;
    
    assign img_wide = WIDTH;
    
    assign bram_addr_a_wire = bram_addr_a;
    assign bram_addr_a2_wire = bram_addr_a2;
     buffer #(.BUF_WIDTH(WIDTH+2)) Buf(
        .clk(clk),
        .rst(reset),
        .pixel_in(pixel_in),
        .shift_enable(shift_enable),
        .done(1'b0),
        .img_width(img_wide),
        .pixel_out(pixel_out),
        .residues(residues_buf),
        .cycle_change(cycle_change),
        .img_width_count(img_width_count)
    );
        
    generate
    for (b = 2; b < 8; b = b + 1) begin: reverse_loop 
    assign residues_rmu [b] = residues_buf[9 - b];
    end 
    endgenerate
    
    remapunit #(
                .IMG_WIDTH(WIDTH), 
                .IMG_HEIGHT(HEIGHT) 
                ) R (
        .clk(clk),
        .rst(reset),
        .patch_size(patch_size),
        .stride(stride),
        .done(done_rmu),
        .xcor1(img_width_count),
        .pixel_in(pixel_out),
        .residues(residues_rmu),
        .cycle_counts(cycle_count),
        .cycle_detect(cycle_change),
        .processor_in1(processor_in1), .processor_in2(processor_in2),
        .processor_in3(processor_in3), .processor_in4(processor_in4),
        .processor_in5(processor_in5), .processor_in6(processor_in6),
        .processor_in7(processor_in7), .processor_in8(processor_in8),
        .p_en(pe_en),
        .p1y1(p1y1), .p1x1(p1x1), .p2y1(p2y1),.p3y1(p3y1), .p4y1(p4y1), 
        .p5y1(p5y1), .p6y1(p6y1),.p7y1(p7y1), .p8y1(p8y1),
        .clause_act(clause_act)
    );
always @(posedge clk) begin
    if (rst) begin
        tready <= 0;
        output_params <= 0;
        x            <= -1;
        img_load_done <= 0;
        cycle_count  <= 1;
        k            <= 0;
        j            <= 0;
        shift_enable <= 0;
        pixel_in     <= 0;
    end else begin
        if (img_rst) begin
        tready <= 0;
            shift_enable <= 0;
            pixel_in <= 0;
            x            <= -1;
            img_load_done <= 0;
        end 
        else begin
        tready <= tvalid && !img_load_done && !wea && !wea2;
        class_op <= class_op_wire;
        if (!(img_rst || img_load_done || wea || wea2)) begin
            for (i = 0; i < 128; i = i + 1) begin
                total_memory[x*128 + i] <= total_img[i];
            end
            x <= x + 1;
        end

        if (x == 7)begin
            img_load_done <= 1;
            tready <= 0;
        end
        if (!reset && !cycle_change) begin
            shift_enable <= 1;
            if((j*WIDTH)+k < WIDTH*HEIGHT)begin
            pixel_in <= {
                total_memory[((j+7)*WIDTH)+k],
                total_memory[((j+6)*WIDTH)+k],
                total_memory[((j+5)*WIDTH)+k],
                total_memory[((j+4)*WIDTH)+k],
                total_memory[((j+3)*WIDTH)+k],
                total_memory[((j+2)*WIDTH)+k],
                total_memory[((j+1)*WIDTH)+k],
                total_memory[(j*WIDTH)+k]
            };
            end
            else pixel_in <= 0;
            k <= k + 1;
        end
        else if (cycle_change && !reset) begin
            j <= j + 8;
            k <= 0;
            cycle_count <= cycle_count + 1;
        end
        else begin
        j <= 0;
            k <= 0;
            cycle_count  <= 1;
         end
    end
if(img_done_wire)output_params <= class_op;
else output_params <= output_params;
end
end


            top #(
                .WIDTH(WIDTH), 
                .HEIGHT(HEIGHT), 
                .CLAUSEN(CLAUSEN),
                .CLASSN(CLASSN),
                .CLAUSE_WIDTH(CLAUSE_WIDTH)
                ) T (
            .clk(clk),
            .rst(rst),
            .img_rst(img_rst),
            .patch_size(patch_size),
            .stride(stride),
            .wea(wea),
            .bram_addr_a(bram_addr_a_wire),
            .clause_write(clause_write),
            .pe_en(pe_en),
            .clauses(clause),
            .weight_write(weight_write),
            .wea2(wea2),
            .bram_addr_a2(bram_addr_a2_wire),
            .clause_act(clause_act),
            .processor_in1(processor_in1),
            .processor_in2(processor_in2),
            .processor_in3(processor_in3),
            .processor_in4(processor_in4),
            .processor_in5(processor_in5),
            .processor_in6(processor_in6),
            .processor_in7(processor_in7),
            .processor_in8(processor_in8),
            .p1y1(p1y1),
            .p1x1(p1x1),
            .p2y1(p2y1),
            .p3y1(p3y1),
            .p4y1(p4y1),
            .p5y1(p5y1),
            .p6y1(p6y1),
            .p7y1(p7y1),
            .p8y1(p8y1),
            .done(img_done_wire),
            .class_op(class_op_wire),
            .done_rmu(done_rmu)
            );

endmodule
