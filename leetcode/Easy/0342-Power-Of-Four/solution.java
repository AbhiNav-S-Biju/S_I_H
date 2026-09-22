// LeetCode Problem: Power of Four
// Link: https://leetcode.com/problems/power-of-four/
// Difficulty: Easy
// Language: java

class Solution {
    public boolean isPowerOfFour(int n) {
         if (n <= 0) {
            return false;
        }
        while(n%4 == 0){
            n = n/4;
        }
        if(n == 1){
            return true;
        }
        return false;
    }
}
