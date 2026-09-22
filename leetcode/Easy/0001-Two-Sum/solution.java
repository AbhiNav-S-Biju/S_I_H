// LeetCode Problem: Two Sum
// Link: https://leetcode.com/problems/two-sum/
// Difficulty: Easy
// Language: java

import java.util.*;
class Solution {
    public int[] twoSum(int[] nums, int target) {
        HashMap<Integer, Integer> maps= new HashMap<>();
        int[] result = new int[2];
        for(int i = 0; i<nums.length;i++){
            int complimentary = target - nums[i];
            if(maps.containsKey(complimentary)){
                result[0] = maps.get(complimentary);
                result[1] = i;
                return result;
            }
            maps.put(nums[i],i);
        }
        return result;
    }
}