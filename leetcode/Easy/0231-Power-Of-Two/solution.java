// LeetCode Problem: Power of Two
// Link: https://leetcode.com/problems/power-of-two/
// Difficulty: Easy
// Language: java

class Solution {
    public boolean isPowerOfTwo(int n) {
        if(n <= 0)return false; 
        if((n & (n-1)) == 0){
            return true;
        }
        return false;
    }
}