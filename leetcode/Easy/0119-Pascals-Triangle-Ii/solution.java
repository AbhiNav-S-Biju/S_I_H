// LeetCode Problem: Pascal's Triangle II
// Link: https://leetcode.com/problems/pascals-triangle-ii/
// Difficulty: Easy
// Language: java

class Solution {
    public List<Integer> getRow(int rowIndex) {
       List<List<Integer>> result = new ArrayList<>();
        for(int i = 0; i<=rowIndex;i++){
            List<Integer> row = new ArrayList<>();
            for(int j = 0; j<=i; j++){
                if(j == 0||j==i){
                    row.add(1);
                }
                else{
                    int left = result.get(i-1).get(j-1);
                    int right = result.get(i-1).get(j);
                    row.add(left+right);
                }
            }
            result.add(row);
        }  
        return result.get(rowIndex); 
    }
}
