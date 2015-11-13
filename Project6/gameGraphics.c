//file: gameGraphics.c
//Authors: William Putnam, Jeff Falberg
//Last Updated: 11.2.2015

//Description: Write graphics data to the monitor.
//
//read  	|	register
//----------+-------------------
//   31		|	wEn fore
//   30		|	wEn back
//   29		|	wEn sprite
//   24-27	|	color
//   18-23	|	foreground sprNum
//   12-17	|	background sprNum
//   0-11	|	address (0-1200/2047)

#include <stdio.h>
#include <unistd.h>
#include "xgpio_l.h"
#include "xparameters.h"
#include "xbasic_types.h"
#include "xtmrctr.h"
#include "xtmrctr_l.h"

#define cblk0 0
#define cblk1 1
#define cblue0 2
#define cblue1 3
#define cgreen0 4
#define cgreen1 5
#define ccyan0 6
#define ccyan1 7
#define cred0 8
#define cred1 9
#define cmag0 10
#define cmag1 11
#define cyel0 12
#define cyel1 13
#define cwht0 14
#define cwht1 15

const int IPcoreAddr = 0xc7000000, bgOff = 0x40000000, bgSprOff = 0x1000, fgSprOff = 0x40000, fgOff = 0x80000000,
			sprOff = 0x20000000, sprColorOff = 0x1000000, controllerCoreAddr = 0xC7200000;

