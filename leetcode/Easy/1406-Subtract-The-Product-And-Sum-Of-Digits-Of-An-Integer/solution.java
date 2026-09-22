// LeetCode Problem: Subtract the Product and Sum of Digits of an Integer
// Link: https://leetcode.com/problems/subtract-the-product-and-sum-of-digits-of-an-integer/
// Difficulty: Easy
// Language: java

class Solution {
    public int subtractProductAndSum(int n) {
        int c = n, pro = 1, sum = 0, result, rem;
        while(c!= 0){
            rem = c%10;
            pro = pro*rem;
            sum = sum+rem;
            c = c/10;
        }
        result = pro - sum;
        return result;
    }
}