`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/12/2022 03:12:52 PM
// Design Name: 
// Module Name: FP_Divide
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



module FP_Divider
    (
     input   [31:0]  A,
     input   [31:0]  B,
     output  reg [31:0]  C
    );
    
    
    /*
                            Data Width = 32,
                            Exponent Width = 8,
                            Mantissa Width = 23,
                            Dividend_Data_Width = 47,
                            Divisor_Data_Width = 24
    */

logic [15:0] softfloat_approxRecip_1k0s[15:0] = {
    16'hFFC4, 16'hF0BE, 16'hE363, 16'hD76F, 16'hCCAD, 16'hC2F0, 16'hBA16, 16'hB201,
    16'hAA97, 16'hA3C6, 16'h9D7A, 16'h97A6, 16'h923C, 16'h8D32, 16'h887E, 16'h8417};

logic [15:0] softfloat_approxRecip_1k1s[15:0] = {
    16'hF0F1, 16'hD62C, 16'hBFA1, 16'hAC77, 16'h9C0A, 16'h8DDB, 16'h8185, 16'h76BA,
    16'h6D3B, 16'h64D4, 16'h5D5C, 16'h56B1, 16'h50B6, 16'h4B55, 16'h4679, 16'h4211};



logic [4:0] softfloat_countLeadingZeros8[ 255:0 ] = {
    8, 7, 6, 6, 5, 5, 5, 5, 4, 4, 4, 4, 4, 4, 4, 4,
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
};








        reg signA ;             // 1 bit sign
        reg [7:0]  expA;  // [30:23] 8 bit exponent
        reg [23:0] sigA;   // 24 bit mantissa
        
        reg signB ;             // 1 bit sign
        reg [7:0]  expB;  // [30:23] 8 bit exponent
        reg [23:0] sigB;   // 24 bit mantissa
        
        
        reg signZ = signA ^ signB; // sign of result
        reg [7:0] expZ;
        reg [23:0] sigZ;
        /*------------------------------------------------------------------------
        *------------------------------------------------------------------------*/
        //reg [63:0] sig64A;   
        reg [63:0] rem=0;   
         
        reg [63:0] sigR;              
        reg [31:0] shiftCount;
        reg [31:0] count;
        reg [4:0] index;
        reg [31:0] eps, r0;
        reg [31:0] sigma0;
        reg [31:0] sqrSigma0;
  
        /*------------------------------------------------------------------------
        *------------------------------------------------------------------------*/
                
        always_comb begin
        
        signA = A[31];             // 1 bit sign
        expA  = A[30:23];  // [30:23] 8 bit exponent
        sigA  = A[23:0];   // 24 bit mantissa
        
        signB = B[31];             // 1 bit sign
        expB  = B[30:23];  // [30:23] 8 bit exponent
        sigB  = B[23:0];   // 24 bit mantissa
                
                
        signZ = signA ^ signB; // sign of result
                        
        
        if ( expA == 8'hFF )
        begin
            if ( sigA != 0 ) C = 32'h7fc00000;            // assign defaultNaNF32UI goto propagateNaN;
            if ( expB == 8'hFF )
            begin
                if ( sigB != 0 ) C = 32'h7fc00000;       // assign defaultNaNF32UI goto propagateNaN;
                
                C = 32'h7fc00000;                   // assign defaultNaNF32UI goto invalid;
            end
            C = {signZ, 8'hFF, 23'b000_0000_0000_0000_0000_0000};  // goto infinity;
        end
        
        
        if ( expB == 8'hFF )
        begin
            if ( sigB != 0 ) C = 32'h7fc00000;       // assign defaultNaNF32UI goto propagateNaN;
            C = {signZ, 8'h00, 23'b000_0000_0000_0000_0000_0000}; // assign zero goto zero;
        end
        /*------------------------------------------------------------------------
        *------------------------------------------------------------------------*/
        if ( expB == 0 )
        begin
            if ( ! (sigB == 0) )
            begin
                if ( ! (expA == 0  | sigA) ) C = 32'h7fc00000;          // assign defaultNaNF32UI goto invalid;
                // softfloat_raiseFlags( softfloat_flag_infinite );
                C = {signZ, 8'hFF, 23'b000_0000_0000_0000_0000_0000};  // assign infinity; goto infinity;
            end
            
         
             count = 0;
             if ( sigB < 'h10000 )
             begin
                 count = 16;
                 sigB = sigB << 16;
             end
             
             if ( sigB < 'h1000000 )
             begin
                 count = count + 8;
                 sigB = sigB << 8;
             end
             count = count + softfloat_countLeadingZeros8[sigB>>24];

            
            shiftCount = count - 8;
                        
            expB        = 1 - shiftCount;
            sigB    = sigB<<shiftCount;

            
            //softfloat_normSubnormalF32Sig M1( sigB, expB, sigB );
        end
        
        if ( ! (expA == 0) )
        begin
            if ( ! sigA ) C = {signZ, 8'h00, 23'b000_0000_0000_0000_0000_0000}; // assign zero goto zero;
            
            //softfloat_normSubnormalF32Sig( sigA, expA, sigA );


             count = 0;
             if ( sigA < 'h10000 )
             begin
                 count = 16;
                 sigA = sigA << 16;
             end
             
             if ( sigA < 'h1000000 )
             begin
                 count = count + 8;
                 sigA = sigA << 8;
             end
             count = count + softfloat_countLeadingZeros8[sigA>>24];

            
            shiftCount = count - 8;
            expA        = 1 - shiftCount;
            sigA        = sigA<<shiftCount;

        end
        
        
        /*------------------------------------------------------------------------
        *------------------------------------------------------------------------*/
        
        
        expZ = expA - expB + 8'h7E;

        sigA = sigA | 32'h00800000;
        sigB = sigB | 32'h00800000;


/* #ifdef SOFTFLOAT_FAST_DIV64TO32
        if ( sigA < sigB )
        begin
            assign expZ = expZ - 1;
            assign sig64A = sigA<<31;
        end 
        else
            assign sig64A =  sigA<<30;
 
 
        sigZ = sig64A / sigB;
        
        
        if ( ! (sigZ & 8'h3F) ) 
            sigZ = sigZ | ( sigB * sigZ != sig64A);
    
    #else
    begin
    */
        if ( sigA < sigB )
        begin
            expZ = expZ -1;
            sigA = sigA << 8;
        end
        else
            sigA = sigA << 7;
            
        sigB = sigB << 8;
       // softfloat_approxRecip32_1( sigB, sigR );
        index = sigB>>27 & 4'hF;
        eps = sigB>>11;
        r0 = softfloat_approxRecip_1k0s[index] - ((softfloat_approxRecip_1k1s[index] * eps)>>20);
        sigma0 = ~(r0 * sigB)>>7;
        sigR = (r0<<16) + ((r0 * sigma0)>>24);
        sqrSigma0 = (sigma0 * sigma0)>>32;
        sigR = sigR + (sigR * sqrSigma0)>>48;

        
        
        
        
        sigZ = sigA * sigR>>32;
        /*------------------------------------------------------------------------
        *------------------------------------------------------------------------*/
        sigZ = sigZ + 2;
        if ( (sigZ & 8'h3F) < 2 )
        begin
            sigZ = sigZ & ~3;
            
    //#ifdef SOFTFLOAT_FAST_INT64
    //        rem = ((uint_fast64_t) sigA<<31) - (uint_fast64_t) sigZ * sigB;
    //#else
    rem = ( sigA<<32) -  (sigZ<<1) * sigB;
    //#endif
    if ( rem & ( 64'h8000000000000000 ) )
    begin
        sigZ = sigZ - 4;
    end 
    else
    begin
      if ( rem ) sigZ = sigZ | 1;
    end
    
    
    end
    //#endif
        C =  {signZ, expZ, sigZ};
        /*------------------------------------------------------------------------
        *------------------------------------------------------------------------*/

    end
endmodule