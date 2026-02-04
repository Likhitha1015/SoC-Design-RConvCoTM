`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: top
// Description: Top module connecting buffer, remapunit, convolution units, etc.
//////////////////////////////////////////////////////////////////////////////////

module top#(
    parameter WIDTH = 28, 
            HEIGHT = 28, 				
            CLAUSEN = 10,
            CLASSN = 10,
            CLAUSE_WIDTH = (35 + HEIGHT + WIDTH)*2   // MAX CLAUSE WIDTH
)
(
    input clk,
    input rst,img_rst,
    input [2:0] patch_size,
    input [2:0] stride,
    input [8:0]clauses,
    input [255:0]clause_write,
    input [7:0] pe_en,
    input  [$clog2(CLASSN)-1 :0]bram_addr_a2,
    input [255:0]weight_write,
    input done_rmu,
    input [6:0] processor_in1,processor_in2,processor_in3,processor_in4,processor_in5,processor_in6,processor_in7,processor_in8,
    input [HEIGHT - 1:0]p1y1,p2y1,p3y1,p4y1,p5y1,p6y1,p7y1,p8y1,
    input [WIDTH - 1:0] p1x1,
    input wea,wea2,
    input [31:0]bram_addr_a,
    input clause_act,
    output reg [$clog2(CLASSN)-1:0] class_op,   // FINAL CLASS output
    output reg done
);       
    wire [CLAUSEN - 1:0] clause_op;     
    reg signed [17:0] temp_sum[CLASSN-1:0];     // Temporary class sum of each class
    wire reset,done_conv;                       // Convolution done signal till last clause
    wire [2:0] patch_size_op [CLAUSEN : 0];        // To reduce fanout
    wire [2:0] stride_op [CLAUSEN : 0];
    
    wire [0:CLAUSEN-1] done_conv_arch;          // per clause convolution done signal    (weights will be added based on o/p)
    wire [6:0] processor_out [1: CLAUSEN][0:7];  // stage wise shifting of pixels in PE array
    wire [WIDTH-1:0] po_x1 [1:CLAUSEN];
    wire [7:0] pe_en_out [1:CLAUSEN];
    wire [HEIGHT-1:0] po_y1 [1:CLAUSEN];         // stage wise shifting of adresses
    wire [HEIGHT-1:0] po_y2 [1:CLAUSEN];           
    wire [HEIGHT-1:0] po_y3 [1:CLAUSEN];           
    wire [HEIGHT-1:0] po_y4 [1:CLAUSEN];           
    wire [HEIGHT-1:0] po_y5 [1:CLAUSEN];           
    wire [HEIGHT-1:0] po_y6 [1:CLAUSEN];           
    wire [HEIGHT-1:0] po_y7 [1:CLAUSEN];           
    wire [HEIGHT-1:0] po_y8 [1:CLAUSEN];        
    wire clause_done [1:CLAUSEN];              // To delay clause_act activation signal
    wire [8:0] weight[CLASSN - 1:0];           // stores weights
    reg [$clog2(CLAUSEN):0]clause_no;         // Latest evaluated clause to get corresponding weights
    reg ip_done_reg;                          // Complete patch generation done from remap unit
    reg done_conv_long;                       // Total class sums comparision when enabled (10 cycles)
    reg signed [17:0] max_sum;      
    reg [$clog2(CLASSN):0] cnt;               // 10 cycle count for done_conv_long
    reg should_add;                           // stores condition result of clause
    reg signed [8:0] weight_snapshot [CLASSN-1:0];  //stores weights pipelined

    reg [$clog2(CLAUSEN)-1:0] clause_idx;      // pipelined clause no
    reg done_bit_r;                            // pipelined done_conv_arch
    reg op_bit_r;                              // pipelined clause op
    reg should_add_r;                          // condition for adding weights

    reg signed [31:0] add_result [0:CLASSN-1];  // temporary sum

    integer jdx,kdx,ldx;

    assign patch_size_op[0] = patch_size;
    assign stride_op[0] = stride;
    assign reset = wea || rst || wea2 || img_rst;
    assign done_conv = done_conv_arch[clauses-1]; 

always @(posedge clk) begin
    if(reset) begin
        cnt <= 0;
        done_conv_long <= 0;
    end
    else begin
        // New pulse came ? reload counter
        if(done_conv) begin
            cnt <= CLASSN - 1;
            done_conv_long <= 1;
        end

        // Continue stretching
        else if(cnt != 0) begin
            cnt <= cnt - 1;
            done_conv_long <= 1;
        end

        // Counter expired ? deassert
        else begin
            done_conv_long <= 0;
        end
    end
end




always @(posedge clk) begin
    if (reset) begin
        clause_no    <= 1;
        clause_idx   <= 0;
        should_add   <= 0;
        should_add_r <= 0;
        ip_done_reg  <= 0;

        for (jdx = 0; jdx < CLASSN; jdx = jdx+1)
            weight_snapshot[jdx] <= 0;
    end
    else begin
        if (done_rmu) begin
            ip_done_reg <= 1;
        end

        clause_idx <= clause_no;
        done_bit_r <= done_conv_arch[clause_idx];
        op_bit_r   <= clause_op[clause_idx];
        should_add_r <= done_bit_r & op_bit_r;

        if (ip_done_reg) begin
            should_add <= should_add_r;
            for (jdx = 0; jdx < CLASSN; jdx = jdx+1)
                weight_snapshot[jdx] <= weight[jdx];
            clause_no <= clause_no + 1;
        end
        else begin
            should_add <= 0;
        end
    end
end

always @(posedge clk) begin
    if (reset) begin
        for (ldx=0; ldx<CLASSN; ldx=ldx+1)
            add_result[ldx] <= 0;
    end
    else begin
        for (ldx=0; ldx<CLASSN; ldx=ldx+1) begin
            if (should_add)
                add_result[ldx] <= temp_sum[ldx] + weight_snapshot[ldx];
            else
                add_result[ldx] <= temp_sum[ldx];
        end
    end
end

always @(posedge clk) begin
    if (reset) begin
        for (ldx=0; ldx<CLASSN; ldx=ldx+1)
            temp_sum[ldx] <= 0;
    end
    else begin
        for (ldx=0; ldx<CLASSN; ldx=ldx+1)
            temp_sum[ldx] <= add_result[ldx];
    end
end

always @(posedge clk) begin
    if (reset) begin
        max_sum  <= -1000;       // worst case 
        kdx      <= 0;
        class_op<= 0;
        done     <= 0;
    end
    else if (done_conv_long) begin

        if (temp_sum[kdx] > max_sum) begin
            max_sum   <= temp_sum[kdx];
            class_op <= kdx;
        end

        if (kdx == CLASSN-1) begin
            done <= 1'b1;
            kdx  <= 0;
        end
        else begin
            kdx  <= kdx + 1'b1;
            done <= 1'b0;
        end
    end
end

    
    


// extracting 2's complemented weights
    genvar id,idx;
    generate
    for (idx = 0; idx < CLASSN; idx = idx + 1) begin : wt_chain_pos
        weight_adder #(.CLAUSEN(CLAUSEN))W(
                .clk(clk),
                .rst(rst),
                .valid((bram_addr_a2 / 5)== idx),
                .offset(bram_addr_a2 % 5),
                .clauses(clauses),
                .weight_write(weight_write),
                .clause_no(clause_no),
                .weight(weight[idx])
                );
                
    end
    endgenerate
    
    
generate
    for (id = 0; id < CLAUSEN; id = id + 1) begin : conv_chain_pos
        if(id == 0 || id==1)begin :conv_chain_exception
                conv_arch  #(
                .IMG_WIDTH(WIDTH), 
                .IMG_HEIGHT(HEIGHT), 
                .CLAUSEN(CLAUSEN),
                .CLASSN(CLASSN),
                .CLAUSE_WIDTH(CLAUSE_WIDTH)
                ) C (
            .clk(clk),
            .rst(rst),
            .img_rst(img_rst),
            .patch_size_out(patch_size_op[id + 1]),
            .ipdone(done_rmu),
            .opdone_reg(done_conv_arch[id]),
            .stride(stride),
            .stride_out(stride_op[id+1]),
            .pe_en(pe_en),
            .pe_en_out(pe_en_out[id+1]),
            .patch_size(patch_size),
            .valid(bram_addr_a == id),
            .clause_op(clause_op[id]),
            .clause_act(clause_act),
            .clause_write(clause_write),
            .prev_clause_op(clause_output[id]),
            .clause_done(clause_done[id+1]),
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

            .processor_out1(processor_out[id+1][0]),
            .processor_out2(processor_out[id+1][1]),
            .processor_out3(processor_out[id+1][2]),
            .processor_out4(processor_out[id+1][3]),
            .processor_out5(processor_out[id+1][4]),
            .processor_out6(processor_out[id+1][5]),
            .processor_out7(processor_out[id+1][6]),
            .processor_out8(processor_out[id+1][7]),

            .po1x(po_x1[id+1]),
            .po1y(po_y1[id+1]),
            .po2y(po_y2[id+1]),
            .po3y(po_y3[id+1]),
            .po4y(po_y4[id+1]),
            .po5y(po_y5[id+1]),
            .po6y(po_y6[id+1]),
            .po7y(po_y7[id+1]),
            .po8y(po_y8[id+1])
        );
    end
        else begin : conv_chain_general
        conv_arch #(
                .IMG_WIDTH(WIDTH), 
                .IMG_HEIGHT(HEIGHT), 
                .CLAUSEN(CLAUSEN),
                .CLASSN(CLASSN),
                .CLAUSE_WIDTH(CLAUSE_WIDTH)
                ) C (
            .clk(clk),
            .rst(rst || !(id < clauses)),
            .img_rst(img_rst),
            .stride(stride_op[id]),
            .pe_en(pe_en_out[id]),
            .patch_size_out(patch_size_op[id + 1]),
            .pe_en_out(pe_en_out[id+1]),
            .stride_out(stride_op[id+1]),
            .ipdone(done_conv_arch[id-1]),
            .opdone_reg(done_conv_arch[id]),
            .patch_size(patch_size_op[id]),
            .valid(bram_addr_a == id),
            .clause_write(clause_write),
            .clause_op(clause_op[id]),
            .clause_act(clause_done[id]),
            .clause_done(clause_done[id+1]),
            .prev_clause_op(clause_output[id]),
            // Processor inputs: use stage i signals
            .processor_in1(processor_out[id][0]),
            .processor_in2(processor_out[id][1]),
            .processor_in3(processor_out[id][2]),
            .processor_in4(processor_out[id][3]),
            .processor_in5(processor_out[id][4]),
            .processor_in6(processor_out[id][5]),
            .processor_in7(processor_out[id][6]),
            .processor_in8(processor_out[id][7]),

            .p1y1(po_y1[id]),
            .p1x1(po_x1[id]),
            .p2y1(po_y2[id]),
            .p3y1(po_y3[id]),
            .p4y1(po_y4[id]),
            .p5y1(po_y5[id]),
            .p6y1(po_y6[id]),
            .p7y1(po_y7[id]),
            .p8y1(po_y8[id]),

            .processor_out1(processor_out[id+1][0]),
            .processor_out2(processor_out[id+1][1]),
            .processor_out3(processor_out[id+1][2]),
            .processor_out4(processor_out[id+1][3]),
            .processor_out5(processor_out[id+1][4]),
            .processor_out6(processor_out[id+1][5]),
            .processor_out7(processor_out[id+1][6]),
            .processor_out8(processor_out[id+1][7]),

            .po1x(po_x1[id+1]),
            .po1y(po_y1[id+1]),
            .po2y(po_y2[id+1]),
            .po3y(po_y3[id+1]),
            .po4y(po_y4[id+1]),
            .po5y(po_y5[id+1]),
            .po6y(po_y6[id+1]),
            .po7y(po_y7[id+1]),
            .po8y(po_y8[id+1])
        );
        end
    end
endgenerate
endmodule

