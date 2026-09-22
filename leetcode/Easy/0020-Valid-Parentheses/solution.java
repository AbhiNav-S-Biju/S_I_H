// LeetCode Problem: Valid Parentheses
// Link: https://leetcode.com/problems/valid-parentheses/
// Difficulty: Easy
// Language: java

class Solution {
    public boolean isValid(String str) {
        Stack <Character> s = new Stack<>();
        for(char ch:str.toCharArray()){
            if(ch == '{' || ch == '(' || ch == '['){
                s.push(ch);
            }
            else{
                if(s.isEmpty()){
                    return false;
                }
                char br = s.pop();
                if((br != '{' && ch == '}')||
                   (br != '(' && ch == ')')||
                   (br != '[' && ch == ']')){
                    return false;
                   }
            }
        }
        return s.isEmpty();
    }
}