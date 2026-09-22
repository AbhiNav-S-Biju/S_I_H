// LeetCode Problem: Binary Search
// Link: https://leetcode.com/problems/binary-search/
// Difficulty: Easy
// Language: java

class Solution {
    public int search(int[] nums, int target) {
        int low = 0;
        int high = nums.length -1;
        int index = -1;
        while(low<=high){
            int mid = (low+high)/2;
            if(nums[mid] == target){
                index= mid;
                break;
            }
            else if(nums[mid]<target){
                low = mid+1;
            }
            else{
                high = mid-1;
            }
        }
        if(index != -1){
            return index;
        }
        else{
            return -1;
        }
    }
}