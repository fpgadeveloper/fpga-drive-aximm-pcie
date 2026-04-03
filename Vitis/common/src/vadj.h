/*
 * vadj.h — VADJ enable for Versal boards
 */

#ifndef VADJ_H
#define VADJ_H

typedef enum {
	VADJ_1V5,
	VADJ_1V2,
} vadj_voltage_t;

int vadj_enable(vadj_voltage_t voltage);

#endif
