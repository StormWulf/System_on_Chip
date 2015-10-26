/**********************************************************************/
/*   ____  ____                                                       */
/*  /   /\/   /                                                       */
/* /___/  \  /                                                        */
/* \   \   \/                                                       */
/*  \   \        Copyright (c) 2003-2009 Xilinx, Inc.                */
/*  /   /          All Right Reserved.                                 */
/* /---/   /\                                                         */
/* \   \  /  \                                                      */
/*  \___\/\___\                                                    */
/***********************************************************************/

/* This file is designed for use with ISim build 0x79f3f3a8 */

#define XSI_HIDE_SYMBOL_SPEC true
#include "xsi.h"
#include <memory.h>
#ifdef __GNUC__
#include <stdlib.h>
#else
#include <malloc.h>
#define alloca _alloca
#endif
static const char *ng0 = "E:/SoC/Project5IPCore/project5IP.vhd";
extern char *IEEE_P_2592010699;
extern char *IEEE_P_3620187407;

unsigned char ieee_p_2592010699_sub_1744673427_503743352(char *, char *, unsigned int , unsigned int );
int ieee_p_3620187407_sub_514432868_3965413181(char *, char *, char *);


static void work_a_3177151912_3212880686_p_0(char *t0)
{
    char *t1;
    unsigned char t2;
    char *t3;
    char *t4;
    unsigned char t5;
    unsigned char t6;
    char *t7;
    char *t8;
    int t9;
    int t10;
    unsigned int t11;
    unsigned int t12;
    unsigned int t13;
    char *t14;
    char *t15;
    char *t16;
    char *t17;

LAB0:    xsi_set_current_line(79, ng0);
    t1 = (t0 + 568U);
    t2 = ieee_p_2592010699_sub_1744673427_503743352(IEEE_P_2592010699, t1, 0U, 0U);
    if (t2 != 0)
        goto LAB2;

LAB4:
LAB3:    t1 = (t0 + 6764);
    *((int *)t1) = 1;

LAB1:    return;
LAB2:    xsi_set_current_line(80, ng0);
    t3 = (t0 + 776U);
    t4 = *((char **)t3);
    t5 = *((unsigned char *)t4);
    t6 = (t5 == (unsigned char)3);
    if (t6 != 0)
        goto LAB5;

LAB7:
LAB6:    xsi_set_current_line(82, ng0);
    t1 = (t0 + 3628U);
    t3 = *((char **)t1);
    t1 = (t0 + 1972U);
    t4 = *((char **)t1);
    t9 = *((int *)t4);
    t10 = (t9 - 0);
    t11 = (t10 * 1);
    xsi_vhdl_check_range_of_index(0, 2047, 1, t9);
    t12 = (4U * t11);
    t13 = (0 + t12);
    t1 = (t3 + t13);
    t7 = (t0 + 6900);
    t8 = (t7 + 32U);
    t14 = *((char **)t8);
    t15 = (t14 + 40U);
    t16 = *((char **)t15);
    memcpy(t16, t1, 4U);
    xsi_driver_first_trans_fast_port(t7);
    goto LAB3;

LAB5:    xsi_set_current_line(80, ng0);
    t3 = (t0 + 1420U);
    t7 = *((char **)t3);
    t3 = (t0 + 2248U);
    t8 = *((char **)t3);
    t9 = *((int *)t8);
    t10 = (t9 - 0);
    t11 = (t10 * 1);
    t12 = (4U * t11);
    t13 = (0U + t12);
    t3 = (t0 + 6864);
    t14 = (t3 + 32U);
    t15 = *((char **)t14);
    t16 = (t15 + 40U);
    t17 = *((char **)t16);
    memcpy(t17, t7, 4U);
    xsi_driver_first_trans_delta(t3, t13, 4U, 0LL);
    goto LAB6;

}

