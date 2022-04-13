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
reg DONE;
reg [1:0] EXCEPTION;
reg [31:0] result;
real value;
fpdiv tester( result, DONE, EXCEPTION, A, B);




initial  
begin
A = 32'b0_01111110_01010001111010111000010;  // 0.66
B = 32'b0_01111110_00000101000111101011100;  // 0.51
#200
A = 32'b0_10000001_00001100110011001100110;  // 4.2 
B = 32'b0_10000000_10011001100110011001101;  // 3.2
#200
A = 32'hC0CCCCCD;                               // -6.4 
B = 32'hBF000000;                               // -0.5
#200
A = 32'h40CCCCCD;                               // 6.4
B = 32'hBF000000;                               // -0.5
#200
A = 32'h4034b4b5; //2.82
B = 32'h3f70f0f1; //0.94
end



initial
begin
#150
value =(2**(result[30:23]-127))*($itor({1'b1,result[22:0]})/2**23)*((-1)**(result[31]));
$display("Expected Value : %f Result : %f",0.66/0.51,value);
#200
value =(2**(result[30:23]-127))*($itor({1'b1,result[22:0]})/2**23)*((-1)**(result[31]));
$display("Expected Value : %f Result : %f",4.2/3.2,value);
#200
value =(2**(result[30:23]-127))*($itor({1'b1,result[22:0]})/2**23)*((-1)**(result[31]));
$display("Expected Value : %f Result : %f",(-6.4)/(-0.5),value);
#200
value =(2**(result[30:23]-127))*($itor({1'b1,result[22:0]})/2**23)*((-1)**(result[31]));
$display("Expected Value : %f Result : %f",6.4/(-0.5),value);
#200
value =(2**(result[30:23]-127))*($itor({1'b1,result[22:0]})/2**23)*((-1)**(result[31]));
$display("Expected Value : %f Result : %f",2.82/0.94,value);
$finish;
end


endmodule
