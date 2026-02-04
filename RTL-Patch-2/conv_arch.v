`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.07.2025 17:01:03
// Design Name: 
// Module Name: conv_arch
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

//////////////////////////////////////////////////////////////////////////////////


module conv_arch(
    clk,rst,stride,pe_en,pe_en_out,patch_size,clause_op,prev_clause_op,clause_act,clause_done,clause_write,valid,img_rst,
    processor_in1,processor_in2,processor_in3,processor_in4,processor_in5,processor_in6,processor_in7,processor_in8,
    p1y1,p1x1,p2y1,p3y1,p4y1,p5y1,p6y1,p7y1,p8y1,ipdone,opdone_reg,stride_out,patch_size_out,
    processor_out1,processor_out2,processor_out3,processor_out4,processor_out5,processor_out6,processor_out7,processor_out8,
    po1x,po1y,po2y,po3y,po4y,po5y,po6y,po7y,po8y
    );
    parameter  IMG_WIDTH = 32, IMG_HEIGHT = 32,CLAUSEN = 10,CLASSN = 5,
            CLAUSE_WIDTH = (35 + IMG_HEIGHT + IMG_WIDTH)*2;
    input clk,rst,img_rst,ipdone;
    input [2:0] stride;
    input valid;
    wire conv_enable;
    input [7:0] pe_en;
    output wire [2:0]stride_out;
    output wire [2:0]patch_size_out;
    output reg [7:0] pe_en_out;
    input [6:0] processor_in1,processor_in2,processor_in3,processor_in4,processor_in5,processor_in6,processor_in7,processor_in8;
    input wire [IMG_WIDTH - 1:0] p1x1;
    input wire [IMG_HEIGHT - 1:0] p1y1,p2y1,p3y1,p4y1,p5y1,p6y1,p7y1,p8y1;
    input [2:0] patch_size;
    input prev_clause_op;    // partial clause o/p
    output reg clause_op;    // final clause o/p
    output reg [6:0] processor_out1,processor_out2,processor_out3,processor_out4,processor_out5,processor_out6,processor_out7,processor_out8;
    output reg [IMG_WIDTH - 1:0] po1x;
    output reg [IMG_HEIGHT - 1:0] po1y,po2y,po3y,po4y,po5y,po6y,po7y,po8y;
    wire [7:0] bclause_op;   // clause o/p for 8 processors
    input clause_act;
    input [255:0]clause_write;
    output reg clause_done;
    output reg opdone_reg;
    reg rst_n;
    reg [IMG_HEIGHT - 1:0] nypos[0:7];    //negated y position
    reg [IMG_WIDTH - 1:0] nxpos;           // negated x position
    reg [(CLAUSE_WIDTH)-1:0]clause;
    reg Xmatch;                            // x address matched with clause address
    reg Ymatch[7:0];
    reg [IMG_HEIGHT - 1:0] Ypos_mask,nYpos_mask;  // addresses coming from trained clause
    reg [IMG_WIDTH - 1:0] Xpos_mask,nXpos_mask;
    reg [48:0]patch_rule_1;                         // paytch bites coming from clause
    reg [48:0]patch_neg_rule_1;
    reg [27:0] force_ones;                         
    assign patch_size_out = patch_size;
    assign stride_out = stride;
        
    always @(posedge clk)begin
        if(rst)begin
            clause <= 0;
        end
        else if(valid)  clause <= clause_write;
        else clause<= clause;
    end
        
        
    always @(*) begin
        if (patch_size >= 28)
            force_ones = 28'hFFFFFFF;  // all 1s if patch_size >= 28
        else
            force_ones = (28'hFFFFFFF << (28 - patch_size));  // MSB ones, rest zeros
    end


    conv_enable_generation CE(
                .clk(clk),
                .rst(rst_n),
                .stride(stride),
                .patch_size(patch_size),
                .conv_enable(conv_enable)
            );

always @(posedge clk)begin
    if(rst)begin
    Ypos_mask <=28'hFFFF_FFF;
        Xpos_mask <= 28'hFFFF_FFF;
        end
    else if(rst_n)begin
        Xmatch        <= 0;
        Ymatch[1]     <= 1'b0;
        Ymatch[2]     <= 1'b0;
        Ymatch[3]     <= 1'b0;
        Ymatch[4]     <= 1'b0;
        Ymatch[5]     <= 1'b0;
        Ymatch[6]     <= 1'b0;
        Ymatch[7]     <= 1'b0;
        Ymatch[0]     <= 1'b0;
        
        nypos[0]      <= 0;
        nypos[1]      <= 0;
        nypos[2]      <= 0;
        nypos[3]      <= 0;
        nypos[4]      <= 0;
        nypos[5]      <= 0;
        nypos[6]      <= 0;
        nypos[7]      <= 0;
        
        end
    else begin
        nypos[0] <= ~p1y1;
        nypos[1] <= ~p2y1;
        nypos[2] <= ~p3y1;
        nypos[3] <= ~p4y1;
        nypos[4] <= ~p5y1;
        nypos[5] <= ~p6y1;
        nypos[6] <= ~p7y1;
        nypos[7] <= ~p8y1;
        nxpos <= ~p1x1;
        
        patch_rule_1 <= 49'd0;          // default full assignment
        patch_neg_rule_1 <= 49'd0;
        
        if (patch_size == 3)
        begin
            patch_rule_1[2:0]   <= clause[52:50];//conv unit and rules vector matching
            patch_rule_1[9:7]   <= clause[55:53];
            patch_rule_1[16:14] <= clause[58:56]; // neg patch and patch pixels extraction from clause

            patch_neg_rule_1[2:0]   <= clause[111:109];
            patch_neg_rule_1[9:7]   <= clause[114:112];
            patch_neg_rule_1[16:14] <= clause[117:115];

        end
        
        else if (patch_size == 5)
        begin
            patch_rule_1[4:0]    <= clause[50:46];
            patch_rule_1[11:8]   <= clause[55:51];
            patch_rule_1[18:14]  <= clause[60:56];
            patch_rule_1[25:21]  <= clause[65:61];
            patch_rule_1[32:28]  <= clause[70:66];

            patch_neg_rule_1[4:0]    <= clause[121:117];
            patch_neg_rule_1[11:7]   <= clause[126:122];
            patch_neg_rule_1[18:14]  <= clause[131:127];
            patch_neg_rule_1[25:21]  <= clause[136:132];
            patch_neg_rule_1[32:28]  <= clause[141:137];

        end

        else begin
            patch_rule_1[48:0] <= clause[90:42];
            patch_neg_rule_1[48:0] <= clause[181:133];
                    
        end
        
        if (patch_size == 3'd3) begin
                Ypos_mask  <= clause[24:0];    //if 32 [28:0]    64 [60:0]    128 [124:0]   256 [252:0]
                Xpos_mask  <= clause[49:25];   //if 32 [57:29]   64 [121:61]  128 [249:125] 256 [505:253]
                nYpos_mask <= clause[83:59];   //if 32 [95:67]   64 [191:131] 128 [383:259] 256 [767:515]
                nXpos_mask <= clause[108:84];  //if 32 [124:96]  64 [252:192] 128 [508:384] 256 [1020:768]
        end else if (patch_size == 3'd5) begin
                Ypos_mask  <= clause[22:0];    //if 32 [26:0]    64 [58:0]    128 [122:0]   256 [250:0]
                Xpos_mask  <= clause[45:23];   //if 32 [53:27]   64 [117:59]  128 [245:123] 256 [501:251]
                nYpos_mask <= clause[93:71];    //if 32 [105:79]  64 [201:143] 128 [393:271] 256 [777:527]
                nXpos_mask <= clause[116:94];    //if 32 [132:106] 64 [260:202] 128 [516:394] 256 [1028:778]

        end else if (patch_size == 3'd7) begin
                Ypos_mask <= clause[20:0];     //if 32 [24:0]    64 [56:0]    128 [120:0]   256 [248:0]
                Xpos_mask <= clause[41:21];    //if 32 [49:25]   64 [113:57]  128 [241:121] 256 [497:249]
                nYpos_mask <= clause[111:91];  //if 32 [123:99]  64 [219:163] 128 [411:291] 256 [795:547]
                nXpos_mask <= clause[132:112]; //if 32 [148:124] 64 [276:220] 128 [532:412] 256 [1044:796]

        end else begin
            Ypos_mask  <= 1'b0;
            Xpos_mask  <= 1'b0;
            nYpos_mask <= 1'b0;
            nXpos_mask <= 1'b0;
        end

        Xmatch    <= &(p1x1 | ~Xpos_mask | force_ones) && (&(nxpos    | ~nXpos_mask | force_ones));
        Ymatch[0] <= &(p1y1 | ~Ypos_mask | force_ones) && (&(nypos[0] | ~nYpos_mask | force_ones));
        Ymatch[1] <= &(p2y1 | ~Ypos_mask | force_ones) && (&(nypos[1] | ~nYpos_mask | force_ones));
        Ymatch[2] <= &(p3y1 | ~Ypos_mask | force_ones) && (&(nypos[2] | ~nYpos_mask | force_ones));
        Ymatch[3] <= &(p4y1 | ~Ypos_mask | force_ones) && (&(nypos[3] | ~nYpos_mask | force_ones));
        Ymatch[4] <= &(p5y1 | ~Ypos_mask | force_ones) && (&(nypos[4] | ~nYpos_mask | force_ones));
        Ymatch[5] <= &(p6y1 | ~Ypos_mask | force_ones) && (&(nypos[5] | ~nYpos_mask | force_ones));
        Ymatch[6] <= &(p7y1 | ~Ypos_mask | force_ones) && (&(nypos[6] | ~nYpos_mask | force_ones));
        Ymatch[7] <= &(p8y1 | ~Ypos_mask | force_ones) && (&(nypos[7] | ~nYpos_mask | force_ones));
    
    end 

    if(!(rst || img_rst)) clause_done <= clause_act;
    else clause_done <= 1'b0;

    rst_n <= rst ||!(clause_act) || img_rst;

    if(rst || img_rst)   clause_op <= 0;
    else
        clause_op <= (prev_clause_op | (|bclause_op) );
        processor_out1 <= processor_in1;
        processor_out2 <= processor_in2;
        processor_out3 <= processor_in3;
        processor_out4 <= processor_in4;
        processor_out5 <= processor_in5;
        processor_out6 <= processor_in6;
        processor_out7 <= processor_in7;
        processor_out8 <= processor_in8;
        pe_en_out <= pe_en;
        po1x <= p1x1;
        po1y <= p1y1;
        po2y <= p2y1;
        po3y <= p3y1;
        po4y <= p4y1;
        po5y <= p5y1;
        po6y <= p6y1;
        po7y <= p7y1;
        po8y <= p8y1;
    end

    always@(posedge clk)begin
        if(rst_n)opdone_reg <= 0;
        else opdone_reg <= ipdone;
    end
    Convolution PE1 (clk, ( rst || img_rst), conv_enable, pe_en[0], processor_in1, patch_size, patch_rule_1,patch_neg_rule_1,Xmatch,Ymatch[0],bclause_op[0]);
    Convolution PE2 (clk, ( rst || img_rst), conv_enable, pe_en[1], processor_in2, patch_size, patch_rule_1,patch_neg_rule_1,Xmatch,Ymatch[1],bclause_op[1]);
    Convolution PE3 (clk, ( rst || img_rst), conv_enable, pe_en[2], processor_in3, patch_size, patch_rule_1,patch_neg_rule_1,Xmatch,Ymatch[2],bclause_op[2]);
    Convolution PE4 (clk, ( rst || img_rst), conv_enable, pe_en[3], processor_in4, patch_size, patch_rule_1,patch_neg_rule_1,Xmatch,Ymatch[3],bclause_op[3]);
    Convolution PE5 (clk, ( rst || img_rst), conv_enable, pe_en[4], processor_in5, patch_size, patch_rule_1,patch_neg_rule_1,Xmatch,Ymatch[4],bclause_op[4]);
    Convolution PE6 (clk, ( rst || img_rst), conv_enable, pe_en[5], processor_in6, patch_size, patch_rule_1,patch_neg_rule_1,Xmatch,Ymatch[5],bclause_op[5]);
    Convolution PE7 (clk, ( rst || img_rst), conv_enable, pe_en[6], processor_in7, patch_size, patch_rule_1,patch_neg_rule_1,Xmatch,Ymatch[6],bclause_op[6]);
    Convolution PE8 (clk, ( rst || img_rst), conv_enable, pe_en[7], processor_in8, patch_size, patch_rule_1,patch_neg_rule_1,Xmatch,Ymatch[7],bclause_op[7]);
    
endmodule
