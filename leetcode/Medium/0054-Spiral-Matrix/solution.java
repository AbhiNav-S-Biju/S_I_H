// LeetCode Problem: Spiral Matrix
// Link: https://leetcode.com/problems/spiral-matrix/
// Difficulty: Medium
// Language: java

class Solution {
    public List<Integer> spiralOrder(int[][] matrix) {
        List<Integer> a=new ArrayList<>();
        int c1=0,c2=matrix[0].length-1;
        int r1=0,r2=matrix.length-1;
        int c=0;
        while(c<matrix.length*matrix[0].length){
            
            for(int i=c1;i<=c2&&c<matrix.length*matrix[0].length;i++){
            a.add(matrix[r1][i]);
            c++;
        }
        r1++;
        for(int i=r1;i<=r2&&c<matrix.length*matrix[0].length;i++){
            a.add(matrix[i][c2]);
            c++;
        }
        c2--;
        for(int i=c2;i>=c1&&c<matrix.length*matrix[0].length;i--){
            a.add(matrix[r2][i]);
            c++;
        }
        r2--;
        for(int i=r2;i>=r1&&c<matrix.length*matrix[0].length;i--){
            a.add(matrix[i][c1]);
            c++;
        }
        c1++;}
        return a;
    }
}