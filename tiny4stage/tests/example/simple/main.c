#include <stdint.h>
#include "../include/utils.h"


int mul = 3;
int div = 3;


int main()
{
    int i;
    int sum;


     sum = 255;
   // for (i = 0; i <= 100; i++)
       // sum += i;

    // sum = 3775
   // for (i = 0; i <= 50; i++)
       // sum -= i;

    // sum = 22650
    sum = sum * mul;

    // sum = 7550
    sum = sum / div;

    if (sum == 765)
        set_test_pass();
    else
        set_test_fail();

    return 0;
}
