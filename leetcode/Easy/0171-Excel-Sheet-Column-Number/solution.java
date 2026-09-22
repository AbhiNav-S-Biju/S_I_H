// LeetCode Problem: Excel Sheet Column Number
// Link: https://leetcode.com/problems/excel-sheet-column-number/
// Difficulty: Easy
// Language: java

class Solution {
    public int titleToNumber(String columnTitle) {
        int col = 0;
        for(int i = 0; i<columnTitle.length(); i++){
            col = (26*col)+(columnTitle.charAt(i)-'A'+1);
        }
        return col;
    }
}