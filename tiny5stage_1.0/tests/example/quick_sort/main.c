//快速排序
#include <stdio.h>
#include "../include/utils.h"
void quick_sort(int num[], int low, int high)
{
   int i,j,temp;
   int tmp;

   i = low;
   j = high;
   tmp = num[low];   //任命为中间分界线，左边比他小，右边比他大,通常第一个元素是基准数

   if(i > j)  //如果下标i大于下标j，函数结束运行
   {
       return;
   }

   while(i != j)
   {
       while(num[j] >= tmp && j > i)
       {
           j--;
       }

       while(num[i] <= tmp && j > i)
       {
           i++;
       }

       if(j > i)
       {
           temp = num[j];
           num[j] = num[i];
           num[i] = temp;
       }
   }

   num[low] = num[i];
   num[i] = tmp;

   quick_sort(num,low,i-1);
   quick_sort(num,i+1,high);
}

int main()
{
   //创建一个数组
   int array[] = { 1, 4, 3, 2, 5, 6, 7, 11, 9, 10, 8};
   int order_array[]={1,2,3,4,5,6,7,8,9,10,11};
   int ok=1;
		
   quick_sort(array, 0, 10);

   for(int i = 0; i < 11; i++)
   {
       if(array[i]!=order_array[i])	ok=0;
   }
   
   
    if (ok == 1)
        set_test_pass();
    else
        set_test_fail();

    return 0;

}
