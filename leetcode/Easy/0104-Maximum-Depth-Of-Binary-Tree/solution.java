// LeetCode Problem: Maximum Depth of Binary Tree
// Link: https://leetcode.com/problems/maximum-depth-of-binary-tree/
// Difficulty: Easy
// Language: java

/**
 * Definition for a binary tree node.
 * public class TreeNode {
 *     int val;
 *     TreeNode left;
 *     TreeNode right;
 *     TreeNode() {}
 *     TreeNode(int val) { this.val = val; }
 *     TreeNode(int val, TreeNode left, TreeNode right) {
 *         this.val = val;
 *         this.left = left;
 *         this.right = right;
 *     }
 * }
 */
class Solution {
    public int maxDepth(TreeNode root) {
        int count = 0;
        if(root== null){
            return 0;
        }
        int left = maxDepth(root.left);
        int right = maxDepth(root.right);
        return 1+ Math.max(left, right);
        
    }
}