static void work_a_3177151912_3212880686_p_1(char *t0)
{
    char *t1;
    unsigned char t2;
    char *t3;
    char *t4;
    unsigned char t5;
    unsigned char t6;
    char *t7;
    char *t8;
    int t9;
    int t10;
    unsigned int t11;
    unsigned int t12;
    unsigned int t13;
    char *t14;
    char *t15;
    char *t16;
    char *t17;

LAB0:    xsi_set_current_line(88, ng0);
    t1 = (t0 + 568U);
    t2 = ieee_p_2592010699_sub_1744673427_503743352(IEEE_P_2592010699, t1, 0U, 0U);
    if (t2 != 0)
        goto LAB2;

LAB4:
LAB3:    t1 = (t0 + 6772);
    *((int *)t1) = 1;

LAB1:    return;
LAB2:    xsi_set_current_line(89, ng0);
    t3 = (t0 + 868U);
    t4 = *((char **)t3);
    t5 = *((unsigned char *)t4);
    t6 = (t5 == (unsigned char)3);
    if (t6 != 0)
        goto LAB5;

LAB7:
LAB6:    xsi_set_current_line(91, ng0);
    t1 = (t0 + 3720U);
    t3 = *((char **)t1);
    t1 = (t0 + 2064U);
    t4 = *((char **)t1);
    t9 = *((int *)t4);
    t10 = (t9 - 0);
    t11 = (t10 * 1);
    xsi_vhdl_check_range_of_index(0, 2047, 1, t9);
    t12 = (4U * t11);
    t13 = (0 + t12);
    t1 = (t3 + t13);
    t7 = (t0 + 6972);
    t8 = (t7 + 32U);
    t14 = *((char **)t8);
    t15 = (t14 + 40U);
    t16 = *((char **)t15);
    memcpy(t16, t1, 4U);
    xsi_driver_first_trans_fast_port(t7);
    goto LAB3;

LAB5:    xsi_set_current_line(89, ng0);
    t3 = (t0 + 1512U);
    t7 = *((char **)t3);
    t3 = (t0 + 2340U);
    t8 = *((char **)t3);
    t9 = *((int *)t8);
    t10 = (t9 - 0);
    t11 = (t10 * 1);
    t12 = (4U * t11);
    t13 = (0U + t12);
    t3 = (t0 + 6936);
    t14 = (t3 + 32U);
    t15 = *((char **)t14);
    t16 = (t15 + 40U);
    t17 = *((char **)t16);
    memcpy(t17, t7, 4U);
    xsi_driver_first_trans_delta(t3, t13, 4U, 0LL);
    goto LAB6;

}

static void work_a_3177151912_3212880686_p_2(char *t0)
{
    char *t1;
    unsigned char t2;
    char *t3;
    char *t4;
    unsigned char t5;
    unsigned char t6;
    char *t7;
    char *t8;
    int t9;
    int t10;
    unsigned int t11;
    unsigned int t12;
    unsigned int t13;
    char *t14;
    char *t15;
    char *t16;
    char *t17;

LAB0:    xsi_set_current_line(97, ng0);
    t1 = (t0 + 568U);
    t2 = ieee_p_2592010699_sub_1744673427_503743352(IEEE_P_2592010699, t1, 0U, 0U);
    if (t2 != 0)
        goto LAB2;

LAB4:
LAB3:    t1 = (t0 + 6780);
    *((int *)t1) = 1;

LAB1:    return;
LAB2:    xsi_set_current_line(98, ng0);
    t3 = (t0 + 960U);
    t4 = *((char **)t3);
    t5 = *((unsigned char *)t4);
    t6 = (t5 == (unsigned char)3);
    if (t6 != 0)
        goto LAB5;

LAB7:
LAB6:    xsi_set_current_line(100, ng0);
    t1 = (t0 + 3812U);
    t3 = *((char **)t1);
    t1 = (t0 + 2156U);
    t4 = *((char **)t1);
    t9 = *((int *)t4);
    t10 = (t9 - 0);
    t11 = (t10 * 1);
    xsi_vhdl_check_range_of_index(0, 2047, 1, t9);
    t12 = (4U * t11);
    t13 = (0 + t12);
    t1 = (t3 + t13);
    t7 = (t0 + 7044);
    t8 = (t7 + 32U);
    t14 = *((char **)t8);
    t15 = (t14 + 40U);
    t16 = *((char **)t15);
    memcpy(t16, t1, 4U);
    xsi_driver_first_trans_fast_port(t7);
    goto LAB3;

LAB5:    xsi_set_current_line(98, ng0);
    t3 = (t0 + 1604U);
    t7 = *((char **)t3);
    t3 = (t0 + 2432U);
    t8 = *((char **)t3);
    t9 = *((int *)t8);
    t10 = (t9 - 0);
    t11 = (t10 * 1);
    t12 = (4U * t11);
    t13 = (0U + t12);
    t3 = (t0 + 7008);
    t14 = (t3 + 32U);
    t15 = *((char **)t14);
    t16 = (t15 + 40U);
    t17 = *((char **)t16);
    memcpy(t17, t7, 4U);
    xsi_driver_first_trans_delta(t3, t13, 4U, 0LL);
    goto LAB6;

}

