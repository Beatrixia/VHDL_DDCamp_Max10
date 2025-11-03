-------------------------------------------------------------------------------------------------------
-- Copyright (c) 2017, Design Gateway Co., Ltd.
-- All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without modification,
-- are permitted provided that the following conditions are met:
-- 1. Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- 2. Redistributions in binary form must reproduce the above copyright notice,
-- this list of conditions and the following disclaimer in the documentation
-- and/or other materials provided with the distribution.
--
-- 3. Neither the name of the copyright holder nor the names of its contributors
-- may be used to endorse or promote products derived from this software
-- without specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
-- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
-- IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
-- INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
-- PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
-- HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
-- OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
-- EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
-- Filename     Tb.vhd
-- Title        Tb
--
-- Company      Design Gateway Co., Ltd.
-- Project      
-- PJ No.       
-- Syntax       VHDL
-- Note         

-- Version      1.00
-- Author       U.Patheera
-- Date         2018/12/17
-- Remark       New Creation
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
USE STD.TEXTIO.ALL;

Entity Tb Is
End Entity Tb;

Architecture HTWTestBench Of Tb Is

--------------------------------------------------------------------------------------------
-- Constant Declaration
--------------------------------------------------------------------------------------------

	constant	tClk			: time := 10 ns;
	
-------------------------------------------------------------------------
-- Component Declaration
-------------------------------------------------------------------------
-- Ex
--	Component Comp Is
--	Port 
--	(
--		RstB		: in	std_logic;
--		Clk			: in	std_logic;	
--	);
--	End Component Par2Ser;
	
-------------------------------------------------------------------------
-- Signal Declaration
-------------------------------------------------------------------------
	
	signal	TM			: integer	range 0 to 65535;
	signal	TT			: integer	range 0 to 65535;

-- Ex
--	signal	RstB		: std_logic;
--	signal	Clk			: std_logic;		

Begin

----------------------------------------------------------------------------------
-- Concurrent signal
----------------------------------------------------------------------------------
	
	u_Clk : Process
	Begin
		Clk		<= '1';
		wait for tClk/2;
		Clk		<= '0';
		wait for tClk/2;
	End Process u_Clk;
	
	u_Par2Ser : Par2Ser
	Port map
	( 
		RstB		=> RstB		,		
		Clk			=> Clk		,	

		ParLoad		=> ParLoad	,		
		ParDataIn	=> ParDataIn,	
		
		EnShift		=> EnShift	,
		SerOut		=> SerOut		
	);
	
-------------------------------------------------------------------------
-- Testbench
-------------------------------------------------------------------------

	u_Test : Process
	Begin
		-------------------------------------------
		-- TM=0 : Reset and Initial Value
		-------------------------------------------
		TM <= 0; TT <= 0; wait for 1 ns;
		Report "TM=" & integer'image(TM) & " TT=" & integer'image(TT); 
		RstB		<= '0';
		ParLoad		<= '0';
		ParDataIn	<= x"00";
		EnShift		<= '0';
		wait for 16*tClk;
		RstB		<= '1';

		-------------------------------------------
		-- TM=1 : Test Load value feature
		-------------------------------------------	
		TM <= 1; TT <= 0; wait for 1 ns;
		Report "TM=" & integer'image(TM) & " TT=" & integer'image(TT); 
				
		-- Load input
		ParLoad		<= '1';
		ParDataIn	<= x"9A";
		wait until rising_edge(Clk);
		wait for 15*tClk;
		ParLoad		<= '0';
		ParDataIn	<= x"00";
		
		wait for 15*tClk;

		-------------------------------
		-- ParDataIn change, but ParLoad='0' 
		TT <= 1; wait for 1 ns;
		Report "TM=" & integer'image(TM) & " TT=" & integer'image(TT); 
		
		-- Load input
		ParLoad		<= '0';
		ParDataIn	<= x"9A";
		wait until rising_edge(Clk);
		wait for 15*tClk;
		ParDataIn	<= x"00";
		
		wait for 10*tClk;

		-------------------------------------------
		-- TM=2 : Test shift function
		-------------------------------------------	
		TM <= 2; TT <= 0; wait for 1 ns;
		Report "TM=" & integer'image(TM) & " TT=" & integer'image(TT); 
		
		-- Shift one cycle every 2 cycles (run 4 times)
		For i in 0 to 3 Loop
			EnShift		<= '1';
			wait until rising_edge(Clk);
			wait for 15*tClk;
			EnShift		<= '0';
			wait until rising_edge(Clk);
			wait for 15*tClk;
		End loop;
		
		wait for 15*tClk;
		
		-------------------------------
		-- Shift 5 time continuously (5th clock is filled by 0, not data)
		TT <= 1; wait for 1 ns;
		Report "TM=" & integer'image(TM) & " TT=" & integer'image(TT); 
		
		EnShift		<= '1';
		For i in 0 to 3 Loop
			wait until rising_edge(Clk);
			wait for 15*tClk;
		End loop;
		EnShift		<= '0';
		wait until rising_edge(Clk);
		
		wait for 15*tClk;
		
		-------------------------------------------
		-- TM=3 : Generate signal with output condition
		-------------------------------------------	
		TM <= 3; TT <= 0; wait for 1 ns;		
		Report "TM=" & integer'image(TM) & " TT=" & integer'image(TT); 

		-- Load and shift continuously 
		ParLoad		<= '1';
		ParDataIn	<= x"57";
		wait until rising_edge(Clk);
		ParLoad		<= '0';
		ParDataIn	<= x"00";
		EnShift		<= '1';
		For i in 0 to 7 Loop
			wait until rising_edge(Clk);
			wait for 15*tClk;
		End loop;
		EnShift		<= '0';
		wait until rising_edge(Clk);
		
		wait for 15*tClk;
		
		-- Load -> shift 4 -> Load -> shift 9 
		TT <= 1; wait for 1 ns;
		Report "TM=" & integer'image(TM) & " TT=" & integer'image(TT); 
		
		ParLoad		<= '1';
		ParDataIn	<= x"E9";
		wait until rising_edge(Clk);
		wait for 15*tClk;
		ParLoad		<= '0';
		ParDataIn	<= x"00";
		EnShift		<= '1';
		For i in 0 to 3 Loop
			wait until rising_edge(Clk);
			wait for 15*tClk;
		End loop;
		ParLoad		<= '1';
		ParDataIn	<= x"66";
		wait until rising_edge(Clk);
		wait for 15*tClk;
		ParLoad		<= '0';
		ParDataIn	<= x"00";
		For i in 0 to 7 Loop
			wait until rising_edge(Clk);
			wait for 15*tClk;
		End loop;
		
		wait for 16*tClk;

		--------------------------------------------------------
		TM <= 255; wait for 1 ns;
		wait for 20*tClk;
		Report "##### End Simulation #####" Severity Failure;		
		wait;
		
	End Process u_Test;

End Architecture HTWTestBench;
