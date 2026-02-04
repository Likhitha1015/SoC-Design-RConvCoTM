module weight_adder #(
    parameter CLAUSEN = 140
)(
    input clk,
    input rst,
    input valid,
    input [255:0] weight_write,
    input [31:0] offset,
    input [$clog2(CLAUSEN):0] clauses,
    input [$clog2(CLAUSEN):0] clause_no,
    output reg signed [8:0] weight
);

    reg [1279:0] dout;
    reg [$clog2(CLAUSEN*9)-1:0] idx;
    reg signed [8:0] wt;
    // Write logic
    always @(posedge clk) begin
        if (rst) begin
            dout <= 0;
        end 
        else if (valid) begin
            case (offset)
                3'd0: dout[255:0]      <= weight_write;
                3'd1: dout[511:256]    <= weight_write;
                3'd2: dout[767:512]    <= weight_write;
                3'd3: dout[1023:768]   <= weight_write;
                3'd4: dout[1279:1024]  <= weight_write;
            endcase
        end
    end

    // Address pipeline
    always @(posedge clk) begin
        idx <= (clauses - clause_no - 1) * 9;
    end

    // Read pipeline
    always @(posedge clk) begin
if (rst) begin
            wt <= 0;
            weight <= 0;
end
else begin
    wt <= dout[idx +: 9];
    weight <= wt;
end
    end

endmodule
