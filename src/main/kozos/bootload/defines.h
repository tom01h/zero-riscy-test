#ifdef SERIAL_DEFAULT_DEVICE
#elif UARTSIM
#define SERIAL_DEFAULT_DEVICE 1
#else
#define SERIAL_DEFAULT_DEVICE 0
#endif

#ifndef _DEFINES_H_INCLUDED_
#define _DEFINES_H_INCLUDED_

#define NULL ((void *)0)

typedef unsigned char  uint8;
typedef unsigned short uint16;
typedef unsigned long  uint32;

#endif
