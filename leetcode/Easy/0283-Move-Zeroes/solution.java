// LeetCode Problem: Move Zeroes
// Link: https://leetcode.com/problems/move-zeroes/
// Difficulty: Easy
// Language: java

class Solution {
    public void moveZeroes(int[] nums) {
        int i = 0;
        for(int j:nums){
            if(j != 0){
                nums[i] = j;
                i++;
            }
        }
        while(i<nums.length){
            nums[i] = 0;
            i++;
        }
        System.out.println(nums);
    }
}