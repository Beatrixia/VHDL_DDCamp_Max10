----------------------------------------------------------------------------------
-- TimingDiagram code for wavedrom
[
  {name: 'Clk',					wave: 'P.....|.|.|.|.|.|.|.|.|......' ,		period: 1}	,
  {								node: '.....AB.C.D.E.F.G.H.I.J.K....' ,		phase: 0.15}	,
  {name: 'RxFfFull',			wave: '1.....|.|.|.|.|.|.|.|.|0.....' }	,
  {name: 'SerDataIn',			wave: '1....0|1|0|1|0|1|.|0|.|1.....' }	,
  {name: 'RxFfWrEn',			wave: '0.....|.|.|.|.|.|.|.|.|.1.0..' }	,
  {name: 'RxFfWrData',			wave: 'x.....|.|.|.|.|.|.|.|.|.2.2..' ,		data : "0x35" }	,
  {name: 'rDataCnt',			wave: '2.....2.2.2.2.2.2.2.2.2.2....' , 	data : " 9 8 7 6 5 4 3 2 1 0 9" }	,
  {name: 'rBaudEn',				wave: '0....1|.|.|.|.|.|.|.|.|.0....' , }	,
  {name: 'rBaudCnt',			wave: '2....22.2.2.2.2.2.2.2.2.2....' ,		phase: 0.2	, 	data : " half count full full full full full full full full full half" }	,
 ] ,
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

Entity RxSerial Is
Generic
	(
		gMainClk		: integer := 100000000;
		gBaudRate		: integer := 115200
	);
Port
	(
		RstB		: in	std_logic;
		Clk			: in	std_logic;
		
		SerDataIn	: in	std_logic;
		
		RxFfFull	: in	std_logic;
		RxFfWrData	: out	std_logic_vector( 7 downto 0 );
		RxFfWrEn	: out	std_logic
	);
End Entity RxSerial;

Architecture rtl Of RxSerial Is

----------------------------------------------------------------------------------
-- Constant declaration
----------------------------------------------------------------------------------

	constant cBaudCnt		: integer := ( gMainClk/gBaudRate ) - 1;
	constant cHalfBaudCnt	: integer := ( cBaudCnt/2 ) - 3;
	-- cHalfBaudCnt normally we usually -1 to counting write but -3 be cause we has delay
	constant cDataCnt		: integer := 9;

----------------------------------------------------------------------------------
-- Signal declaration
----------------------------------------------------------------------------------
	
	signal	rSerDataIn		: std_logic_vector( 1 downto 0 );
	
	signal	rRxFfWrData		: std_logic_vector( 7 downto 0 );
	signal	rRxFfWrEn		: std_logic;
	signal	rRxFfFull		: std_logic;
	
	signal	rBaudCnt		: integer range 0 to cBaudCnt;
	signal	rBaudTrig		: std_logic;
	signal	rBaudEn			: std_logic;
	
	signal	rDataCnt		: integer range 0 to cDataCnt;
Begin

----------------------------------------------------------------------------------
-- Output assignment
----------------------------------------------------------------------------------
	
	RxFfWrData		<= rRxFfWrData;
	RxFfWrEn		<= rRxFfWrEn;
	
----------------------------------------------------------------------------------
-- DFF 
----------------------------------------------------------------------------------
	
	-- meta stability for SerDataIn
	u_rSerDataIn : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			rSerDataIn(1)		<= rSerDataIn(0);
			rSerDataIn(0)		<= SerDataIn;
		end if;
	End Process u_rSerDataIn;
	
	-- baud enabler
	u_rBaudEn : Process (Clk ,rBaudTrig ,rSerDataIn) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rBaudEn		<= '0';
			else
				if ( rDataCnt=9 and rSerDataIn(1)='0' ) then
					rBaudEn		<= '1';
				elsif ( rDataCnt=0 and rBaudTrig='1' ) then
					rBaudEn		<= '0';
				else
					rBaudEn		<= rBaudEn;
				end if;
			end if;
		end if;
	End Process u_rBaudEn;
	
	-- Cnting baudrate to trig baudtrig
	u_rBaudCnt : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rBaudCnt		<= cHalfBaudCnt;
			else
				if ( rBaudEn='1' ) then
					if ( rBaudCnt=0 ) then
						rBaudCnt		<= cBaudCnt;
					else
						rBaudCnt		<= rBaudCnt - 1;
					end if;
				else
					rBaudCnt		<= cHalfBaudCnt;
				end if;
			end if;
		end if;
	End Process u_rBaudCnt;

	-- baudtrig 
	u_rBaudTrig : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rBaudTrig		<= '0';
			else
				if ( rBaudCnt=0 ) then
					rBaudTrig		<= '1';
				else
					rBaudTrig		<= '0';
				end if;
			end if;
		end if;
	End Process u_rBaudTrig;
	
	-- store data
	u_rRxFfWrData : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rRxFfWrData		<= (others=>'1');
			else
				if ( rBaudTrig='1' and rDataCnt>0 ) then
					rRxFfWrData		<= rSerDataIn(1) & rRxFfWrData( 7 downto 1 );
				else
					rRxFfWrData		<= rRxFfWrData;
				end if;
			end if;
		end if;
	End Process u_rRxFfWrData;
	
	-- meta stability for RxFfFull
	u_rRxFfFull : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			rRxFfFull		<= RxFfFull;
		end if;
	End Process u_rRxFfFull;
	
	-- rRxFfWrEn use to send flag when data in is done
	u_rRxFfWrEn : Process (Clk)
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rRxFfWrEn		<= '0';
			else
				if ( rDataCnt=0 and rRxFfFull='0' and  rSerDataIn(1)='1' and rBaudTrig='1') then
					rRxFfWrEn		<= '1';
				else
					rRxFfWrEn		<= '0';
				end if;
			end if;
		end if;
	End Process u_rRxFfWrEn;
	
	u_rDataCnt : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0') then
				rDataCnt		<= cDataCnt;
			else
				if ( rBaudTrig='1' or (rDataCnt=0 and rBaudEn='0') )then
					if ( rDataCnt=0 ) then
						if ( rSerDataIn(1)='1' ) then
							rDataCnt 		<= cDataCnt;
						else
							rDataCnt 		<= rDataCnt;
						end if;
					else
						rDataCnt 		<= rDataCnt - 1;
					end if;
				end if;
			end if;
		end if;
	End Process u_rDataCnt;
	
End Architecture rtl;
