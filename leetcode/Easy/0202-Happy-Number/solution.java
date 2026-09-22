// LeetCode Problem: Happy Number
// Link: https://leetcode.com/problems/happy-number/
// Difficulty: Easy
// Language: java

class Solution {
    public boolean isHappy(int n) {
        
        HashSet<Integer> s = new HashSet<>();
        while(n!=1 && !s.contains(n)){
            s.add(n);
            n = sumofSq(n);
        }
        if(n == 1)return true;
        else return false;
    }
    int sumofSq(int n){
        int rem, sum = 0;
        while(n!= 0){
            rem = n%10;
            sum = sum + (rem*rem);
            n = n/10;
        }
        return sum;
    }
}