//reg [1:0] x;
reg [4:0] x;

wire [2:0] y;

wire a;
wire b;

integer ctr;

always @(posedge clock.val) begin
    ctr <= ctr + 1;
    if (ctr > 10)
      $finish(1);
end


assign y = x;
assign a = x[0];
assign b = x[1];

initial begin
    //x <= 2'b01;
    x <= 5'b10110;
end

always @(posedge clock.val) begin
    $display("x: %d, y: %d, a: %d, b: %d", x, y, a, b);
end

