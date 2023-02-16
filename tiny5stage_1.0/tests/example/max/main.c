//求最大公约数
#include <stdio.h>
#include "../include/utils.h"

int main() {
    // 规定数组
    int array[] = { 4,6,8};
    int size = 3;
    int result=0;

    // 第一步，求得数组中的最大数和最小数
    int max = array[0];
    int min = array[0];

    for (int i = 0; i < size; i++) {
        if (max < array[i]) {
            max = array[i];
        }
        if (min > array[i]) {
            min = array[i];
        }
    }

    // 第二步，判断最大公约数
    // 如果最大数对最小数取余，如果等于0那么最小数一定是最大公约数
    if (max % min == 0) {
        result=min;
    } else {
        // 如果不等于，那么从最小数开始遍历，寻找最大公约数
        for (int i = min; i > 0; i--) {
            // 即最大数和最小数同时对i取余，为零者则是最大公约数
            if (max % i == 0 && min % i == 0) {
                result=i;
            }
        }
    }
    
    
    
       
    if (result == 2)
        set_test_pass();
    else
        set_test_fail();
    
    
    
    
    
    return 0;
}

