// LeetCode Problem: Sqrt(x)
// Link: https://leetcode.com/problems/sqrtx/
// Difficulty: Easy
// Language: java

class Solution {
    public int mySqrt(int x) {
        long i = 1;
        while(i*i <= x){
            i++;
        }
        return (int)--i;
    }
}