static void work_a_3177151912_3212880686_p_3(char *t0)
{
    char t6[16];
    char t15[16];
    char *t1;
    char *t2;
    unsigned int t3;
    unsigned int t4;
    unsigned int t5;
    char *t7;
    char *t8;
    int t9;
    unsigned int t10;
    int t11;
    char *t12;
    unsigned int t13;
    unsigned int t14;
    char *t16;
    char *t17;
    int t18;
    unsigned int t19;
    int t20;
    int t21;
    int t22;
    char *t23;
    char *t24;
    char *t25;
    char *t26;
    char *t27;

LAB0:    xsi_set_current_line(111, ng0);

LAB3:    t1 = (t0 + 2800U);
    t2 = *((char **)t1);
    t3 = (9 - 9);
    t4 = (t3 * 1U);
    t5 = (0 + t4);
    t1 = (t2 + t5);
    t7 = (t6 + 0U);
    t8 = (t7 + 0U);
    *((int *)t8) = 9;
    t8 = (t7 + 4U);
    *((int *)t8) = 4;
    t8 = (t7 + 8U);
    *((int *)t8) = -1;
    t9 = (4 - 9);
    t10 = (t9 * -1);
    t10 = (t10 + 1);
    t8 = (t7 + 12U);
    *((unsigned int *)t8) = t10;
    t11 = ieee_p_3620187407_sub_514432868_3965413181(IEEE_P_3620187407, t1, t6);
    t8 = (t0 + 2892U);
    t12 = *((char **)t8);
    t10 = (9 - 9);
    t13 = (t10 * 1U);
    t14 = (0 + t13);
    t8 = (t12 + t14);
    t16 = (t15 + 0U);
    t17 = (t16 + 0U);
    *((int *)t17) = 9;
    t17 = (t16 + 4U);
    *((int *)t17) = 4;
    t17 = (t16 + 8U);
    *((int *)t17) = -1;
    t18 = (4 - 9);
    t19 = (t18 * -1);
    t19 = (t19 + 1);
    t17 = (t16 + 12U);
    *((unsigned int *)t17) = t19;
    t20 = ieee_p_3620187407_sub_514432868_3965413181(IEEE_P_3620187407, t8, t15);
    t21 = (t20 * 40);
    t22 = (t11 + t21);
    t17 = (t0 + 7080);
    t23 = (t17 + 32U);
    t24 = *((char **)t23);
    t25 = (t24 + 40U);
    t26 = *((char **)t25);
    *((int *)t26) = t22;
    xsi_driver_first_trans_fast(t17);

LAB2:    t27 = (t0 + 6788);
    *((int *)t27) = 1;

LAB1:    return;
LAB4:    goto LAB2;

}

