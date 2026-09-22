// LeetCode Problem: Spiral Matrix II
// Link: https://leetcode.com/problems/spiral-matrix-ii/
// Difficulty: Medium
// Language: java

class Solution {
    public int[][] generateMatrix(int n) {
        int top = 0;
        int left = 0;
        int bottom = n-1;
        int right = n-1;
        int num = 1;
        int[][] mat = new int[n][n];
        while(top<=bottom){
            for(int i = left; i<=right;i++){
                mat[top][i] = num++;
            }
            top++;
            for(int i = top; i<=bottom; i++){
                mat[i][right] = num++;
            }
            right--;
            if(top<=bottom){
                for(int i = right; i>=left;i--){
                    mat[bottom][i] = num++;
                }
                bottom--;
            }
            if(left<=right){
                for(int i = bottom; i>=top; i--){
                    mat[i][left] = num++;
                }
                left++;
            }
        }
        return mat;
    }
}