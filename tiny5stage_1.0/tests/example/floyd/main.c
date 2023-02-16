//floyd
#include <stdio.h>
#include "../include/utils.h"

//floyd求最短路径长度,A-C最短60

int main() {
   //用矩阵定义有向图
   int graph[4][4] = {0, 10, 100, 25,
                      1000, 0, 1000, 20,
                      1000, 1000, 0, 1000,
                      1000, 1000, 30, 0};
   //初始化路径图
   int path[4][4];
   for(int i = 0; i < 4; i++)
       for(int j = 0; j < 4; j++){
           path[i][j] = -1;
       }
   // floyd核心代码
   for(int i = 0; i < 4; i++)
       for(int j = 0; j < 4; j++)
           for(int k = 0; k < 4; k++){
               if(graph[j][k] > graph[j][i]+graph[i][k])
               {
                   graph[j][k] = graph[j][i]+graph[i][k];
                   path[j][k] = path[i][k];
               }
           }
           
                  
    if (graph[0][2] == 55)
        set_test_pass();
    else
        set_test_fail();
    
    
    
   return 0;
}
