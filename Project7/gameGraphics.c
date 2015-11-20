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
#include <sys/types.h>
#include <sys/stat.h>
#include "xgpio_l.h"
#include "xparameters.h"
#include "xbasic_types.h"
#include "xtmrctr.h"
#include "xtmrctr_l.h"

#define cblk0 0
#define cblk1 1
#define cblu0 2
#define cblu1 3
#define cgrn0 4
#define cgrn1 5
#define ccyn0 6
#define ccyn1 7
#define cred0 8
#define cred1 9
#define cmag0 10
#define cmag1 11
#define cyel0 12
#define cyel1 13
#define cwht0 14
#define cwht1 15

//up to this many bullets can be on the map at any time
#define MAX_BULLETS 5

const int IPcoreAddr = 0xc7000000, bgOff = 0x40000000, bgSprOff = 0x1000, fgSprOff = 0x40000, fgOff = 0x80000000,
			sprOff = 0x20000000, sprColorOff = 0x1000000, controllerCoreAddr = 0xC7200000;

typedef struct{
	int tl, tr, cl, cr, bl, br;
}evinLoc;

int main(){

	int i, addr, cont, LorR = 1, bullets[MAX_BULLETS] = {-1}, bullDir[MAX_BULLETS] = {1};

	int foreground[1200] = {0}, background[1200] = {0};
	evinLoc oldLoc = {1040, 1041, 1080, 1081, 1120, 1121};
	evinLoc newLoc = {1040, 1041, 1080, 1081, 1120, 1121};
	evinLoc endLoc = {558, 559, 598, 599, 638, 639};

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
			cwht0, cwht0, cwht0, cwht0, cblk1, cwht0, cwht0, ccyn1,
			cwht0, cwht0, cwht0, cwht0, cblk1, cblk1, cblk1, cblk1,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cblk1, cblk1,
			cwht0, cwht0, cwht0, cwht0, cblk1, cblk1, cblk1, cblk1,
			cgrn1, cgrn1, cgrn1, cblk1, cblk1, cblu1, cblu1, cblu1,
			cgrn1, cwht0, cwht0, cblk1, cblu1, cblu1, cblu1, cblu1,
			cgrn1, cwht0, cwht0, cblk1, cblu1, cblu1, cblu1, cblu1,
			//evin CR 3
			cwht0, cwht0, cwht0, cblk1, cwht0, cwht0, cwht0, cwht0,
			ccyn1, cwht0, cwht0, cblk1, cwht0, cwht0, cwht0, cwht0,
			cblk1, cblk1, cblk1, cblk1, cwht0, cwht0, cwht0, cwht0,
			cblk1, cblk1, cwht0, cwht0, cwht0, cgrn1, cgrn1, cwht0,
			cblk1, cblk1, cblk1, cblk1, cwht0, cwht0, cgrn1, cwht0,
			cblu1, cblu1, cblu1, cblk1, cblk1, cwht0, cgrn1, cwht0,
			cblu1, cblu1, cblu1, cblu1, cblk1, cgrn1, cgrn1, cwht0,
			cblu1, cblu1, cblu1, cblu1, cblk1, cwht0, cwht0, cwht0,
			//evin BL 4
			cgrn1, cgrn1, cwht0, cblk1, cblu1, cblu1, cblu1, cblu1,
			cwht0, cwht0, cwht0, cblk1, cblu1, cblu1, cblu1, cblu1,
			cwht0, cwht0, cwht0, cblk1, cblk1, cblu1, cblu1, cblu1,
			cwht0, cwht0, cwht0, cwht0, cblk1, cblu1, cblu1, cblu1,
			cwht0, cwht0, cwht0, cblk1, cblk1, cblu1, cblu1, cblu1,
			cwht0, cwht0, cblk1, cblk1, cblu1, cblu1, cblu1, cblu1,
			cwht0, cwht0, cblk1, cblk1, cblk1, cblk1, cblk1, cblk1,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			//evin BR 5
			cblu1, cblu1, cblu1, cblu1, cblk1, cwht0, cwht0, cwht0,
			cblu1, cblu1, cblu1, cblu1, cblk1, cwht0, cwht0, cwht0,
			cblu1, cblu1, cblu1, cblk1, cblk1, cwht0, cwht0, cwht0,
			cblu1, cblu1, cblu1, cblk1, cwht0, cwht0, cwht0, cwht0,
			cblu1, cblu1, cblu1, cblk1, cblk1, cwht0, cwht0, cwht0,
			cblu1, cblu1, cblu1, cblu1, cblk1, cblk1, cwht0, cwht0,
			cblk1, cblk1, cblk1, cblk1, cblk1, cblk1, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			//foreground 6
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			//win 7
			cblk0, cyel0, cblk0, cyel0, cblk0, cyel0, cblk0, cblk0,
			cblk0, cblk0, cyel0, cblk0, cyel0, cblk0, cblk0, cblk0,
			cblk0, cblk0, cgrn0, cgrn0, cgrn0, cblk0, cblk0, cblk0,
			cblk0, cblk0, cblk0, cgrn0, cblk0, cblk0, cblk0, cblk0,
			cblk0, cblk0, cgrn0, cgrn0, cgrn0, cblk0, cblk0, cblk0,
			cblk0, cred0, cred0, cblk0, cblk0, cred0, cblk0, cblk0,
			cblk0, cred0, cblk0, cred0, cblk0, cred0, cblk0, cblk0,
			cblk0, cred0, cblk0, cblk0, cred0, cred0, cblk0, cblk0,
			//evin bullet 8
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cblu1, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cblu1, ccyn1, cblu1, cwht0, cwht0, cwht0,
			cwht0, cblu1, cblu1, ccyn1, cblu1, cblu1, cwht0, cwht0,
			cwht0, cblu1, cblu1, ccyn1, cblu1, cblu1, cwht0, cwht0,
			cwht0, cwht0, cblu1, ccyn1, cblu1, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cblu1, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			//bullet enemy 9
			cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cmag1, cwht0, cwht0, cwht0, cwht0,
			cwht0, cwht0, cmag1, cred1, cmag1, cwht0, cwht0, cwht0,
			cwht0, cmag1, cmag1, cred1, cmag1, cmag1, cwht0, cwht0,
			cwht0, cmag1, cmag1, cred1, cmag1, cmag1, cwht0, cwht0,
			cwht0, cwht0, cmag1, cred1, cmag1, cwht0, cwht0, cwht0,
			cwht0, cwht0, cwht0, cmag1, cwht0, cwht0, cwht0, cwht0,
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
			cgrn0, cmag0, cgrn0, cmag0, cgrn0, cmag0, cgrn0, cmag0,
			cmag0, cgrn0, cmag0, cgrn0, cmag0, cgrn0, cmag0, cgrn0,
			cgrn0, cmag0, cgrn0, cmag0, cgrn0, cmag0, cgrn0, cmag0,
			cmag0, cgrn0, cmag0, cgrn0, cmag0, cgrn0, cmag0, cgrn0,
			cgrn0, cmag0, cgrn0, cmag0, cgrn0, cmag0, cgrn0, cmag0,
			cmag0, cgrn0, cmag0, cgrn0, cmag0, cgrn0, cmag0, cgrn0,
			cgrn0, cmag0, cgrn0, cmag0, cgrn0, cmag0, cgrn0, cmag0,
			cmag0, cgrn0, cmag0, cgrn0, cmag0, cgrn0, cmag0, cgrn0,
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
			cblu0, cblu0, cblu0, cblu0, cblu0, cblu0, cblu0, cblu0,
			cblu0, cblu0, cblu0, cblu0, cblu0, cblu0, cblu0, cblu0,
			cblu0, cblu0, cblu0, cblu0, cblu0, cblu0, cblu0, cblu0,
			cblu0, cblu0, cblu0, cblu0, cblu0, cblu0, cblu0, cblu0,
			cblu0, cblu0, cblu0, cblu0, cblu0, cblu0, cblu0, cblu0,
			cblu0, cblu0, cblu0, cblu0, cblu0, cblu0, cblu0, cblu0,
			cblu0, cblu0, cblu0, cblu0, cblu0, cblu0, cblu0, cblu0,
			cblu0, cblu0, cblu0, cblu0, cblu0, cblu0, cblu0, cblu0,
			//cyan level 27
			ccyn0, ccyn0, ccyn0, ccyn0, ccyn0, ccyn0, ccyn0, ccyn0,
			ccyn0, ccyn0, ccyn0, ccyn0, ccyn0, ccyn0, ccyn0, ccyn0,
			ccyn0, ccyn0, ccyn0, ccyn0, ccyn0, ccyn0, ccyn0, ccyn0,
			ccyn0, ccyn0, ccyn0, ccyn0, ccyn0, ccyn0, ccyn0, ccyn0,
			ccyn0, ccyn0, ccyn0, ccyn0, ccyn0, ccyn0, ccyn0, ccyn0,
			ccyn0, ccyn0, ccyn0, ccyn0, ccyn0, ccyn0, ccyn0, ccyn0,
			ccyn0, ccyn0, ccyn0, ccyn0, ccyn0, ccyn0, ccyn0, ccyn0,
			ccyn0, ccyn0, ccyn0, ccyn0, ccyn0, ccyn0, ccyn0, ccyn0,
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

	for (i = 0; i < 1200; ++i){								//magenta level
		background[i] = 31;
		foreground[i] = 6;
	}

	for (i = 679; i < 1200; i += 40) background[i] = 30;

	for (i = 670; i < 675; ++i) background[i] = 30;
	for (i = 740; i < 745; ++i) background[i] = 30;
	for (i = 840; i < 850; ++i) background[i] = 30;
	for (i = 1017; i < 1028; ++i) background[i] = 30;
	for (i = 1160; i < 1200; ++i) background[i] = 30;

	foreground[oldLoc.tl] = 0;
	foreground[oldLoc.tr] = 1;
	foreground[oldLoc.cl] = 2;
	foreground[oldLoc.cr] = 3;
	foreground[oldLoc.bl] = 4;
	foreground[oldLoc.br] = 5;
	for (;;){

		cont = XGpio_ReadReg(controllerCoreAddr, 0);
		//process move
		if (cont == 254){					//A (jump)
			if (background[newLoc.tl-40] != 30 && background[newLoc.tr-40] != 30 && newLoc.tl > 39 &&
					newLoc.tr > 39){
				newLoc.tl = oldLoc.tl - 40;
				newLoc.tr = oldLoc.tr - 40;
				newLoc.cl = oldLoc.cl - 40;
				newLoc.cr = oldLoc.cr - 40;
				newLoc.bl = oldLoc.bl - 40;
				newLoc.br = oldLoc.br - 40;
				foreground[oldLoc.bl] = 6;
				foreground[oldLoc.br] = 6;
			}
		}
		if (cont == 253){					//B (fire)
			for (i = 0; i < MAX_BULLETS; ++i){
				if (bullets[i] == -1){
					if (LorR == 1){
						bullets[i] = oldLoc.cr + 1;
						bullDir[i] = 1;
					}
					else{
						bullets[i] = oldLoc.cl - 1;
						bullDir[i] = -1;
					}
					break;
				}
			}
		}
		if (cont == 191){					//left
			LorR = -1;
			if (background[newLoc.tl-1] != 30 && background[newLoc.cl-1] != 30 && background[newLoc.bl-1] != 30){
				newLoc.tl = oldLoc.tl - 1;
				newLoc.tr = oldLoc.tr - 1;
				newLoc.cl = oldLoc.cl - 1;
				newLoc.cr = oldLoc.cr - 1;
				newLoc.bl = oldLoc.bl - 1;
				newLoc.br = oldLoc.br - 1;
				foreground[oldLoc.tr] = 6;
				foreground[oldLoc.cr] = 6;
				foreground[oldLoc.br] = 6;
			}
		}
		if (cont == 190){					//left + A
			if (background[newLoc.tl+1] != 30 && background[newLoc.cl+1] != 30 && background[newLoc.bl+1] != 30
					&& newLoc.tl > -1 && newLoc.tr > -1){
				newLoc.tl = oldLoc.tl - 41;
				newLoc.tr = oldLoc.tr - 41;
				newLoc.cl = oldLoc.cl - 41;
				newLoc.cr = oldLoc.cr - 41;
				newLoc.bl = oldLoc.bl - 41;
				newLoc.br = oldLoc.br - 41;
				foreground[oldLoc.tr] = 6;
				foreground[oldLoc.cr] = 6;
				foreground[oldLoc.bl] = 6;
				foreground[oldLoc.br] = 6;
			}
		}
		if (cont == 127){					//right
			LorR = 1;
			if (background[newLoc.tr+1] != 30 && background[newLoc.cr+1] != 30 && background[newLoc.br+1] != 30
					|| ((newLoc.cr+1) % 39 != 39) || (newLoc.cr != 39 || newLoc.cr != 79 || newLoc.cr != 119 || newLoc.cr != 159
					|| newLoc.cr != 199 || newLoc.cr != 239 || newLoc.cr != 279 || newLoc.cr != 319
					|| newLoc.cr != 359 || newLoc.cr != 399 || newLoc.cr != 439 || newLoc.cr != 479
					|| newLoc.cr != 519 || newLoc.cr != 559 || newLoc.cr != 599 || newLoc.cr != 639
					|| newLoc.cr != 679 || newLoc.cr != 719 || newLoc.cr != 759 || newLoc.cr != 799
					|| newLoc.cr != 839 || newLoc.cr != 879 || newLoc.cr != 919 || newLoc.cr != 959
					|| newLoc.cr != 999 || newLoc.cr != 1039 || newLoc.cr != 1079 || newLoc.cr != 1119
					|| newLoc.cr != 1159 || newLoc.cr != 1199)){
				newLoc.tl = oldLoc.tl + 1;
				newLoc.tr = oldLoc.tr + 1;
				newLoc.cl = oldLoc.cl + 1;
				newLoc.cr = oldLoc.cr + 1;
				newLoc.bl = oldLoc.bl + 1;
				newLoc.br = oldLoc.br + 1;
				foreground[oldLoc.tl] = 6;
				foreground[oldLoc.cl] = 6;
				foreground[oldLoc.bl] = 6;
			}
		}
		if (cont == 126){					//right + A
			if (background[newLoc.tr+1] != 30 && background[newLoc.cr+1] != 30 && background[newLoc.br+1] != 30
					&& newLoc.tl > 39 && newLoc.tr > 39){
				newLoc.tl = oldLoc.tl - 39;
				newLoc.tr = oldLoc.tr - 39;
				newLoc.cl = oldLoc.cl - 39;
				newLoc.cr = oldLoc.cr - 39;
				newLoc.bl = oldLoc.bl - 39;
				newLoc.br = oldLoc.br - 39;
				foreground[oldLoc.tl] = 6;
				foreground[oldLoc.cl] = 6;
				foreground[oldLoc.bl] = 6;
				foreground[oldLoc.br] = 6;
			}
		}

		//gravity?
		if (cont != 254 && background[oldLoc.bl+40] != 30 && background[oldLoc.br+40] != 30){
			if(cont == 191){
				newLoc.tl += 39;
				newLoc.tr += 39;
				newLoc.cl += 39;
				newLoc.cr += 39;
				newLoc.bl += 39;
				newLoc.br += 39;
				foreground[oldLoc.tl] = 6;
				foreground[oldLoc.cl] = 6;
				foreground[oldLoc.bl] = 6;
				foreground[oldLoc.tr] = 6;
				foreground[oldLoc.cr] = 6;
				foreground[oldLoc.br] = 6;
			}
			else if (cont == 127){
				newLoc.tl += 41;
				newLoc.tr += 41;
				newLoc.cl += 41;
				newLoc.cr += 41;
				newLoc.bl += 41;
				newLoc.br += 41;
				foreground[oldLoc.tl] = 6;
				foreground[oldLoc.cl] = 6;
				foreground[oldLoc.bl] = 6;
				foreground[oldLoc.tr] = 6;
				foreground[oldLoc.cr] = 6;
				foreground[oldLoc.br] = 6;
			}
			else {
				newLoc.tl += 40;
				newLoc.tr += 40;
				newLoc.cl += 40;
				newLoc.cr += 40;
				newLoc.bl += 40;
				newLoc.br += 40;
				foreground[oldLoc.tl] = 6;
				foreground[oldLoc.tr] = 6;
			}
		}

		//copy over old location to new
		oldLoc = newLoc;

		foreground[oldLoc.tl] = 0;
		foreground[oldLoc.tr] = 1;
		foreground[oldLoc.cl] = 2;
		foreground[oldLoc.cr] = 3;
		foreground[oldLoc.bl] = 4;
		foreground[oldLoc.br] = 5;

		//update any bullets out there
		for (i = 0; i < MAX_BULLETS; ++i){
			if (bullets[i] != -1){
				foreground[bullets[i]] = 6;
				bullets[i] += bullDir[i];
				if (background[bullets[i]] == 30 || (bullets[i] == 0) || (bullets[i] == 39) || (bullets[i] == 79)
						|| (bullets[i] == 119) || (bullets[i] == 159) || (bullets[i] == 199)
						|| (bullets[i] == 239) || (bullets[i] == 279) || (bullets[i] == 319)
						|| (bullets[i] == 359) || (bullets[i] == 399) || (bullets[i] == 439)
						|| (bullets[i] == 479) || (bullets[i] == 519) || (bullets[i] == 559)
						|| (bullets[i] == 599) || (bullets[i] == 639) || (bullets[i] == 679)
						|| (bullets[i] == 719) || (bullets[i] == 759) || (bullets[i] == 799)
						|| (bullets[i] == 839) || (bullets[i] == 879) || (bullets[i] == 919)
						|| (bullets[i] == 959) || (bullets[i] == 999) || (bullets[i] == 1039)
						|| (bullets[i] == 1079) || (bullets[i] == 1119) || (bullets[i] == 1159)
						|| (bullets[i] == 1199)) bullets[i] = -1;
				else foreground[bullets[i]] = 8;
			}
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

		//proceed to next level if we reach the goal
		if (endLoc.tl == oldLoc.tl && endLoc.tr == oldLoc.tr && endLoc.cl == oldLoc.cl &&
				endLoc.cr == oldLoc.cr && endLoc.bl == oldLoc.bl && endLoc.br == oldLoc.br) break;
	}

	/*for(;;){
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

	}*/

	return 0;
}

