----------------------------------------------------------------------------------
-- Timing Diagram (App WaveDrom)
-- [
--   {name: 'Clk',					wave: 'P.....|.|.|.|.|.|.|.|.|......' , period: 1}	,
--   {name: 'RxFfFull',			wave: '1.....|.|.|.|.|.|.|.|.|0.....' }	,
--   {name: 'SerDataIn',			wave: '1....0|1|0|1|0|1|.|0|.|1.....' }	,
--   {name: 'RxFfWrEn',			wave: '0.....|.|.|.|.|.|.|.|.|.1.0..' }	,
--   {name: 'RxFfWrData',			wave: 'x.....|.|.|.|.|.|.|.|.|.2.2..' , 	data : "35h" }	,
--   {name: 'rDataCnt',			wave: '2.....2.2.2.2.2.2.2.2.2....' , 	data : " 9 8 7 6 5 4 3 2 1 0 9" }	,
--   {name: 'rBaudEn',				wave: '0....1|.|.|.|.|.|.|.|.|.0....' }	,
--   {name: 'rBaudCnt',			wave: '2....22.2.2.2.2.2.2.2.2.2....' , 	data : " half count full full full full full full full full full half" }	,
--   {name: 'rState',				wave: '2....22...............2.2.2..' , 	data : " stIdle stStart stWrData stWtStop stWtSend Idle" }	,
-- ] ,
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
	type	SerStateType Is
		(
			stIdle	,
			stStart	,
			stRdData,
			stWtStop,
			stWtSend
		);
	signal	rSerState		: SerStateType;
	
	signal	rSerDataIn		: std_logic_vector( 1 downto 0 );
	
	signal	rRxFfWrData		: std_logic_vector( 7 downto 0 );
	signal	wRxFfWrEn		: std_logic;
	signal	rRxFfFull		: std_logic;
	signal	rRxStopBit		: std_logic;
	
	signal	rBaudCnt		: integer range 0 to cBaudCnt;
	signal	rBaudTrig		: std_logic;
	signal	rBaudEn			: std_logic;
	
	signal	rDataCnt		: std_logic_vector ( 3 downto 0 );
Begin

----------------------------------------------------------------------------------
-- Output assignment
----------------------------------------------------------------------------------
	
	RxFfWrData		<= rRxFfWrData;
	RxFfWrEn		<= wRxFfWrEn;
	
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
	
	-- State Process
	u_rSerState : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rSerState		<= stIdle;
			else
				case rSerState Is
					when stIdle =>
						if ( rSerDataIn(1)='0' ) then
							rSerState		<= stStart;
						else
							rSerState		<= rSerState;
						end if;
					when stStart =>
						if ( rBaudTrig='1' ) then
							rSerState		<= stRdData;
						else
							rSerState		<= rSerState;
						end if;
					when stRdData =>
						if ( rBaudTrig='1' and rDataCnt=1 ) then
							rSerState		<= stWtStop;
						else
							rSerState		<= rSerState;
						end if;
					when stWtStop =>
						if ( rBaudTrig='1' and rDataCnt=0 ) then
							rSerState		<= stWtSend;
						else
							rSerState		<= rSerState;
						end if;
					when stWtSend =>
						if ( rSerDataIn(1)='1' ) then
							-- 118 use when stopbit='0' then w8 for rSerDataIn(1)='1' again
							rSerState		<= stIdle;
						else
							rSerState		<= rSerState;
						end if;
					when others =>
						rSerState		<= stIdle;
				end case;
			end if;
		end if;
	End Process u_rSerState;
	
	-- baud enabler
	u_rBaudEn : Process (Clk ,rSerState ,rBaudTrig ,rSerDataIn) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rBaudEn		<= '0';
			else
				if ( rSerState=stIdle and rSerDataIn(1)='0' ) then
					rBaudEn		<= '1';
				elsif ( rSerState=stWtStop and rBaudTrig='1' ) then
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
				if ( rSerState=stRdData and rBaudTrig='1' ) then
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
	
	
	-- check stop bit with rRxStopBit
	u_rRxStopBit : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0' ) then
				rRxStopBit		<= '0';
			else
				if ( rSerState=stWtStop and rBaudTrig='1' ) then
					rRxStopBit		<= rSerDataIn(1);
				else
					rRxStopBit		<= rRxStopBit;
				end if;
			end if;
		end if;
	end Process u_rRxStopBit;
	
	-- wRxFfWrEn use to send flag when data in is done
	u_wRxFfWrEn : Process ( rSerState ,rRxFfFull ,rSerDataIn )
	Begin
		if ( rSerState=stWtSend and rRxFfFull='0' and rRxStopBit='1' ) then
			wRxFfWrEn		<= '1';
		else
			wRxFfWrEn		<= '0';
		end if;
	End Process u_wRxFfWrEn;
	
	u_rDataCnt : Process (Clk) Is
	Begin
		if ( rising_edge(Clk) ) then
			if ( RstB='0') then
				rDataCnt		<= conv_std_logic_vector(cDataCnt,rDataCnt'Length);
			else
				if ( rBaudTrig='1' ) then
					if ( rDataCnt=( rDataCnt'Length-1 downto 0=>'0' ) ) then
						rDataCnt		<= conv_std_logic_vector(cDataCnt,rDataCnt'Length);
					else
						rDataCnt		<= rDataCnt - 1;
					end if;
				else
					rDataCnt		<= rDataCnt;
				end if;
			end if;
		end if;
	End Process u_rDataCnt;
	
End Architecture rtl;