static void work_a_3177151912_3212880686_p_4(char *t0)
{
    char t17[16];
    char *t1;
    char *t2;
    int t3;
    int t4;
    int t5;
    char *t6;
    char *t7;
    unsigned int t8;
    unsigned int t9;
    char *t10;
    int t11;
    int t12;
    unsigned int t13;
    unsigned int t14;
    unsigned int t15;
    unsigned int t16;
    char *t18;
    char *t19;
    int t20;
    unsigned int t21;
    int t22;
    int t23;
    int t24;
    char *t25;
    int t26;
    int t27;
    int t28;
    int t29;
    int t30;
    char *t31;
    char *t32;
    char *t33;
    char *t34;
    char *t35;
    char *t36;

LAB0:    xsi_set_current_line(114, ng0);

LAB3:    t1 = (t0 + 2800U);
    t2 = *((char **)t1);
    t1 = (t0 + 11296U);
    t3 = ieee_p_3620187407_sub_514432868_3965413181(IEEE_P_3620187407, t2, t1);
    t4 = (t3 / 2);
    t5 = xsi_vhdl_mod(t4, 8);
    t6 = (t0 + 3628U);
    t7 = *((char **)t6);
    t8 = (3 - 3);
    t9 = (t8 * 1U);
    t6 = (t0 + 3168U);
    t10 = *((char **)t6);
    t11 = *((int *)t10);
    t12 = (t11 - 0);
    t13 = (t12 * 1);
    xsi_vhdl_check_range_of_index(0, 2047, 1, t11);
    t14 = (4U * t13);
    t15 = (0 + t14);
    t16 = (t15 + t9);
    t6 = (t7 + t16);
    t18 = (t17 + 0U);
    t19 = (t18 + 0U);
    *((int *)t19) = 3;
    t19 = (t18 + 4U);
    *((int *)t19) = 1;
    t19 = (t18 + 8U);
    *((int *)t19) = -1;
    t20 = (1 - 3);
    t21 = (t20 * -1);
    t21 = (t21 + 1);
    t19 = (t18 + 12U);
    *((unsigned int *)t19) = t21;
    t22 = ieee_p_3620187407_sub_514432868_3965413181(IEEE_P_3620187407, t6, t17);
    t23 = (64 * t22);
    t24 = (t5 + t23);
    t19 = (t0 + 2892U);
    t25 = *((char **)t19);
    t19 = (t0 + 11296U);
    t26 = ieee_p_3620187407_sub_514432868_3965413181(IEEE_P_3620187407, t25, t19);
    t27 = (t26 / 2);
    t28 = xsi_vhdl_mod(t27, 8);
    t29 = (t28 * 8);
    t30 = (t24 + t29);
    t31 = (t0 + 7116);
    t32 = (t31 + 32U);
    t33 = *((char **)t32);
    t34 = (t33 + 40U);
    t35 = *((char **)t34);
    *((int *)t35) = t30;
    xsi_driver_first_trans_fast(t31);

LAB2:    t36 = (t0 + 6796);
    *((int *)t36) = 1;

LAB1:    return;
LAB4:    goto LAB2;

}

static void work_a_3177151912_3212880686_p_5(char *t0)
{
    char t17[16];
    char *t1;
    char *t2;
    int t3;
    int t4;
    int t5;
    char *t6;
    char *t7;
    unsigned int t8;
    unsigned int t9;
    char *t10;
    int t11;
    int t12;
    unsigned int t13;
    unsigned int t14;
    unsigned int t15;
    unsigned int t16;
    char *t18;
    char *t19;
    int t20;
    unsigned int t21;
    int t22;
    int t23;
    int t24;
    char *t25;
    int t26;
    int t27;
    int t28;
    int t29;
    int t30;
    char *t31;
    char *t32;
    char *t33;
    char *t34;
    char *t35;
    char *t36;

LAB0:    xsi_set_current_line(115, ng0);

LAB3:    t1 = (t0 + 2800U);
    t2 = *((char **)t1);
    t1 = (t0 + 11296U);
    t3 = ieee_p_3620187407_sub_514432868_3965413181(IEEE_P_3620187407, t2, t1);
    t4 = (t3 / 2);
    t5 = xsi_vhdl_mod(t4, 8);
    t6 = (t0 + 3720U);
    t7 = *((char **)t6);
    t8 = (3 - 3);
    t9 = (t8 * 1U);
    t6 = (t0 + 3168U);
    t10 = *((char **)t6);
    t11 = *((int *)t10);
    t12 = (t11 - 0);
    t13 = (t12 * 1);
    xsi_vhdl_check_range_of_index(0, 2047, 1, t11);
    t14 = (4U * t13);
    t15 = (0 + t14);
    t16 = (t15 + t9);
    t6 = (t7 + t16);
    t18 = (t17 + 0U);
    t19 = (t18 + 0U);
    *((int *)t19) = 3;
    t19 = (t18 + 4U);
    *((int *)t19) = 1;
    t19 = (t18 + 8U);
    *((int *)t19) = -1;
    t20 = (1 - 3);
    t21 = (t20 * -1);
    t21 = (t21 + 1);
    t19 = (t18 + 12U);
    *((unsigned int *)t19) = t21;
    t22 = ieee_p_3620187407_sub_514432868_3965413181(IEEE_P_3620187407, t6, t17);
    t23 = (64 * t22);
    t24 = (t5 + t23);
    t19 = (t0 + 2892U);
    t25 = *((char **)t19);
    t19 = (t0 + 11296U);
    t26 = ieee_p_3620187407_sub_514432868_3965413181(IEEE_P_3620187407, t25, t19);
    t27 = (t26 / 2);
    t28 = xsi_vhdl_mod(t27, 8);
    t29 = (t28 * 8);
    t30 = (t24 + t29);
    t31 = (t0 + 7152);
    t32 = (t31 + 32U);
    t33 = *((char **)t32);
    t34 = (t33 + 40U);
    t35 = *((char **)t34);
    *((int *)t35) = t30;
    xsi_driver_first_trans_fast(t31);

LAB2:    t36 = (t0 + 6804);
    *((int *)t36) = 1;

LAB1:    return;
LAB4:    goto LAB2;

}

