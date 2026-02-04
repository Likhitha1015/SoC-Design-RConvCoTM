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
    input [127:0]tdata,         //Input image data from dma
    input [255:0]clause_write,
    input [255:0]weight_write,
    input tvalid,               //valid signal from dma to send data
    input [15:0] tkeep,         // protocol signals not used inside IP
    input tlast,
    output reg [$clog2(CLAUSEN)-1 :0] bram_addr_a,  // Clauses adress
    output reg [$clog2(CLASSN)-1 :0] bram_addr_a2, // Weights
    output reg tready,              // Ready to receive data
    output enb,                     //Enable signal for BRAMs
    output reg [3:0] output_params, // Class output
    output reg [31:0]web ,          // BRAM write enable
    output reg [255:0] dinb,        // BRAM write Data
        output img_done
);
    wire img_rst,rst;
   
    integer x;
    wire [127:0]total_img;
    
    
    wire [2:0]stride;
    reg [3:0] class_op;
    wire [3:0] class_op_wire;
    wire wea,wea2;              //enable signals to load data from bram to IP
    wire [31:0]bram_addr_a_wire; 
    wire [31:0]bram_addr_a2_wire;
    reg [((HEIGHT + 8)*WIDTH)-1:0] total_memory; //full image
    wire [8:0] clause;                             // number of clauses
    wire img_done_wire;                            // One image classified 
    reg img_load_done;                             // Image loading is done initially
    integer i,j,k,l;
    wire done_rmu;                                 // IMAGE completely moved to remap unit 
    genvar idx;
    wire clause_act;                               // Enable during convolution operation for each clause
    reg [5:0] cycle_count;                         // Accessing 8 rows of image till last col is counted as one cycle
    reg shift_enable;                              // movement of pixels into the buffer
    wire [7:0] pixel_out;                          // image pixels
    wire [3:0]classes;                             // number of classes
    reg [7:0] pixel_in;                             
    wire [7:2] residues_buf;                       
    wire [7:2] residues_rmu;                        // same residues, realigned as per remap unit design
    wire [$clog2(WIDTH + 2) :0] img_width_count;    // x-coordinate of image
    wire [7:0] pe_en;                               // Used in convolution unit 
    wire reset;
    wire [2:0] patch_size;
    wire[6:0] processor_in1,processor_in2,processor_in3,processor_in4,processor_in5,processor_in6,processor_in7,processor_in8; // input to PE
    wire [WIDTH - 1:0] p1x1;                                        // x co-ordinate thermometer encoded adrress 
    wire [HEIGHT - 1:0] p1y1,p2y1,p3y1,p4y1,p5y1,p6y1,p7y1,p8y1; // y co-ordinate adresses of each patch (max 8 at a time)
    genvar b; 
    wire cycle_change;                          // Every 8 rows till last col is done
    wire [4:0] img_wide;
   
    assign img_wide = WIDTH;
    assign clause = model_params[14:6];         // Clause count from input model params
    assign classes = model_params[18:15];
    assign img_rst = rst ? 1 : img_done_wire;
    assign enb = 1;                             
    assign total_img = tdata;
    assign rst = rt | stop;
    assign patch_size = model_params[2:0];
    assign stride = model_params[5:3];
    assign wea = stop ? 1'b1 : (bram_addr_a <  { {23{1'b0}}, clause }) ? 1'b1 : 1'b0;
    assign wea2 = stop ? 1'b1 : (bram_addr_a2 < classes * 5) ? 1'b1 : 1'b0;
    assign reset = wea || rst || !img_load_done || wea2;
    assign img_done = img_done_wire;
    reg [9:0] addr0,addr1,addr2,addr3,addr4,addr5,addr6,addr7; // starting adress of 8 rows while accesing
    reg valid_addr;                                 // To prevent image width from exceeding 28
    assign bram_addr_a_wire = bram_addr_a;
    assign bram_addr_a2_wire = bram_addr_a2;
    reg p0,p1,p2,p3,p4,p5,p6,p7;                    //each pixel in 1 col (8)

    // BRAM adress increment to load clauses and weights
    
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
    

