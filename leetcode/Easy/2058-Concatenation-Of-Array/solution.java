// LeetCode Problem: Concatenation of Array
// Link: https://leetcode.com/problems/concatenation-of-array/
// Difficulty: Easy
// Language: java

class Solution {
    public int[] getConcatenation(int[] nums) {
        int size = 2*(nums.length);
        int[] res = new int[size];
        for(int i = 0; i<size; i++){
            res[i] = nums[i%nums.length];
        }
        System.out.println(res);
        return res;
    }
}