static void work_a_3177151912_3212880686_p_6(char *t0)
{
    char *t1;
    char *t2;
    unsigned char t3;
    unsigned char t4;
    char *t5;
    char *t6;
    char *t7;
    char *t8;
    char *t9;
    char *t10;
    unsigned char t11;
    unsigned char t12;
    int t13;
    unsigned int t14;
    unsigned int t15;
    int t16;
    int t17;
    unsigned int t18;
    unsigned int t19;
    unsigned int t20;
    unsigned int t21;
    unsigned char t22;
    unsigned char t23;
    unsigned int t24;
    unsigned int t25;
    int t26;
    int t27;
    unsigned int t28;
    unsigned int t29;
    unsigned int t30;
    unsigned int t31;
    char *t32;
    char *t33;
    char *t34;
    char *t35;
    char *t36;

LAB0:    xsi_set_current_line(120, ng0);
    t1 = (t0 + 684U);
    t2 = *((char **)t1);
    t3 = *((unsigned char *)t2);
    t4 = (t3 == (unsigned char)3);
    if (t4 != 0)
        goto LAB2;

LAB4:    t1 = (t0 + 568U);
    t4 = xsi_signal_has_event(t1);
    if (t4 == 1)
        goto LAB7;

LAB8:    t3 = (unsigned char)0;

LAB9:    if (t3 != 0)
        goto LAB5;

LAB6:
LAB3:    t1 = (t0 + 6812);
    *((int *)t1) = 1;

LAB1:    return;
LAB2:    xsi_set_current_line(120, ng0);
    t1 = xsi_get_transient_memory(3U);
    memset(t1, 0, 3U);
    t5 = t1;
    memset(t5, (unsigned char)2, 3U);
    t6 = (t0 + 7188);
    t7 = (t6 + 32U);
    t8 = *((char **)t7);
    t9 = (t8 + 40U);
    t10 = *((char **)t9);
    memcpy(t10, t1, 3U);
    xsi_driver_first_trans_fast(t6);
    goto LAB3;

LAB5:    xsi_set_current_line(123, ng0);
    t2 = (t0 + 3812U);
    t6 = *((char **)t2);
    t13 = (0 - 3);
    t14 = (t13 * -1);
    t15 = (1U * t14);
    t2 = (t0 + 3536U);
    t7 = *((char **)t2);
    t16 = *((int *)t7);
    t17 = (t16 - 0);
    t18 = (t17 * 1);
    xsi_vhdl_check_range_of_index(0, 2047, 1, t16);
    t19 = (4U * t18);
    t20 = (0 + t19);
    t21 = (t20 + t15);
    t2 = (t6 + t21);
    t22 = *((unsigned char *)t2);
    t23 = (t22 == (unsigned char)3);
    if (t23 != 0)
        goto LAB10;

LAB12:    xsi_set_current_line(124, ng0);
    t1 = (t0 + 3812U);
    t2 = *((char **)t1);
    t14 = (3 - 3);
    t15 = (t14 * 1U);
    t1 = (t0 + 3444U);
    t5 = *((char **)t1);
    t13 = *((int *)t5);
    t16 = (t13 - 0);
    t18 = (t16 * 1);
    xsi_vhdl_check_range_of_index(0, 2047, 1, t13);
    t19 = (4U * t18);
    t20 = (0 + t19);
    t21 = (t20 + t15);
    t1 = (t2 + t21);
    t6 = (t0 + 7188);
    t7 = (t6 + 32U);
    t8 = *((char **)t7);
    t9 = (t8 + 40U);
    t10 = *((char **)t9);
    memcpy(t10, t1, 3U);
    xsi_driver_first_trans_fast(t6);

LAB11:    goto LAB3;

LAB7:    t2 = (t0 + 592U);
    t5 = *((char **)t2);
    t11 = *((unsigned char *)t5);
    t12 = (t11 == (unsigned char)3);
    t3 = t12;
    goto LAB9;

LAB10:    xsi_set_current_line(123, ng0);
    t8 = (t0 + 3628U);
    t9 = *((char **)t8);
    t24 = (3 - 3);
    t25 = (t24 * 1U);
    t8 = (t0 + 3536U);
    t10 = *((char **)t8);
    t26 = *((int *)t10);
    t27 = (t26 - 0);
    t28 = (t27 * 1);
    xsi_vhdl_check_range_of_index(0, 2047, 1, t26);
    t29 = (4U * t28);
    t30 = (0 + t29);
    t31 = (t30 + t25);
    t8 = (t9 + t31);
    t32 = (t0 + 7188);
    t33 = (t32 + 32U);
    t34 = *((char **)t33);
    t35 = (t34 + 40U);
    t36 = *((char **)t35);
    memcpy(t36, t8, 3U);
    xsi_driver_first_trans_fast(t32);
    goto LAB11;

}

