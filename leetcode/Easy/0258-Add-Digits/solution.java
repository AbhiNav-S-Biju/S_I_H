// LeetCode Problem: Add Digits
// Link: https://leetcode.com/problems/add-digits/
// Difficulty: Easy
// Language: java

class Solution {
    public int addDigits(int num) {
        int c = num, rem,sum = 0;
        while(c>9){
            sum = 0;
            while(c!= 0){
            rem = c%10;
            sum+= rem;
            c = c/10;
            }
            c = sum;
        }
        return c;
    }
}