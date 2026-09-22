// LeetCode Problem: Symmetric Tree
// Link: https://leetcode.com/problems/symmetric-tree/
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
    public boolean isSymmetric(TreeNode root) {
        if(root == null){
            return false;
        }
        boolean flag = compare(root.left, root.right);
        return flag;
    }
    public boolean compare(TreeNode Lroot, TreeNode Rroot){
        if(Lroot == null && Rroot == null){
            return true;
        }
        if(Lroot == null || Rroot == null){
            return false;
        }
        if(Lroot.val != Rroot.val){
            return false;
        }
        return compare(Lroot.right, Rroot.left) && compare(Lroot.left, Rroot.right);
    }
}