static void work_a_3177151912_3212880686_p_7(char *t0)
{
    char *t1;
    char *t2;
    unsigned char t3;
    unsigned char t4;
    char *t5;
    char *t6;
    char *t7;
    char *t8;
    char *t9;
    char *t10;
    char *t12;
    char *t13;
    char *t14;
    char *t15;
    char *t16;
    char *t17;

LAB0:    xsi_set_current_line(129, ng0);
    t1 = (t0 + 2708U);
    t2 = *((char **)t1);
    t3 = *((unsigned char *)t2);
    t4 = (t3 == (unsigned char)3);
    if (t4 != 0)
        goto LAB3;

LAB4:
LAB5:    t10 = (t0 + 36396);
    t12 = (t0 + 7224);
    t13 = (t12 + 32U);
    t14 = *((char **)t13);
    t15 = (t14 + 40U);
    t16 = *((char **)t15);
    memcpy(t16, t10, 3U);
    xsi_driver_first_trans_fast_port(t12);

LAB2:    t17 = (t0 + 6820);
    *((int *)t17) = 1;

LAB1:    return;
LAB3:    t1 = (t0 + 2524U);
    t5 = *((char **)t1);
    t1 = (t0 + 7224);
    t6 = (t1 + 32U);
    t7 = *((char **)t6);
    t8 = (t7 + 40U);
    t9 = *((char **)t8);
    memcpy(t9, t5, 3U);
    xsi_driver_first_trans_fast_port(t1);
    goto LAB2;

LAB6:    goto LAB2;

}


extern void work_a_3177151912_3212880686_init()
{
	static char *pe[] = {(void *)work_a_3177151912_3212880686_p_0,(void *)work_a_3177151912_3212880686_p_1,(void *)work_a_3177151912_3212880686_p_2,(void *)work_a_3177151912_3212880686_p_3,(void *)work_a_3177151912_3212880686_p_4,(void *)work_a_3177151912_3212880686_p_5,(void *)work_a_3177151912_3212880686_p_6,(void *)work_a_3177151912_3212880686_p_7};
	xsi_register_didat("work_a_3177151912_3212880686", "isim/project5IP_isim_beh.exe.sim/work/a_3177151912_3212880686.didat");
	xsi_register_executes(pe);
}