// Buffer instantiation    
    
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


// Reversing residues coming from buffer to match remap design order

    generate
        for (b = 2; b < 8; b = b + 1)
        begin: reverse_loop 
            assign residues_rmu [b] = residues_buf[9 - b];
    end 
    endgenerate

//Remap unit instantiation
    
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

// Image accesing address generation

always @(posedge clk) begin
  if (reset) begin
    addr0 <= 0; addr1 <= 0; addr2 <= 0; addr3 <= 0;
    addr4 <= 0; addr5 <= 0; addr6 <= 0; addr7 <= 0;
    valid_addr <= 0;
  end else begin
    addr0 <= (j+0)*WIDTH + k;
    addr1 <= (j+1)*WIDTH + k;
    addr2 <= (j+2)*WIDTH + k;
    addr3 <= (j+3)*WIDTH + k;
    addr4 <= (j+4)*WIDTH + k;
    addr5 <= (j+5)*WIDTH + k;
    addr6 <= (j+6)*WIDTH + k;
    addr7 <= (j+7)*WIDTH + k;

    valid_addr <= ((j*WIDTH)+k < WIDTH*HEIGHT);
  end
end


//Accesing pixels from the adress of image

always @(posedge clk) begin
  if (reset) begin
    p0<=0; p1<=0; p2<=0; p3<=0;
    p4<=0; p5<=0; p6<=0; p7<=0;
  end else begin
  if(valid_addr) begin
    p0 <= total_memory[addr0];
    p1 <= total_memory[addr1];
    p2 <= total_memory[addr2];
    p3 <= total_memory[addr3];
    p4 <= total_memory[addr4];
    p5 <= total_memory[addr5];
    p6 <= total_memory[addr6];
    p7 <= total_memory[addr7];
    end
    else begin
    p0 <= 1'b0;
    p1 <= 1'b0;
    p2 <= 1'b0;
    p3 <= 1'b0;
    p4 <= 1'b0;
    p5 <= 1'b0;
    p6 <= 1'b0;
    p7 <= 1'b0;
    end
  end
end

// packing each pixel of 8 rows from image

always @(posedge clk) begin
  if (reset) begin
    pixel_in <= 0;
    shift_enable <= 0;
  end 
  else if (!cycle_change) begin
    shift_enable <= 1;
    if (valid_addr)
      pixel_in <= {p7,p6,p5,p4,p3,p2,p1,p0};
    else
      pixel_in <= 0;
  end
  else shift_enable <= 1;
end


always @(posedge clk) begin
    if (rst) begin
        tready <= 0;
        output_params <= 0;
        x             <= -1;    // To ensure it starts from 0 th address
        img_load_done <= 0;
        cycle_count  <= 1;
        k            <= 0;
        j            <= 0;
    end 
    else begin
        if (img_rst) begin
            tready <= 0;
            x            <= -1;
            img_load_done <= 0;
        end 
        else begin
            tready <= tvalid && !img_load_done && !wea && !wea2;
            class_op <= class_op_wire;

            if (!(img_rst || img_load_done || wea || wea2)) begin
                for (i = 0; i < 128; i = i + 1) begin
                    total_memory[(x << 7) + i] <= total_img[i];
                end
                x <= x + 1;
            end

            // loading image in 8 cycles from dma ( x= 0-7)
            if (x == 7)
            begin
                img_load_done <= 1;
                tready <= 0;
            end
            else begin
                img_load_done <= 0;
                tready <= 1;
            end

            if (!reset && !cycle_change) 
            begin            
                k <= k + 1;                  // image col increment during loading
            end
            else if (cycle_change && !reset)
            begin
                j <= j + 8;                 // image row increment
                k <= 0;
                cycle_count <= cycle_count + 1;
            end
            else begin
                j <= 0;
                k <= 0;
                cycle_count  <= 1;
            end
        end
        if(img_done_wire)  output_params <= class_op;    // classification done signal 
        else    output_params <= output_params;
    end
end

// Convolution Engine
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
