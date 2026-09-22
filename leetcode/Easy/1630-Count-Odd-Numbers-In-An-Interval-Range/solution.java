// LeetCode Problem: Count Odd Numbers in an Interval Range
// Link: https://leetcode.com/problems/count-odd-numbers-in-an-interval-range/
// Difficulty: Easy
// Language: java

class Solution {
    public int countOdds(int low, int high) {
        int count = (high-low)/2;;
        if(low%2 != 0 || high%2 != 0){
           count++;
        }
        
        return count;
    }
}