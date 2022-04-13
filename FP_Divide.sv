`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/12/2022 09:39:13 PM
// Design Name: 
// Module Name: FP_div
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


module get_sign(A, B, sign); // this is to get the sign of the output
  input A, B;
  output sign;

  xor(sign,A,B);
endmodule
//This is now directly implemented in the division module
//module get_exp(A,B, exp);// this is to get the exponent of the result. depending on the division of the mantissa this value will be altered
//  input [7:0] A, B;
//  output [7:0]exp;
//  assign exp = A - B +8'd127; // we subract 127 because exponents are stored in excess 128 form.
//endmodule

module division (i_divisor, i_dividend, result, done, expo, except, expA, expB);
  //reg [23:0];
  input wire [7:0] expA, expB;
  input [31:0]i_dividend, i_divisor;
  reg [23:0]quotient=0;
  reg [7:0]exponent_diff = 8'd0;
  output reg [7:0]expo=0;
  reg first_bit = 1'b0;
  output reg done = 1'b0;
  output reg [22:0]result=0;
  output reg [1:0]except=0;
  reg [32:0] dividend=0, divisor=0;

  always @ ( i_divisor, i_dividend, expA, expB) begin 
    dividend = i_dividend;
    divisor = i_divisor;
    done = 0;
    quotient=0;
    exponent_diff = 0;
    first_bit = 0;
    except=0;
    
    
    
    
    if (divisor[31:0] == 32'b0 && expB[7:0] == 8'b0 && done == 1'b0) begin
      except = 2'b00;
      done = 1'b1;
      result = 23'b0;
      expo = 8'b0;
    end
    if (dividend[31:0] == 32'b0 && expA[7:0] == 8'b0 && done == 1'b0) begin
      result = 23'b0;
      expo = 8'b0;
      done = 1'b1;
    end
    if(done == 1'b0) begin
      while (quotient[23] != 1'b1) begin
        if (dividend >= divisor) begin
          dividend = dividend - divisor;    // here we just subtract the divisor from the dividend and shift the dividend left.
          dividend = dividend << 1;
          quotient = {quotient[22:0], 1'b1}; // this is to shift the quotient left and add 1 to the lsb.
          if (first_bit == 1'b0) begin
            first_bit = 1'b1;
          end
        end else begin
          dividend = dividend << 1;
          quotient = {quotient[22:0], 1'b0};
          if (first_bit == 1'b0) begin             //until we get the first bit i.e. the first time the divisor is less than the dividend the exponent value will decrease
            exponent_diff = exponent_diff + 1;
          end
        end

        if (dividend[31:0] == 32'b0 && done == 1'b0) begin
          while (quotient[23] != 1'b1) begin
            quotient = quotient << 1;
            if(first_bit == 1'b0) begin           // if we haven got a first_bit by now give output 0.
              result = 23'b0;
              expo = 8'b0;
              done = 1'b1;
              //break;
            end
          end
        end
      end
      if (done == 1'b0) begin
        expo = expA - expB +8'd127;
        //get_exp exp_out (.A(expA), .B(expB), .exp(expo));
        expo = expo - exponent_diff;
        if (expo[7] == 0 && expA >= 128 && expB < 128) begin
          done = 1'b1;
          except = 2'b10;
        end else if (expo[7] == 1 && expA < 128 && expB >= 128) begin
          done = 1'b1;
          except = 2'b01;
        end
        if (quotient[23] == 1) begin
          result = quotient[22:0];
          done = 1'b1;
        end
      end
    end
  end


endmodule // division

//This module is the main module where all the sub modules will be included

module fpdiv(AbyB, DONE, EXCEPTION, InputA, InputB);
input [31:0] InputA, InputB;
output [31:0] AbyB;
output DONE;
output [1:0] EXCEPTION;
wire [7:0]  expAbyB;
wire [22:0]  mantAbyB;
reg  signAbyB;
wire [32:0] temp_divisor, temp_dividend;
assign temp_divisor = {1'b1,InputB[23:0],7'd0};
assign temp_dividend = {1'b1,InputA[23:0],7'd0};
get_sign s_out (.A(InputA[31]), .B(InputB[31]), .sign(signAbyB));
division divide (.i_divisor({1'b1,InputB[22:0],8'd0}), 
                 .i_dividend({1'b1,InputA[22:0],8'd0}), 
                 .result(mantAbyB), .done(DONE), 
                 .expo(expAbyB), .except(EXCEPTION), 
                 .expA(InputA[30:23]), .expB(InputB[30:23]));
assign AbyB = {signAbyB,expAbyB,mantAbyB};

endmodule
