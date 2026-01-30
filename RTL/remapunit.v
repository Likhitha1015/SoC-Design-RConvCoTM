`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/11/2024 04:50:04 PM
// Design Name: 
// Module Name: remapunit
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

module remapunit(clk, rst, patch_size,stride,pixel_in, residues,cycle_counts,cycle_detect,xcor1,
               processor_in1,processor_in2,processor_in3,processor_in4,processor_in5,processor_in6,processor_in7,processor_in8
               ,p_en,p1y1,p1x1,p2y1,p3y1,p4y1,p5y1,p6y1,p7y1,p8y1,clause_act,done);

parameter  IMG_WIDTH = 32;
parameter  IMG_HEIGHT = 32;

input clk, rst,cycle_detect;
input [2:0] patch_size,stride;
input [7:0] pixel_in;
input [5:0] residues,cycle_counts;
input [$clog2(IMG_WIDTH + 2) :0]xcor1;
output reg [6:0] processor_in1,processor_in2,processor_in3,processor_in4,processor_in5,processor_in6,processor_in7,processor_in8;
output wire [7:0] p_en;
output reg [IMG_WIDTH - 1:0] p1x1;
output wire [IMG_HEIGHT - 1:0] p1y1,p2y1,p3y1,p4y1,p5y1,p6y1,p7y1,p8y1;
output reg clause_act;
output reg done;
reg [2:0] k1, k2, k3, k4, k5, k6, k7, k8;
reg done_seen;
integer l;
wire [7:0] clause_active;
wire [7:0] done_ad;
wire [7:0] p_en_rmu;
wire [IMG_WIDTH - 1:0] po1x1[0:7];
always @(*) begin
   for(l = 0; l < 8; l = l + 1) begin :loop
        if(p_en[l]) begin
            p1x1 = po1x1[l];
            disable loop;  // stop after first enabled
        end
       else p1x1 = 0;
    end
    case (stride)
        3'd1: begin k1 = 3'd0; k2 = 3'd1; k3 = 3'd2; k4 = 3'd3; k5 = 3'd4; k6 = 3'd5; k7 = 3'd6; k8 = 3'd7; end
        3'd2: begin k1 = 3'd0; k2 = 3'd0; k3 = 3'd3; k4 = 3'd0; k5 = 3'd1; k6 = 3'd2; k7 = 3'd0; k8 = 3'd0; end
        3'd3: begin k1 = 3'd6; k2 = 3'd7; k3 = 3'd0; k4 = 3'd1; k5 = 3'd2; k6 = 3'd3; k7 = 3'd4; k8 = 3'd5; end
        3'd4: begin k1 = 3'd0; k2 = 3'd0; k3 = 3'd0; k4 = 3'd0; k5 = 3'd0; k6 = 3'd0; k7 = 3'd0; k8 = 3'd1; end
        3'd5: begin k1 = 3'd6; k2 = 3'd7; k3 = 3'd0; k4 = 3'd1; k5 = 3'd2; k6 = 3'd3; k7 = 3'd4; k8 = 3'd5; end
        3'd6: begin k1 = 3'd0; k2 = 3'd0; k3 = 3'd3; k4 = 3'd0; k5 = 3'd1; k6 = 3'd2; k7 = 3'd0; k8 = 3'd0; end
        3'd7: begin k1 = 3'd6; k2 = 3'd7; k3 = 3'd0; k4 = 3'd1; k5 = 3'd2; k6 = 3'd3; k7 = 3'd4; k8 = 3'd5; end
        default: begin k1 = 3'd0; k2 = 3'd0; k3 = 3'd0; k4 = 3'd0; k5 = 3'd0; k6 = 3'd0; k7 = 3'd0; k8 = 3'd0; end
    endcase
    clause_act = (!done_seen) && (clause_active[0]||clause_active[1]||clause_active[2]||clause_active[3]||clause_active[4]||clause_active[5]||clause_active[6]||clause_active[7]);
    done = (done_ad[0]||done_ad[1]||done_ad[2]||done_ad[3]||done_ad[4]||done_ad[5]||done_ad[6]||done_ad[7]);
end
processor_en proc_en(clk, rst, patch_size, stride,cycle_detect, p_en, done, p_en_rmu);
addr_gen #(.WIDTH(IMG_WIDTH),.HEIGHT(IMG_HEIGHT)) addr_inst1(
        .clk(clk),.cycle_counts(cycle_counts),.stride(stride),.patch_size(patch_size),.done(done_ad[0]),.done_rmu(done),
        .xcor1(xcor1),.rst(rst),.k(k1),.en(p_en_rmu[0]),.y1(p1y1),.x1(po1x1[0]),.clause_active(clause_active[0]));
addr_gen #(.WIDTH(IMG_WIDTH),.HEIGHT(IMG_HEIGHT)) addr_inst2(
        .clk(clk),.cycle_counts(cycle_counts),.stride(stride),.patch_size(patch_size),.done(done_ad[1]),.done_rmu(done),
        .xcor1(xcor1),.rst(rst),.k(k2),.en(p_en_rmu[1]),.y1(p2y1),.x1(po1x1[1]),.clause_active(clause_active[1]));
addr_gen #(.WIDTH(IMG_WIDTH),.HEIGHT(IMG_HEIGHT)) addr_inst3(
        .clk(clk),.cycle_counts(cycle_counts),.stride(stride),.patch_size(patch_size),.done(done_ad[2]),.done_rmu(done),
        .xcor1(xcor1),.rst(rst),.k(k3),.en(p_en_rmu[2]),.y1(p3y1),.x1(po1x1[2]),.clause_active(clause_active[2]));
addr_gen #(.WIDTH(IMG_WIDTH),.HEIGHT(IMG_HEIGHT)) addr_inst4(
        .clk(clk),.cycle_counts(cycle_counts),.stride(stride),.patch_size(patch_size),.done(done_ad[3]),.done_rmu(done),
        .xcor1(xcor1),.rst(rst),.k(k4),.en(p_en_rmu[3]),.y1(p4y1),.x1(po1x1[3]),.clause_active(clause_active[3]));
addr_gen #(.WIDTH(IMG_WIDTH),.HEIGHT(IMG_HEIGHT)) addr_inst5(
        .clk(clk),.cycle_counts(cycle_counts),.stride(stride),.patch_size(patch_size),.done(done_ad[4]),.done_rmu(done),
        .xcor1(xcor1),.rst(rst),.k(k5),.en(p_en_rmu[4]),.y1(p5y1),.x1(po1x1[4]),.clause_active(clause_active[4]));
addr_gen #(.WIDTH(IMG_WIDTH),.HEIGHT(IMG_HEIGHT)) addr_inst6(
        .clk(clk),.cycle_counts(cycle_counts),.stride(stride),.patch_size(patch_size),.done(done_ad[5]),.done_rmu(done),
        .xcor1(xcor1),.rst(rst),.k(k6),.en(p_en_rmu[5]),.y1(p6y1),.x1(po1x1[5]),.clause_active(clause_active[5]));
addr_gen #(.WIDTH(IMG_WIDTH),.HEIGHT(IMG_HEIGHT)) addr_inst7(
        .clk(clk),.cycle_counts(cycle_counts),.stride(stride),.patch_size(patch_size),.done(done_ad[6]),.done_rmu(done),
        .xcor1(xcor1),.rst(rst),.k(k7),.en(p_en_rmu[6]),.y1(p7y1),.x1(po1x1[6]),.clause_active(clause_active[6]));
addr_gen #(.WIDTH(IMG_WIDTH),.HEIGHT(IMG_HEIGHT)) addr_inst8(
        .clk(clk),.cycle_counts(cycle_counts),.stride(stride),.patch_size(patch_size),.done(done_ad[7]),.done_rmu(done),
        .xcor1(xcor1),.rst(rst),.k(k8),.en(p_en_rmu[7]),.y1(p8y1),.x1(po1x1[7]),.clause_active(clause_active[7]));
       always@(posedge clk)begin
       if(rst)done_seen  <= 0;
       else if(done)done_seen <= 1;
       else done_seen <= done_seen;
       end 
always@(posedge clk)
begin 
if(rst) begin 
    processor_in1 <= 0;
    processor_in2 <= 0;
    processor_in3 <= 0;
    processor_in4 <= 0;
    processor_in5 <= 0;
    processor_in6 <= 0;
    processor_in7 <= 0;
    processor_in8 <= 0;
end else
begin
    if(stride == 1)
    begin
      processor_in1 <= (patch_size == 3) ? {pixel_in[0],pixel_in[1],pixel_in[2]}  :  (((patch_size == 5)||(patch_size == 7)) ? tex(6,stride,patch_size,residues,pixel_in) : 0 );
   
      processor_in2 <= (patch_size == 3) ? tex(1,stride,patch_size,residues ,pixel_in)  : (((patch_size == 5)||(patch_size == 7))? tex(7,stride,patch_size,residues ,pixel_in) : 0 );
                         
      processor_in3 <= (patch_size == 3) ? tex(2,stride,patch_size,residues ,pixel_in)  :  ((patch_size == 5) ? {pixel_in[0],pixel_in[1],pixel_in[2],pixel_in[3],pixel_in[4]} : 
                            (patch_size == 7) ? {pixel_in[0],pixel_in[1],pixel_in[2],pixel_in[3],pixel_in[4],pixel_in[5],pixel_in[6]}  : 0 );
                            
      processor_in4 <= (patch_size == 3) ? tex(3,stride,patch_size,residues ,pixel_in)  :  (((patch_size == 5)||(patch_size == 7)) ? tex(1,stride,patch_size,residues ,pixel_in): 0 );
                            
      processor_in5 <= (patch_size == 3) ? tex(4,stride,patch_size,residues ,pixel_in)  :  (((patch_size == 5)||(patch_size == 7)) ? tex(2,stride,patch_size,residues ,pixel_in) : 0 );
                            
      processor_in6 <= (patch_size == 3) ? tex(5,stride,patch_size,residues ,pixel_in)  :  (((patch_size == 5)||(patch_size == 7)) ? tex(3,stride,patch_size,residues ,pixel_in) : 0 );
                            
      processor_in7  <= (patch_size == 3) ? tex(6,stride,patch_size,residues ,pixel_in)  :  (((patch_size == 5)||(patch_size == 7)) ? tex(4,stride,patch_size,residues ,pixel_in) : 0 );
                            
      processor_in8 <= (patch_size == 3) ? tex(7,stride,patch_size,residues ,pixel_in)  :  (((patch_size == 5)||(patch_size == 7)) ? tex(5,stride,patch_size,residues ,pixel_in) : 0 );
    end
     else if(stride == 2)
    begin
      processor_in1 <= 0;
      processor_in2 <= 0;
      processor_in3 <= (patch_size == 3) ? tex(3,stride,patch_size,residues ,pixel_in)  :  ((patch_size == 5) ? {pixel_in[0],pixel_in[1],pixel_in[2],pixel_in[3],pixel_in[4]} : 
                            (patch_size == 7) ? {pixel_in[0],pixel_in[1],pixel_in[2],pixel_in[3],pixel_in[4],pixel_in[5],pixel_in[6]}  : 0 );
                            
      processor_in4 <= (patch_size == 3) ? {pixel_in[0],pixel_in[1],pixel_in[2]}  :  ((patch_size == 5) || (patch_size == 7))? tex(1,stride,patch_size,residues ,pixel_in)  : 0 ;
                            
      processor_in5 <= (patch_size == 3) ? tex(1,stride,patch_size,residues ,pixel_in)  :  ((patch_size == 5) || (patch_size == 7)) ? tex(2,stride,patch_size,residues ,pixel_in) : 0 ;
                            
      processor_in6 <= (patch_size == 3) ? tex(2,stride,patch_size,residues ,pixel_in)  :  ((patch_size == 5) || (patch_size == 7))? tex(3,stride,patch_size,residues ,pixel_in): 0 ;
      processor_in7 <= 0;
      processor_in8 <= 0;
    end
    else if (stride == 3) 
    begin
      processor_in1 <= ((patch_size == 5)||(patch_size == 7) || (patch_size == 3)) ? tex(6,stride,patch_size,residues ,pixel_in) : 0 ;
                            
      processor_in2 <= ((patch_size == 5)||(patch_size == 7)|| (patch_size == 3))? tex(7,stride,patch_size,residues ,pixel_in)  : 0 ;
                            
      processor_in3 <= (patch_size == 3) ? {pixel_in[0],pixel_in[1],pixel_in[2]} :  ((patch_size == 5) ? {pixel_in[0],pixel_in[1],pixel_in[2],pixel_in[3],pixel_in[4]} : 
                            (patch_size == 7) ? {pixel_in[0],pixel_in[1],pixel_in[2],pixel_in[3],pixel_in[4],pixel_in[5],pixel_in[6]}  : 0 );
                            
      processor_in4 <= ((patch_size == 5)||(patch_size == 7)|| (patch_size == 3)) ? tex(1,stride,patch_size,residues ,pixel_in) : 0 ;
                            
      processor_in5 <= ((patch_size == 5)||(patch_size == 7)|| (patch_size == 3))? tex(2,stride,patch_size,residues ,pixel_in) : 0 ;
                            
      processor_in6 <= ((patch_size == 5)||(patch_size == 7)|| (patch_size == 3)) ? tex(3,stride,patch_size,residues ,pixel_in) : 0 ;
                            
      processor_in7 <= ((patch_size == 5)||(patch_size == 7)|| (patch_size == 3)) ? tex(4,stride,patch_size,residues ,pixel_in) : 0 ;
                            
      processor_in8 <= ((patch_size == 5)||(patch_size == 7)|| (patch_size == 3))? tex(5,stride,patch_size,residues ,pixel_in)  : 0 ;
                            
    end
    else if (stride == 4) 
    begin
      processor_in1 <= 0;
      processor_in2 <= 0;
      processor_in3 <= 0;
      processor_in4 <= 0;
      processor_in5 <= 0;
      processor_in6 <= 0;
      processor_in7 <=  (patch_size == 5) ? {pixel_in[0],pixel_in[1],pixel_in[2],pixel_in[3],pixel_in[4]} : 
                            ((patch_size == 7) ? {pixel_in[0],pixel_in[1],pixel_in[2],pixel_in[3],pixel_in[4],pixel_in[5],pixel_in[6]}: 0 );
                            
      processor_in8 <= ((patch_size == 5) || (patch_size == 7)) ? tex(1,stride,patch_size,residues ,pixel_in) : 0 ;
    end
    else if (stride == 5) 
    begin
      processor_in1 <= (patch_size == 5) ? tex(6,stride,patch_size,residues ,pixel_in) : 
                            ((patch_size == 7) ? tex(7,stride,patch_size,residues ,pixel_in) : 0 );
                            
      processor_in2 <= (patch_size == 5) ? tex(7,stride,patch_size,residues ,pixel_in) : 
                            ((patch_size == 7) ? tex(6,stride,patch_size,residues ,pixel_in) : 0 );
                            
      processor_in3 <= (patch_size == 5) ? {pixel_in[0],pixel_in[1],pixel_in[2],pixel_in[3],pixel_in[4]} : 
                            ((patch_size == 7) ? {pixel_in[0],pixel_in[1],pixel_in[2],pixel_in[3],pixel_in[4],pixel_in[5],pixel_in[6]}  : 0 );
                            
      processor_in4 <= ((patch_size == 5) || (patch_size == 7))? tex(1,stride,patch_size,residues ,pixel_in) : 0 ;
                            
      processor_in5 <= ((patch_size == 5) || (patch_size == 7))? tex(2,stride,patch_size,residues ,pixel_in) : 0 ;
                            
      processor_in6 <= ((patch_size == 5) || (patch_size == 7)) ? tex(3,stride,patch_size,residues ,pixel_in) : 0 ;
                            
      processor_in7 <= ((patch_size == 5) || (patch_size == 7)) ? tex(4,stride,patch_size,residues ,pixel_in) : 0 ;
                            
      processor_in8 <= ((patch_size == 5) || (patch_size == 7)) ? tex(5,stride,patch_size,residues ,pixel_in) : 0 ;
    end
    else if (stride == 6) 
    begin
      processor_in1 <= 0;
      processor_in2 <= 0;
      processor_in3 <= (patch_size == 7) ?  tex(3,stride,patch_size,residues ,pixel_in) : 0 ;
                            
      processor_in4 <= (patch_size == 7) ? {pixel_in[0],pixel_in[1],pixel_in[2],pixel_in[3],pixel_in[4],pixel_in[5],pixel_in[6]}  : 0 ;
                            
      processor_in5 <= (patch_size == 7) ? tex(1,stride,patch_size,residues ,pixel_in) : 0 ;
                            
      processor_in6 <= (patch_size == 7) ? tex(2,stride,patch_size,residues ,pixel_in) : 0 ;
        
      processor_in7 <= 0;
      processor_in8 <= 0;
    end
    else if (stride == 7) 
    begin
      processor_in1 <= (patch_size == 7) ? tex(6,stride,patch_size,residues ,pixel_in) : 0 ;
        
      processor_in2 <= (patch_size == 7) ? tex(7,stride,patch_size,residues ,pixel_in) : 0 ;
        
      processor_in3 <= (patch_size == 7) ? {pixel_in[0],pixel_in[1],pixel_in[2],pixel_in[3],pixel_in[4],pixel_in[5],pixel_in[6]} : 0 ;
                            
      processor_in4 <= (patch_size == 7) ? tex(1,stride,patch_size,residues ,pixel_in) : 0 ;
                            
      processor_in5 <= (patch_size == 7) ? tex(2,stride,patch_size,residues ,pixel_in) : 0 ;
                            
      processor_in6 <= (patch_size == 7) ? tex(3,stride,patch_size,residues ,pixel_in) : 0 ;
        
      processor_in7 <= (patch_size == 7) ? tex(4,stride,patch_size,residues ,pixel_in) : 0 ;
        
      processor_in8 <= (patch_size == 7) ? tex(5,stride,patch_size,residues ,pixel_in) : 0 ;
    end
    else 
    begin
      processor_in1 <= 0;
      processor_in2 <= 0;
      processor_in3 <= 0;
      processor_in4 <= 0;
      processor_in5 <= 0;
      processor_in6 <= 0;
      processor_in7 <= 0;
      processor_in8 <= 0; 
    end
end
end

// function to calculate Tks and return inputs based on patch_size

function [6:0] tex;
input [2:0] k;
input [2:0] s;
input [2:0] patch_size;
input  [5:0]residues;

input [7:0] pixel_in;
reg [6:0]in;
integer i;
integer T,t;
begin

  t = 1 + k*s;
  if(t > 8) T = t % 8;
  else T = t;
  if (patch_size == 3) 
  begin
    in[0] = (T == 7  ) ? residues[1] : ((T == 8  || T %8 == 0)  ) ? residues[0] : (T > 8) ? pixel_in[(T % 8)-1] : pixel_in[T-1];
    
    in[1] = (((T+1) == 8 || (T+1) %8 == 0)  ) ? residues[0] : ((T+1) > 8) ? pixel_in[((T+1) % 8)-1] : pixel_in[(T+1)-1]  ;
    
    in[2] = ((T+2) > 8) ? pixel_in[((T+2) % 8)-1] : pixel_in[(T+2)-1]  ;
    
   /* in[0] = (T == 7  ) ? residues[1] : (T == 8  ) ? residues[0] : (T > 8) ? pixel_in[T % 8] : pixel_in[T];
    in[1] = (((T+1) == 7  ) ? residues[1] : (((T+1) == 8  ) ? residues[0] : ((T+1) > 8) ? pixel_in[(T+1) % 8] : pixel_in[T+1]))  ;
    in[2] = (((T+2) == 7  ) ? residues[1] : (((T+2) == 8  ) ? residues[0] : ((T+2) > 8) ? pixel_in[(T+2) % 8] : pixel_in[T+2]))  ;*/
    in[3] = 0;
    in[4] = 0;
    in[5] = 0;
    in[6] = 0;
  end 
  else if (patch_size == 5) 
  begin
    in[0] = (T == 5  ) ? residues[3] : ((T == 6  ) ? residues[2] :
                (T == 7  ) ? residues[1] : ((T == 8 || T %8 == 0) ) ? residues[0] : ((T > 8) ? pixel_in[(T%8)-1] : pixel_in[T-1]));
                
    in[1] =   (((T+1) == 6  ) ? residues[2] :
                 ((T+1) == 7  ) ? residues[1] : (((T+1) == 8 || (T+1)%8 == 0)  ) ? residues[0] : ((T+1) > 8) ? pixel_in[((T+1) % 8)-1] : pixel_in[(T+1)-1]);

    in[2] = ((T+2) == 7  ) ? residues[1] : ((((T+2) == 8 || (T+2)%8 == 0)  ) ? residues[0] : ((T+2) > 8) ? pixel_in[((T+2) % 8)-1] : pixel_in[(T+2)-1]);
    
    in[3] = (((T+3) == 8 || (T+3)%8 == 0)  ) ? residues[0] :( ((T+3) > 8) ? pixel_in[((T+3) % 8)-1] : pixel_in[(T+3)-1]);
                
    in[4] =  (((T+4) > 8) ? pixel_in[((T+4) % 8)-1] : pixel_in[(T+4)-1]);
                
   /*  in[4] = ((T+4) == 5  ) ? residues[3] : (((T+4) == 6  ) ? residues[2] :
                ((T+4) == 7  ) ? residues[1] : (((T+4) == 8 || (T+4)%8 == 0)  ) ? residues[0] : ((T+4) > 8) ? pixel_in[((T+4) % 8)-1] : pixel_in[(T+4)-1]);
    */            
     in[5] = 0;
     in[6] = 0;
  
  end 
  else if (patch_size == 7) 
  begin
    in[0] = (T == 3  ) ? residues[5] : ((T == 4  ) ? residues[4] :
                (T == 5  ) ? residues[3] : (T == 6  ) ? residues[2] :
                (T == 7  ) ? residues[1] : ((T == 8 || T %8 == 0) ) ? residues[0] : ((T > 8) ? pixel_in[(T%8)-1] : pixel_in[T-1]));
     
    in[1] = (((T+1) == 4  ) ? residues[4] :
                ((T+1) == 5  ) ? residues[3] : ((T+1) == 6  ) ? residues[2] :
                ((T+1) == 7  ) ? residues[1] : (((T+1) == 8 || (T+1)%8 == 0) ) ? residues[0] : ((T+1) > 8) ? pixel_in[((T+1) % 8)-1] : pixel_in[(T+1)-1]);
  
    in[2] = ((T+2) == 5  ) ? residues[3] :( ((T+2) == 6  ) ? residues[2] :
                ((T+2) == 7  ) ? residues[1] : (((T+2) == 8 || (T+2)%8 == 0) ) ? residues[0] : ((T+2) > 8) ? pixel_in[((T+2) % 8)-1] : pixel_in[(T+2)-1]);
                
    in[3] =   ((T+3) == 6  ) ? residues[2] :
                (((T+3) == 7  ) ? residues[1] : (((T+3) == 8 || (T+3)%8 == 0) ) ? residues[0] : ((T+3) > 8) ? pixel_in[((T+3) % 8)-1] : pixel_in[(T+3)-1]);
                
                
    in[4] =  (((T+4) == 7  ) ? residues[1] : (((T+4) == 8 || (T+4)%8 == 0) ) ? residues[0] : ((T+4) > 8) ? pixel_in[((T+4) % 8)-1] : pixel_in[(T+4)-1]);
    
    in[5] = (((T+5) == 8 || (T+5)%8 == 0) ) ? residues[0] : ((T+5) > 8) ? pixel_in[((T+5) % 8)-1] : pixel_in[(T+5)-1];
    
    in[6] = ((T+6) > 8) ? pixel_in[((T+6) % 8)-1] : pixel_in[(T+6)-1];
  
  /*   in[0] = (T == 3  ) ? residues[5] : ((T == 4  ) ? residues[4] :
                (T == 5  ) ? residues[3] : (T == 6  ) ? residues[2] :
                (T == 7  ) ? residues[1] : (T == 8  ) ? residues[0] : ((T > 8) ? pixel_in[T%8] : pixel_in[T]));
     
     in[1] = ((T+1) == 3  ) ? residues[5] : (((T+1) == 4  ) ? residues[4] :
                ((T+1) == 5  ) ? residues[3] : ((T+1) == 6  ) ? residues[2] :
                ((T+1) == 7  ) ? residues[1] : ((T+1) == 8  ) ? residues[0] : ((T+1) > 8) ? pixel_in[(T+1) % 8] : pixel_in[T+1]);
  
     in[2] = ((T+2) == 3  ) ? residues[5] : (((T+2) == 4  ) ? residues[4] :
                ((T+2) == 5  ) ? residues[3] : ((T+2) == 6  ) ? residues[2] :
                ((T+2) == 7  ) ? residues[1] : ((T+2) == 8  ) ? residues[0] : ((T+2) > 8) ? pixel_in[(T+2) % 8] : pixel_in[T+2]);
                
     in[3] = ((T+3) == 3  ) ? residues[5] : (((T+3) == 4  ) ? residues[4] :
                ((T+3) == 5  ) ? residues[3] : ((T+3) == 6  ) ? residues[2] :
                ((T+3) == 7  ) ? residues[1] : ((T+3) == 8  ) ? residues[0] : ((T+3) > 8) ? pixel_in[(T+3) % 8] : pixel_in[T+3]);
                
                
     in[4] = ((T+4) == 3  ) ? residues[5] : (((T+4) == 4  ) ? residues[4] :
                ((T+4) == 5  ) ? residues[3] : ((T+4) == 6  ) ? residues[2] :
                ((T+4) == 7  ) ? residues[1] : ((T+4) == 8  ) ? residues[0] : ((T+4) > 8) ? pixel_in[(T+4) % 8] : pixel_in[T+4]);
    
     in[5] = ((T+5) == 3  ) ? residues[5] : (((T+5) == 4  ) ? residues[4] :
                ((T+5) == 5  ) ? residues[3] : ((T+5) == 6  ) ? residues[2] :
                ((T+5) == 7  ) ? residues[1] : ((T+5) == 8  ) ? residues[0] : ((T+5) > 8) ? pixel_in[(T+5) % 8] : pixel_in[T+5]);
    
     in[6] = ((T+6) == 3  ) ? residues[5] : (((T+6) == 4  ) ? residues[4] :
                ((T+6) == 5  ) ? residues[3] : ((T+6) == 6  ) ? residues[2] :
                ((T+6) == 7  ) ? residues[1] : ((T+6) == 8  ) ? residues[0] : ((T+6) > 8) ? pixel_in[(T+6) % 8] : pixel_in[T+6]);
*/
  end
  else in = 7'b0;

    tex = in; 


  end
endfunction

/*
initial begin
    out= tex(7,5,7,6'b101011,3,8'b11100010);

end  */

endmodule
