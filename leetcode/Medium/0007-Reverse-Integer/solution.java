// LeetCode Problem: Reverse Integer
// Link: https://leetcode.com/problems/reverse-integer/
// Difficulty: Medium
// Language: java

class Solution {
public int reverse(int x) {
        int c=x, rev = 0, rem;
        while(c!=0){
            rem = c%10;
            if(rev < (Integer.MIN_VALUE/10) || rev > (Integer.MAX_VALUE/10)){
                return 0;
            }
            rev = (rev*10) + rem;
            c = c/10;
        }
        return rev;
    
    }
};
