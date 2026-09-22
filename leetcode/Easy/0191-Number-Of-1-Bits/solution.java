// LeetCode Problem: Number of 1 Bits
// Link: https://leetcode.com/problems/number-of-1-bits/
// Difficulty: Easy
// Language: java

class Solution {
    public int hammingWeight(int n) {
        int count = 0;
        while(n!= 0){
            n = n & (n-1);
            count++;
        }
        return count;
    }
}