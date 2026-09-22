// LeetCode Problem: Palindrome Number
// Link: https://leetcode.com/problems/palindrome-number/
// Difficulty: Easy
// Language: cpp

class Solution {
public:
    bool isPalindrome(int x) {
        long rem, n, rev=0;
        n = x;
        if(x<0){
            return false;
        }
        while(n!=0){
            rem = n%10;
            rev = (rev*10)+rem;
            n = n/10;
        }
        return (x== rev);
    }
};