#include "../headers/myPrintf.hpp"

int main() 
{
    myPrintf("$w $$ %% $b %b $c %c $g %d $m %o $r %s $y %x $R\n", 8, 'A', 100, 10, "HELLO", 61453);
    return 0;
} 