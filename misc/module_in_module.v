module mod_in_mod();
  reg [2:0] x;

  include inner_module.v;
  
endmodule // hello

mod_in_mod mim();

