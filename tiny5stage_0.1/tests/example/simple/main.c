#include <stdint.h>
#include "../include/utils.h"


int mul = 3;
int div = 4;


int main()
{
    int i;
    int sum=100;


    // sum = 5050
   // for (i = 0; i <= 100; i++)
       // sum += i;

    // sum = 3775
    //for (i = 0; i <= 10; i++)
        //sum += i;

    // sum = 22650
   // sum = sum * mul;

    // sum = 7550
    sum = sum / div;

    if (sum == 25)
        set_test_pass();
    else
        set_test_fail();

    return 0;
}
