// Code your testbench here
// or browse Examples
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/12/2022 05:13:45 PM
// Design Name: 
// Module Name: FP_Div_Test
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

module booth_test;

reg [31:0] A, B;
wire DONE;
wire [31:0] result;
shortreal value; 
shortreal valueA, valueB;
real EPSILON=0.0001;
real error;  
  
integer i, fail=0, pass=0;
fpdiv tester( result, A, B);


initial  
begin

// CORNER CASES
A = 32'h3F28F5C3;  // 0.66
B = 32'h3F028F5C;  // 0.51

#15
  value =$bitstoshortreal(result);
$display("Expected Value : %f Result : %f",0.66/0.51,value);







// GENRAL CASES
  for(i =0 ; i < 500; i=i+1) begin
#100
  valueA = $random;
  valueB = $random;
  A =$shortrealtobits(valueA);
  B =$shortrealtobits(valueB);
  #15
  value =$bitstoshortreal(result);
  error = (value - (valueA/valueB));
  error = error < 0 ? -error : error;
  
  
    if( error < EPSILON ) begin
   
    $display("Passed for A = %f and B = %f, expected : %f got : %f",valueA,valueB,valueA/valueB,value);
  	pass = pass + 1;
    end

  else begin
    $display("Failed for A = %f and B = %f, expected : %f got : %f",valueA,valueB,valueA/valueB,value);
  	fail = fail + 1;
end
end	
  $display("No. of Passes = %f and No. of Fails = %f",pass,fail);
	
end


endmodule