int main(){

	unsigned int i, addr, cont;

	int foreground[1200] = {0}, background[1200] = {0};

	//sprite map declaration
	int sprMap[2048] = {	//evin TL 0
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cblk1, cblk1, cblk1, cblk1, cwht0, cwht0,
			cwht0, cblk1, cyel1, cyel1, cred1, cred1, cblk1, cwht0,
			cwht0, cblk1, cyel1, cyel1, cred1, cred1, cblk1, cwht0,
			cwht0, cblk1, cyel1, cyel1, cred1, cred1, cblk1, cwht0,
			cwht0, cblk1, cyel1, cyel1, cred1, cred1, cblk1, cwht0,
			cwht0, cblk1, cblk1, cblk1, cblk1, cblk1, cwht0, cwht0,
			//evin TR 1
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cblk1, cblk1, cblk1, cblk1, cblk1, cwht0,
			cwht0, cblk1, cred1, cred1, cred1, cyel1, cyel1, cblk1,
			cwht0, cblk1, cred1, cred1, cred1, cyel1, cyel1, cblk1,
			cwht0, cblk1, cred1, cred1, cred1, cyel1, cyel1, cblk1,
			cwht0, cblk1, cred1, cred1, cred1, cyel1, cyel1, cblk1,
			cwht0, cwht0, cblk1, cblk1, cblk1, cblk1, cblk1, cwht0,
			cwht0, cwht0, cwht0, cblk1, cwht0, cwht0, cwht0, cwht0,
			//evin CL 2
			cwht0, cwht0, cwht0, cwht0, cblk1, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cblk1, cwht0, cwht0, ccyan1,
			cwht0, cwht0, cwht0, cwht0, cblk1, cblk1, cblk1, cblk1,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cblk1, cblk1,
			cwht0, cwht0, cwht0, cwht0, cblk1, cblk1, cblk1, cblk1,
			cgreen1, cgreen1, cgreen1, cblk1, cblk1, cblue1, cblue1, cblue1,
			cgreen1, cwht0, cwht0, cblk1, cblue1, cblue1, cblue1, cblue1,
			cgreen1, cwht0, cwht0, cblk1, cblue1, cblue1, cblue1, cblue1,
			//evin CR 3
			cwht0, cwht0, cwht0, cblk1, cwht0, cwht0, cwht0, cwht0,
			ccyan1, cwht0, cwht0, cblk1, cwht0, cwht0, cwht0, cwht0,
			cblk1, cblk1, cblk1, cblk1, cwht0, cwht0, cwht0, cwht0,
			cblk1, cblk1, cwht0, cwht0, cwht0, cgreen1, cgreen1, cwht0,
			cblk1, cblk1, cblk1, cblk1, cwht0, cwht0, cgreen1, cwht0,
			cblue1, cblue1, cblue1, cblk1, cblk1, cwht0, cgreen1, cwht0,
			cblue1, cblue1, cblue1, cblue1, cblk1, cgreen1, cgreen1, cwht0,
			cblue1, cblue1, cblue1, cblue1, cblk1, cwht0, cwht0, cwht0,
			//evin BL 4
			cgreen1, cgreen1, cwht0, cblk1, cblue1, cblue1, cblue1, cblue1,
			cwht0, cwht0, cwht0, cblk1, cblue1, cblue1, cblue1, cblue1,
			cwht0, cwht0, cwht0, cblk1, cblk1, cblue1, cblue1, cblue1,
			cwht0, cwht0, cwht0, cwht0, cblk1, cblue1, cblue1, cblue1,
			cwht0, cwht0, cwht0, cblk1, cblk1, cblue1, cblue1, cblue1,
			cwht0, cwht0, cblk1, cblk1, cblue1, cblue1, cblue1, cblue1,
			cwht0, cwht0, cblk1, cblk1, cblk1, cblk1, cblk1, cblk1,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			//evin BR 5
			cblue1, cblue1, cblue1, cblue1, cblk1, cwht0, cwht0, cwht0,
			cblue1, cblue1, cblue1, cblue1, cblk1, cwht0, cwht0, cwht0,
			cblue1, cblue1, cblue1, cblk1, cblk1, cwht0, cwht0, cwht0,
			cblue1, cblue1, cblue1, cblk1, cwht0, cwht0, cwht0, cwht0,
			cblue1, cblue1, cblue1, cblk1, cblk1, cwht0, cwht0, cwht0,
			cblue1, cblue1, cblue1, cblue1, cblk1, cblk1, cwht0, cwht0,
			cblk1, cblk1, cblk1, cblk1, cblk1, cblk1, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			//6
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			//7
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			//8
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			//9
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			//10
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			//11
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			//12
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			//13
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			//14
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			//15
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			//16
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			//17
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			//18
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			//19
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			//20
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			//21
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			//22
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			//23
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			//green/magenta level 24
			cgreen0, cmag0, cgreen0, cmag0, cgreen0, cmag0, cgreen0, cmag0,
			cmag0, cgreen0, cmag0, cgreen0, cmag0, cgreen0, cmag0, cgreen0,
			cgreen0, cmag0, cgreen0, cmag0, cgreen0, cmag0, cgreen0, cmag0,
			cmag0, cgreen0, cmag0, cgreen0, cmag0, cgreen0, cmag0, cgreen0,
			cgreen0, cmag0, cgreen0, cmag0, cgreen0, cmag0, cgreen0, cmag0,
			cmag0, cgreen0, cmag0, cgreen0, cmag0, cgreen0, cmag0, cgreen0,
			cgreen0, cmag0, cgreen0, cmag0, cgreen0, cmag0, cgreen0, cmag0,
			cmag0, cgreen0, cmag0, cgreen0, cmag0, cgreen0, cmag0, cgreen0,
			//yellow level 25
			cyel0, cyel0, cyel0, cyel0, cyel0, cyel0, cyel0, cyel0,
			cyel0, cyel0, cyel0, cyel0, cyel0, cyel0, cyel0, cyel0,
			cyel0, cyel0, cyel0, cyel0, cyel0, cyel0, cyel0, cyel0,
			cyel0, cyel0, cyel0, cyel0, cyel0, cyel0, cyel0, cyel0,
			cyel0, cyel0, cyel0, cyel0, cyel0, cyel0, cyel0, cyel0,
			cyel0, cyel0, cyel0, cyel0, cyel0, cyel0, cyel0, cyel0,
			cyel0, cyel0, cyel0, cyel0, cyel0, cyel0, cyel0, cyel0,
			cyel0, cyel0, cyel0, cyel0, cyel0, cyel0, cyel0, cyel0,
			//blue level 26
			cblue0, cblue0, cblue0, cblue0, cblue0, cblue0, cblue0, cblue0,
			cblue0, cblue0, cblue0, cblue0, cblue0, cblue0, cblue0, cblue0,
			cblue0, cblue0, cblue0, cblue0, cblue0, cblue0, cblue0, cblue0,
			cblue0, cblue0, cblue0, cblue0, cblue0, cblue0, cblue0, cblue0,
			cblue0, cblue0, cblue0, cblue0, cblue0, cblue0, cblue0, cblue0,
			cblue0, cblue0, cblue0, cblue0, cblue0, cblue0, cblue0, cblue0,
			cblue0, cblue0, cblue0, cblue0, cblue0, cblue0, cblue0, cblue0,
			cblue0, cblue0, cblue0, cblue0, cblue0, cblue0, cblue0, cblue0,
			//cyan level 27
			ccyan0, ccyan0, ccyan0, ccyan0, ccyan0, ccyan0, ccyan0, ccyan0,
			ccyan0, ccyan0, ccyan0, ccyan0, ccyan0, ccyan0, ccyan0, ccyan0,
			ccyan0, ccyan0, ccyan0, ccyan0, ccyan0, ccyan0, ccyan0, ccyan0,
			ccyan0, ccyan0, ccyan0, ccyan0, ccyan0, ccyan0, ccyan0, ccyan0,
			ccyan0, ccyan0, ccyan0, ccyan0, ccyan0, ccyan0, ccyan0, ccyan0,
			ccyan0, ccyan0, ccyan0, ccyan0, ccyan0, ccyan0, ccyan0, ccyan0,
			ccyan0, ccyan0, ccyan0, ccyan0, ccyan0, ccyan0, ccyan0, ccyan0,
			ccyan0, ccyan0, ccyan0, ccyan0, ccyan0, ccyan0, ccyan0, ccyan0,
			//black/white level 28
			cblk0, cblk0, cblk0, cblk0, cblk0, cblk0, cblk0, cblk0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cblk0, cblk0, cblk0, cblk0, cblk0, cblk0, cblk0, cblk0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cblk0, cblk0, cblk0, cblk0, cblk0, cblk0, cblk0, cblk0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cblk0, cblk0, cblk0, cblk0, cblk0, cblk0, cblk0, cblk0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			//white level 29
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			//rock 30
			cred0, cred0, cred0, cred0, cred0, cred0, cred0, cred0,
			cred0, cred0, cred0, cwht0, cwht0, cwht0, cwht0, cred0,
			cred0, cred0, cred0, cwht0, cred0, cred0, cwht0, cred0,
			cred0, cred0, cred0, cwht0, cred0, cred0, cwht0, cred0,
			cred0, cred0, cred0, cwht0, cwht0, cwht0, cwht0, cred0,
			cred0, cred0, cred0, cred0, cred0, cred0, cred0, cred0,
			cred0, cred0, cred0, cred0, cred0, cred0, cred0, cred0,
			cred0, cred0, cred0, cred0, cred0, cred0, cred0, cred0,
			//background 31
			cmag0, cmag0, cmag0, cmag0, cmag0, cmag0, cmag0, cmag0,
			cmag0, cmag0, cmag0, cmag0, cmag0, cmag0, cmag0, cmag0,
			cmag0, cmag0, cmag0, cmag0, cmag0, cmag0, cmag0, cmag0,
			cmag0, cmag0, cmag0, cmag0, cmag0, cmag0, cmag0, cmag0,
			cmag0, cmag0, cmag0, cmag0, cmag0, cmag0, cmag0, cmag0,
			cmag0, cmag0, cmag0, cmag0, cmag0, cmag0, cmag0, cmag0,
			cmag0, cmag0, cmag0, cmag0, cmag0, cmag0, cmag0, cmag0,
			cmag0, cmag0, cmag0, cmag0, cmag0, cmag0, cmag0, cmag0
	};

	for(;;){
		cont = XGpio_ReadReg(controllerCoreAddr, 0);
		//paint background
		if (cont == 254){ //A
			for (i = 0; i < 1200; ++i){
				background[i] = 29;
				foreground[i] = 6;
			}
			foreground[1040] = 0;
			foreground[1041] = 1;
			foreground[1080] = 2;
			foreground[1081] = 3;
			foreground[1120] = 4;
			foreground[1121] = 5;

			for (i = 0; i < 1040; i += 40) background[i] = 30;
			for (i = 39; i < 1040; i += 40) background[i] = 30;
			for (i = 436; i < 1200; i += 40) background[i] = 30;
			for (i = 731; i < 931; i += 40) background[i] = 30;

			for (i = 0; i < 40; ++i) background[i] = 30;
			for (i = 309; i < 311; ++i) background[i] = 30;
			for (i = 455; i < 457; ++i) background[i] = 30;
			for (i = 465; i < 467; ++i) background[i] = 30;
			for (i = 566; i < 568; ++i) background[i] = 30;
			for (i = 721; i < 723; ++i) background[i] = 30;
			for (i = 928; i < 935; ++i) background[i] = 30;
			for (i = 1160; i < 1200; ++i) background[i] = 30;
		}
		else if (cont == 253){ //B
			for (i = 0; i < 1200; ++i){
				background[i] = 28;
				foreground[i] = 6;
			}
			foreground[0] = 0;
			foreground[1] = 1;
			foreground[40] = 2;
			foreground[41] = 3;
			foreground[80] = 4;
			foreground[81] = 5;

			for (i = 899; i < 902; ++i) background[i] = 30;
			for (i = 1026; i < 1029; ++i) background[i] = 30;
			for (i = 1012; i < 1015; ++i) background[i] = 30;
			for (i = 1160; i < 1200; ++i) background[i] = 30;
		}
		else if (cont == 239){ //up
			for (i = 0; i < 1200; ++i){
				background[i] = 27;
				foreground[i] = 6;
			}
			foreground[400] = 0;
			foreground[401] = 1;
			foreground[440] = 2;
			foreground[441] = 3;
			foreground[480] = 4;
			foreground[481] = 5;

			for (i = 520; i < 523; ++i) background[i] = 30;

			for (i = 62; i < 65; ++i) background[i] = 30;
			for (i = 186; i < 189; ++i) background[i] = 30;
			for (i = 312; i < 315; ++i) background[i] = 30;
			for (i = 428; i < 431; ++i) background[i] = 30;
			for (i = 544; i < 547; ++i) background[i] = 30;
			for (i = 660; i < 663; ++i) background[i] = 30;
			for (i = 776; i < 779; ++i) background[i] = 30;
			for (i = 892; i < 895; ++i) background[i] = 30;
			for (i = 1008; i < 1011; ++i) background[i] = 30;
			for (i = 1124; i < 1127; ++i) background[i] = 30;
		}
		else if (cont == 223){ //down
			for (i = 0; i < 1200; ++i){
				background[i] = 26;
				foreground[i] = 6;
			}
			foreground[1040] = 0;
			foreground[1041] = 1;
			foreground[1080] = 2;
			foreground[1081] = 3;
			foreground[1120] = 4;
			foreground[1121] = 5;

			for (i = 0; i < 1000; i += 40) background[i] = 30;
			for (i = 39; i < 1200; i += 40) background[i] = 30;
			for (i = 251; i < 411; i += 40) background[i] = 30;

			for (i = 115; i < 118; ++i) background[i] = 30;
			for (i = 200; i < 206; ++i) background[i] = 30;
			for (i = 214; i < 216; ++i) background[i] = 30;
			for (i = 263; i < 272; ++i) background[i] = 30;
			for (i = 369; i < 371; ++i) background[i] = 30;
			for (i = 520; i < 526; ++i) background[i] = 30;
			for (i = 720; i < 735; ++i) background[i] = 30;
			for (i = 750; i < 760; ++i) background[i] = 30;
			for (i = 940; i < 950; ++i) background[i] = 30;
			for (i = 1160; i < 1200; ++i) background[i] = 30;
		}
		else if (cont == 191){ //left
			for (i = 0; i < 1200; ++i){
				background[i] = 25;
				foreground[i] = 6;
			}
			foreground[440] = 0;
			foreground[441] = 1;
			foreground[480] = 2;
			foreground[481] = 3;
			foreground[520] = 4;
			foreground[521] = 5;

			for (i = 455; i < 575; i += 40) background[i] = 30;
			for (i = 461; i < 601; i += 40) background[i] = 30;

			for (i = 560; i < 576; ++i) background[i] = 30;
			for (i = 581; i < 600; ++i) background[i] = 30;

		}
		else if (cont == 127){ //right
			for (i = 0; i < 1200; ++i){
				background[i] = 24;
				foreground[i] = 6;
			}
			foreground[0] = 0;
			foreground[1] = 1;
			foreground[40] = 2;
			foreground[41] = 3;
			foreground[80] = 4;
			foreground[81] = 5;

			for (i = 19; i < 619; i += 40) background[i] = 30;

			for (i = 67; i < 70; ++i) background[i] = 30;
			for (i = 120; i < 123; ++i) background[i] = 30;
			for (i = 196; i < 199; ++i) background[i] = 30;
			for (i = 290; i < 293; ++i) background[i] = 30;
			for (i = 387; i < 390; ++i) background[i] = 30;
			for (i = 440; i < 443; ++i) background[i] = 30;
			for (i = 556; i < 559; ++i) background[i] = 30;
			for (i = 690; i < 693; ++i) background[i] = 30;
			for (i = 707; i < 710; ++i) background[i] = 30;
			for (i = 898; i < 901; ++i) background[i] = 30;
		}
		else{
			for (i = 0; i < 1200; ++i){
				background[i] = 31;
				foreground[i] = 6;
			}
			foreground[0] = 0;
			foreground[1] = 1;
			foreground[40] = 2;
			foreground[41] = 3;
			foreground[80] = 4;
			foreground[81] = 5;

			for (i = 679; i < 1200; i += 40) background[i] = 30;

			for (i = 670; i < 675; ++i) background[i] = 30;
			for (i = 740; i < 745; ++i) background[i] = 30;
			for (i = 840; i < 850; ++i) background[i] = 30;
			for (i = 1017; i < 1028; ++i) background[i] = 30;
			for (i = 1160; i < 1200; ++i) background[i] = 30;
		}

		//start with foreground
		for (addr = 0; addr < 1200; ++addr){
			XGpio_WriteReg(IPcoreAddr, 0, addr + foreground[addr]*fgSprOff + fgOff);
			XGpio_ReadReg(IPcoreAddr, 0);
		}

		//now do background
		for (addr = 0; addr < 1200; ++addr){
			XGpio_WriteReg(IPcoreAddr, 0, addr + background[addr]*bgSprOff + bgOff);
			XGpio_ReadReg(IPcoreAddr, 0);
		}

		//finally sprite
		for (addr = 0; addr < 2048; ++addr){
			XGpio_WriteReg(IPcoreAddr, 0, addr + sprMap[addr]*sprColorOff + sprOff);
			XGpio_ReadReg(IPcoreAddr, 0);
		}

	}

	return 0;
}

