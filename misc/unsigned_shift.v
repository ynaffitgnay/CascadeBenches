wire[31:0] a,b,c,d,e;

assign a = (32 - 200) % 32;
assign b = (32 - 17) % 32;
assign c = (a > 32) ? a % 32 : a;
assign d = b % 32;
assign e = (b > 32) ? b % 32 : b;

initial begin
   $display("%d,%d,%d,%d,%d", a,b,c,d,e);
end
  