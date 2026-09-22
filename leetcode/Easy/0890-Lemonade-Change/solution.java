// LeetCode Problem: Lemonade Change
// Link: https://leetcode.com/problems/lemonade-change/
// Difficulty: Easy
// Language: java

class Solution {
    public boolean lemonadeChange(int[] bills) {
        int five = 0;
        int ten = 0;
        for(int i : bills){
            if(i == 5){
                five++;
            }
            else if(i == 10){
                if(five == 0){
                    return false;
                }
                ten++;
                five--;
            }
            else{
                if(ten>0 && five>0){
                    ten--;
                    five--;
                }else if(five>2){
                    five -= 3;
                }
                else return false;
            }
        }
        return true;
    }
}