// LeetCode Problem: Count the Digits That Divide a Number
// Link: https://leetcode.com/problems/count-the-digits-that-divide-a-number/
// Difficulty: Easy
// Language: java

class Solution {
    public int countDigits(int num) {
        int count = 0;
        int x = num;
        while(num!=0){
            int rem = num % 10;
            if(x%rem == 0)
                count++;
            num = num/10;
        }
        return count;
    }
}